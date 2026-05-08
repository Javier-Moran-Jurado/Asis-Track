package co.edu.uceva.microservicioplanilla.utils;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

public class PythonSignatureUtil {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final Duration DEFAULT_TIMEOUT = Duration.ofMinutes(2);

    private PythonSignatureUtil() {
    }

    public static List<String> extractSignatures(MultipartFile imageFile, Path outputDir)
            throws IOException, InterruptedException {
        return extractSignatures(imageFile.getBytes(), outputDir, locateDefaultScriptPath());
    }

    public static List<String> extractSignatures(byte[] imageBytes, Path outputDir)
            throws IOException, InterruptedException {
        return extractSignatures(imageBytes, outputDir, locateDefaultScriptPath());
    }

    public static List<String> extractSignatures(byte[] imageBytes, Path outputDir, Path scriptPath)
            throws IOException, InterruptedException {
        Objects.requireNonNull(imageBytes, "imageBytes no puede ser nulo");
        Objects.requireNonNull(scriptPath, "scriptPath no puede ser nulo");

        Path normalizedOutputDir = resolveOutputDir(outputDir);
        Files.createDirectories(normalizedOutputDir);

        String encodedImage = Base64.getEncoder().encodeToString(imageBytes);

        List<String> command = new ArrayList<>();
        command.add("python");
        command.add(scriptPath.toString());
        command.add("--image-base64");
        command.add("-");
        command.add("--output-dir");
        command.add(normalizedOutputDir.toString());
        command.add("--no-overlay");

        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        processBuilder.directory(scriptPath.getParent().toFile());

        Process process = processBuilder.start();
        try (OutputStream stdin = process.getOutputStream()) {
            stdin.write(encodedImage.getBytes(StandardCharsets.UTF_8));
            stdin.flush();
        } catch (IOException writeException) {
            String earlyOutput = readProcessOutputSafely(process);
            process.destroyForcibly();
            throw new IllegalStateException(buildBrokenPipeMessage(earlyOutput), writeException);
        }

        boolean finished = process.waitFor(DEFAULT_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
        if (!finished) {
            process.destroyForcibly();
            throw new IllegalStateException("El extractor de firmas excedio el tiempo limite");
        }

        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();

        if (process.exitValue() != 0) {
            throw new IllegalStateException(buildPythonErrorMessage(output));
        }

        if (output.isBlank()) {
            throw new IllegalStateException("El extractor de firmas no devolvio salida JSON");
        }

        JsonNode rootNode = OBJECT_MAPPER.readTree(output);
        if (rootNode.hasNonNull("error")) {
            throw new IllegalStateException(rootNode.get("error").asText());
        }

        JsonNode signaturePathsNode = rootNode.path("signature_paths");
        List<String> signaturePaths = new ArrayList<>();
        if (signaturePathsNode.isArray()) {
            for (JsonNode pathNode : signaturePathsNode) {
                signaturePaths.add(pathNode.asText());
            }
        }

        return signaturePaths;
    }

    public static Path locateDefaultScriptPath() {
        Path directPath = Paths.get("PyLibs", "SignatureExtractor.py").toAbsolutePath().normalize();
        if (Files.exists(directPath)) {
            return directPath;
        }

        Path nestedPath = Paths.get("MicroservicioPlanilla", "PyLibs", "SignatureExtractor.py")
                .toAbsolutePath()
                .normalize();
        if (Files.exists(nestedPath)) {
            return nestedPath;
        }

        return directPath;
    }

    private static Path resolveOutputDir(Path outputDir) {
        if (outputDir == null) {
            return Paths.get("target", "signature-output").toAbsolutePath().normalize();
        }
        return outputDir.toAbsolutePath().normalize();
    }

    private static String buildPythonErrorMessage(String output) {
        if (output == null || output.isBlank()) {
            return "No se pudo ejecutar el extractor de firmas";
        }
        return String.format(Locale.ROOT, "Error al ejecutar el extractor de firmas: %s", output);
    }

    private static String readProcessOutputSafely(Process process) {
        try {
            return new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
        } catch (Exception ignored) {
            return "";
        }
    }

    private static String buildBrokenPipeMessage(String processOutput) {
        if (processOutput == null || processOutput.isBlank()) {
            return "El proceso Python cerro stdin prematuramente (Broken pipe)";
        }
        return "El proceso Python cerro stdin prematuramente (Broken pipe). Salida: " + processOutput;
    }
}
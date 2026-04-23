package co.edu.uceva.microservicioplanilla.utils;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class FileHandlerUtil {

    public static List<Resource> pdfToImages(MultipartFile file) throws IOException{
        List<Resource> listaRecursos = new ArrayList<>();
        PDDocument document = Loader.loadPDF(file.getBytes());
        PDFRenderer pdfRenderer = new PDFRenderer(document);
        int totalPaginas = document.getNumberOfPages();

        for (int pagina = 0; pagina < totalPaginas; pagina++) {

            BufferedImage bim = pdfRenderer.renderImageWithDPI(pagina, 150, ImageType.RGB);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(bim, "jpeg", baos);
            byte[] imagenBytes = baos.toByteArray();

            final int numeroPagina = pagina + 1;
            ByteArrayResource resource = new ByteArrayResource(imagenBytes) {
                @Override
                public String getFilename() {
                    return "pagina_" + numeroPagina + ".jpg";
                }
            };

            listaRecursos.add(resource);
        }
        return listaRecursos;
    }

    public static List<Resource> extractZip(MultipartFile file) throws IOException {
        List<Resource> listRecursos = new ArrayList<>();

        try (ZipInputStream zis = new ZipInputStream(file.getInputStream())) {
            ZipEntry entry;

            while ((entry = zis.getNextEntry()) != null) {

                if (!entry.isDirectory() && isImage(entry.getName())) {

                    ByteArrayOutputStream baos = new ByteArrayOutputStream();
                    byte[] buffer = new byte[1024];
                    int len;
                    while ((len = zis.read(buffer)) > 0) {
                        baos.write(buffer, 0, len);
                    }

                    final String nombreArchivo = entry.getName();
                    ByteArrayResource resource = new ByteArrayResource(baos.toByteArray()) {
                        @Override
                        public String getFilename() {
                            return nombreArchivo.substring(nombreArchivo.lastIndexOf("/") + 1);
                        }
                    };

                    listRecursos.add(resource);
                }
                zis.closeEntry();
            }
        }

        return listRecursos;
    }

    private static boolean isImage(String nombreArchivo) {
        String nombreLower = nombreArchivo.toLowerCase();
        return nombreLower.endsWith(".jpg") ||
                nombreLower.endsWith(".jpeg") ||
                nombreLower.endsWith(".png") ||
                nombreLower.endsWith(".webp");
    }
}

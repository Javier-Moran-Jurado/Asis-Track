package co.edu.uceva.microservicioplanilla.utils;

import org.bytedeco.opencv.global.opencv_core;
import org.bytedeco.opencv.global.opencv_imgproc;
import org.bytedeco.opencv.opencv_core.Mat;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

public class ImagePreprocessor {

    public static Resource preprocessImage(Resource imageResource) throws IOException {
        BufferedImage original = ImageIO.read(imageResource.getInputStream());
        Mat mat = bufferedImageToMat(original);

        // 1. Convertir a grises
        Mat gray = new Mat();
        opencv_imgproc.cvtColor(mat, gray, opencv_imgproc.COLOR_BGR2GRAY);

        // 2. Reducción de ruido (filtro mediano)
        Mat denoised = new Mat();
        opencv_imgproc.medianBlur(gray, denoised, 3);

        // 3. Binarización adaptativa
        Mat binary = new Mat();
        opencv_imgproc.adaptiveThreshold(denoised, binary, 255,
                opencv_imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
                opencv_imgproc.THRESH_BINARY, 11, 2);

        // Convertir Mat a BufferedImage
        BufferedImage processed = matToBufferedImage(binary);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(processed, "png", baos);
        return new ByteArrayResource(baos.toByteArray()) {
            @Override
            public String getFilename() {
                return "processed.png";
            }
        };
    }

    private static Mat bufferedImageToMat(BufferedImage img) {
        int w = img.getWidth();
        int h = img.getHeight();
        Mat mat = new Mat(h, w, opencv_core.CV_8UC3);
        byte[] data = ((java.awt.image.DataBufferByte) img.getRaster().getDataBuffer()).getData();
        mat.data().put(data);
        return mat;
    }

    private static BufferedImage matToBufferedImage(Mat mat) {
        int type = mat.channels() == 1 ? BufferedImage.TYPE_BYTE_GRAY : BufferedImage.TYPE_3BYTE_BGR;
        BufferedImage img = new BufferedImage(mat.cols(), mat.rows(), type);
        byte[] data = new byte[mat.cols() * mat.rows() * mat.channels()];
        mat.data().get(data);
        img.getRaster().setDataElements(0, 0, mat.cols(), mat.rows(), data);
        return img;
    }
}

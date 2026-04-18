package co.edu.uceva.microserviciousuario.domain.converters;

import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAKeyPair;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Base64;

@Converter
public class UsuarioConverter implements AttributeConverter<String, String> {
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    public String convertToDatabaseColumn(String attribute) {
        // Encode data to store into database
        logger.info("Convert Application data to Database: " + attribute);

        String value = null;
        try {
            RSAKeyPair keyPair = RSAEncryption.generateKeyPair();
            value = Base64
                    .getEncoder()
                    .encodeToString(
                            RSAEncryption.
                                    encrypt(keyPair.getPublicKey(), attribute)
                                    .getBytes()
                    );
        } catch(Exception e) {
            logger.info("Failed to encode: "+ e.getMessage());
            e.printStackTrace();
        }
        return value;
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        // Decode data to use in Application
        logger.info("Convert Datbase to Application data: " + dbData);
        String value = null;
        try {
            RSAKeyPair keyPair = RSAEncryption.generateKeyPair();
            value = Base64
                    .getEncoder()
                    .encodeToString(
                            RSAEncryption.
                                    decrypt(keyPair.getPrivateKey(), dbData)
                                    .getBytes()
                    );
        } catch(Exception e) {
            logger.info("Failed to decode: "+ e.getMessage());
            e.printStackTrace();
        }
        return value;
    }
}

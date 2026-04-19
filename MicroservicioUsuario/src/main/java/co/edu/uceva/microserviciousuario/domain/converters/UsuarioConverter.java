package co.edu.uceva.microserviciousuario.domain.converters;

import co.edu.uceva.microserviciousuario.domain.service.PrivateKeyResponseDTO;
import co.edu.uceva.microserviciousuario.domain.service.PublicKeyResponseDTO;
import co.edu.uceva.microserviciousuario.domain.service.SecurityIntegrationService;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import co.uceva.edu.security.RSA.RSAPublicKey;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.math.BigInteger;
import java.util.Base64;


@Component
@Converter
public class UsuarioConverter implements AttributeConverter<String, String> {
    private final Logger logger = LoggerFactory.getLogger(getClass());

    private static SecurityIntegrationService securityService;

    @Autowired
    public void setSecurityService(SecurityIntegrationService service) {
        UsuarioConverter.securityService = service;
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null) return null;
        logger.info("Encrypt Application data to Database for: " + attribute);

        try {
            if (securityService == null) {
                logger.error("SecurityIntegrationService no inyectado en UsuarioConverter.");
                return attribute;
            }
            
            PublicKeyResponseDTO activeKey = securityService.fetchCurrentPublicKey();
            RSAPublicKey publicKey = new RSAPublicKey(activeKey.getPublicE(), new BigInteger(activeKey.getPublicN()));
            
            String encrypted = RSAEncryption.encrypt(publicKey, attribute);
            String b64Encrypted = Base64.getEncoder().encodeToString(encrypted.getBytes());
            // Formato final ej: 5:NDg1OTg0Mzk4MTgyOQ==
            return activeKey.getId() + ":" + b64Encrypted;
            
        } catch(Exception e) {
            logger.info("Failed to encode: "+ e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null) return null;
        logger.info("Decrypt Database to Application data");

        try {
            if (securityService == null) {
                logger.error("SecurityIntegrationService no inyectado en UsuarioConverter.");
                return dbData;
            }
            
            String[] parts = dbData.split(":");
            if (parts.length != 2) {
                // Posible data plana antes de aplicar cifrado
                return dbData;
            }
            
            Long id = Long.parseLong(parts[0]);
            String b64Ciphertext = parts[1];
            String ciphertext = new String(Base64.getDecoder().decode(b64Ciphertext));
            
            PrivateKeyResponseDTO privateKeyDto = securityService.fetchPrivateKeyById(id);
            RSAPrivateKey privateKey = new RSAPrivateKey(new BigInteger(privateKeyDto.getPublicN()), new BigInteger(privateKeyDto.getPrivateD()));
            
            return RSAEncryption.decrypt(privateKey, ciphertext);
            
        } catch(Exception e) {
            logger.info("Failed to decode: "+ e.getMessage());
            e.printStackTrace();
            return null;
        }
    }
}

package co.edu.uceva.microservicioasistencia.domain.converters;
import co.edu.uceva.microservicioasistencia.domain.service.*;
import co.uceva.edu.security.RSA.*;
import jakarta.persistence.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import java.math.BigInteger;
import java.util.Base64;
@Component @Converter
public class EncryptionConverter implements AttributeConverter<String, String> {
    private static SecurityIntegrationService securityService;
    @Autowired public void setSecurityService(SecurityIntegrationService s) { EncryptionConverter.securityService = s; }
    @Override public String convertToDatabaseColumn(String attr) {
        if (attr == null || securityService == null) return attr;
        try {
            PublicKeyResponseDTO key = securityService.fetchCurrentPublicKey();
            RSAPublicKey pub = new RSAPublicKey(key.getPublicE(), new BigInteger(key.getPublicN()));
            return key.getId() + ":" + Base64.getEncoder().encodeToString(RSAEncryption.encrypt(pub, attr).getBytes());
        } catch(Exception e) { return null; }
    }
    @Override public String convertToEntityAttribute(String db) {
        if (db == null || securityService == null) return db;
        try {
            String[] p = db.split(":");
            if (p.length != 2) return db;
            PrivateKeyResponseDTO dto = securityService.fetchPrivateKeyById(Long.parseLong(p[0]));
            RSAPrivateKey pk = new RSAPrivateKey(new BigInteger(dto.getPublicN()), new BigInteger(dto.getPrivateD()));
            return RSAEncryption.decrypt(pk, new String(Base64.getDecoder().decode(p[1])));
        } catch(Exception e) { return null; }
    }
}

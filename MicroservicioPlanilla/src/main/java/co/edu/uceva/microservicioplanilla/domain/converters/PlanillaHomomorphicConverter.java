package co.edu.uceva.microservicioplanilla.domain.converters;

import co.uceva.edu.security.homomorphic.HomomorphicEncryption;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@Converter
public class PlanillaHomomorphicConverter implements AttributeConverter<String, String> {

    @Value("${app.security.homomorphic.a-sets}")
    private String aSetsConfig;

    private volatile byte[] parsedASets;

    @Override
    public String convertToDatabaseColumn(String attr) {
        if (attr == null || attr.isEmpty()) return attr;
        try {
            return HomomorphicEncryption.encrypt(attr, getASets());
        } catch (Exception e) {
            return null;
        }
    }

    @Override
    public String convertToEntityAttribute(String db) {
        if (db == null || db.isEmpty()) return db;
        try {
            return HomomorphicEncryption.decrypt(db);
        } catch (Exception e) {
            return null;
        }
    }

    private byte[] getASets() {
        byte[] local = parsedASets;
        if (local == null) {
            local = parseASets(aSetsConfig);
            parsedASets = local;
        }
        return local;
    }

    private byte[] parseASets(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("app.security.homomorphic.a-sets is empty");
        }

        String[] tokens = value.split(",");
        byte[] result = new byte[tokens.length];

        for (int i = 0; i < tokens.length; i++) {
            String token = tokens[i].trim();
            if (token.startsWith("0x") || token.startsWith("0X")) {
                token = token.substring(2);
            }

            int parsed = Integer.parseInt(token, 16);
            if (parsed < 0 || parsed > 0xFF) {
                throw new IllegalArgumentException("Invalid byte value in app.security.homomorphic.a-sets: " + tokens[i]);
            }
            result[i] = (byte) parsed;
        }

        return result;
    }
}
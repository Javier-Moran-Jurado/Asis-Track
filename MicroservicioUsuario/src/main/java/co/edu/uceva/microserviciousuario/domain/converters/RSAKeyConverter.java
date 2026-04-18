package co.edu.uceva.microserviciousuario.domain.converters;

import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAKeyPair;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import co.uceva.edu.security.RSA.RSAPublicKey;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.Base64;

@Converter
public class RSAKeyConverter implements AttributeConverter<RSAKeyPair, String> {

    private RSAPublicKey masterPublicKey;
    private RSAPrivateKey masterPrivateKey;
    @Override
    public String convertToDatabaseColumn(RSAKeyPair attribute) {
        String b64DCrypt = Base64
                .getEncoder()
                .encodeToString(
                        RSAEncryption.encrypt(
                                masterPublicKey,
                                attribute
                                        .getPrivateKey()
                                        .getD().toString())
                        .getBytes()
                );
        BigInteger n = attribute.getPrivateKey().getN();
        long e = attribute.getPublicKey().getE();

        return b64DCrypt + ":" + n + ":" + e;
    }

    @Override
    public RSAKeyPair convertToEntityAttribute(String dbData) {
        String[] data = dbData.split(":");
        String dString = Arrays.toString(Base64
                .getDecoder()
                .decode(
                        RSAEncryption.decrypt(
                                        masterPrivateKey,
                                        data[0])
                                .getBytes()
                ));
        BigInteger n = new BigInteger(data[1]);
        long e = Long.parseLong(data[2]);
        BigInteger d = new BigInteger(dString);
        return new RSAKeyPair(e, d, n);
    }
}

package co.uceva.edu.security.RSA;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.security.SecureRandom;
import java.nio.charset.StandardCharsets;

public class RSAEncryption {

    public static RSAKeyPair generateKeyPair(){
        BigInteger q;
        BigInteger p;
        BigInteger n;
        BigInteger phiN;
        BigInteger d;
        SecureRandom random = new SecureRandom();
        long e = 65537;
        int bitLength = 1024;
        q = BigInteger.probablePrime(bitLength / 2, random);
        p = BigInteger.probablePrime(bitLength / 2, random);
        n = p.multiply(q);
        phiN = p.subtract(BigInteger.ONE).multiply(q.subtract(BigInteger.ONE));
        d = BigInteger.valueOf(e).modInverse(phiN);
        RSAPublicKey publicKey = new RSAPublicKey(e, n);
        RSAPrivateKey privateKey = new RSAPrivateKey(n, d);
        return new RSAKeyPair(privateKey, publicKey);
    }

    public static String encrypt(RSAPublicKey key, String text){
        if (text == null || text.isEmpty()) return "";
        byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
        int chunkSize = (key.getN().bitLength() / 8) - 1;
        StringBuilder sb = new StringBuilder();
        
        for (int i = 0; i < bytes.length; i += chunkSize) {
            int len = Math.min(chunkSize, bytes.length - i);
            byte[] chunk = new byte[len];
            System.arraycopy(bytes, i, chunk, 0, len);
            
            BigInteger m = new BigInteger(1, chunk);
            BigInteger c = m.modPow(BigInteger.valueOf(key.getE()), key.getN());
            sb.append(c.toString()).append(",");
        }
        return sb.length() > 0 ? sb.substring(0, sb.length() - 1) : "";
    }

    public static String decrypt(RSAPrivateKey key, String cipherText){
        if (cipherText == null || cipherText.isEmpty()) return "";
        String[] parts = cipherText.split(",");
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        
        for (String part : parts) {
            BigInteger t = new BigInteger(part.trim()).modPow(key.getD(), key.getN());
            byte[] decryptedBytes = t.toByteArray();
            int start = (decryptedBytes.length > 1 && decryptedBytes[0] == 0) ? 1 : 0;
            baos.write(decryptedBytes, start, decryptedBytes.length - start);
        }
        return baos.toString(StandardCharsets.UTF_8);
    }
}

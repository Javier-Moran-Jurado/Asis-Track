package co.uceva.edu.security.RSA;

import java.math.BigInteger;
import java.security.SecureRandom;
import java.util.StringTokenizer;

public class RSAEncryption {

    public static RSAKeyPair generateKeyPair(){
        BigInteger q;
        BigInteger p;
        BigInteger n;
        BigInteger phiN;
        BigInteger d;
        SecureRandom random = new SecureRandom();
        long e = 65537;
        int bitLength = 2048;
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
        BigInteger m = new BigInteger(text.getBytes());
        BigInteger c = m.modPow(BigInteger.valueOf(key.getE()), key.getN());
        return c.toString();
    }

    public static String decrypt(RSAPrivateKey key, String cipherText){
        BigInteger c = new BigInteger(cipherText);
        BigInteger t = c.modPow(key.getD(), key.getN());
        return new String(t.toByteArray());
    }
}

package co.uceva.edu.security.RSA;

import java.math.BigInteger;

public class RSAKeyPair {
    private RSAPrivateKey privateKey;
    private RSAPublicKey publicKey;

    public RSAKeyPair(RSAPrivateKey privateKey, RSAPublicKey publicKey){
        this.privateKey = privateKey;
        this.publicKey = publicKey;
    }

    public RSAKeyPair(long e, BigInteger d, BigInteger n){
        this.privateKey = new RSAPrivateKey(n, d);
        this.publicKey = new RSAPublicKey(e, n);
    }

    public RSAPrivateKey getPrivateKey() {
        return privateKey;
    }

    public void setPrivateKey(RSAPrivateKey privateKey) {
        this.privateKey = privateKey;
    }

    public RSAPublicKey getPublicKey() {
        return publicKey;
    }

    public void setPublicKey(RSAPublicKey publicKey) {
        this.publicKey = publicKey;
    }
}

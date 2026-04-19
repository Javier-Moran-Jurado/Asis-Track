package co.uceva.edu.security.RSA;

import java.math.BigInteger;

public class RSAPublicKey {

    private long e;
    private BigInteger n;

    public RSAPublicKey(long e, BigInteger n) {
        this.e = e;
        this.n = n;
    }

    public long getE() {
        return e;
    }

    public void setE(long e) {
        this.e = e;
    }

    public BigInteger getN() {
        return n;
    }

    public void setN(BigInteger n) {
        this.n = n;
    }
}

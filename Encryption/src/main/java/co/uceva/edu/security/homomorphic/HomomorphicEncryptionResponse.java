package co.uceva.edu.security.homomorphic;

public class HomomorphicEncryptionResponse {
    private byte[] ciphertext;
    private byte[] key;

    public HomomorphicEncryptionResponse(byte[] ciphertext, byte[] key) {
        this.ciphertext = ciphertext;
        this.key = key;
    }

    public byte[] getCiphertext() {
        return ciphertext;
    }

    public void setCiphertext(byte[] ciphertext) {
        this.ciphertext = ciphertext;
    }

    public byte[] getKey() {
        return key;
    }

    public void setKey(byte[] key) {
        this.key = key;
    }
}
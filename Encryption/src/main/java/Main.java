import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAKeyPair;

public class Main {
    public static void main(String[] args) {
        RSAKeyPair pair = RSAEncryption.generateKeyPair();
        System.out.println("d: " + pair.getPrivateKey().getD() +
                "\nn: " + pair.getPrivateKey().getN() +
                "\ne: " + pair.getPublicKey().getE());
    }
}


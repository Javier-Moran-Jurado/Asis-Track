import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAKeyPair;
import co.uceva.edu.security.homomorphic.HomomorphicEncryption;

import java.nio.charset.StandardCharsets;

public class Main {

    public static void main(String[] args) {
        byte[] A_SETS = {
            (byte) 0xFC, // 11111100
            (byte) 0xF3, // 11110011
            (byte) 0xCF, // 11001111
            (byte) 0x3F, // 00111111
            (byte) 0x7E, // 01111110
            (byte) 0xF9, // 11111001
            (byte) 0xE7, // 11100111
            (byte) 0x9F  // 10011111
    };
        RSAKeyPair pair = RSAEncryption.generateKeyPair();
        System.out.println("d: " + pair.getPrivateKey().getD() +
                "\nn: " + pair.getPrivateKey().getN() +
                "\ne: " + pair.getPublicKey().getE());
        String ant = "";
        for (int i = 0; i < A_SETS.length; i++) {
            String cypher = HomomorphicEncryption.encrypt("juan.perez@uceva.edu.co", A_SETS);
            System.out.println(cypher);
            System.out.println(HomomorphicEncryption.decrypt(cypher));
        }
    }
}


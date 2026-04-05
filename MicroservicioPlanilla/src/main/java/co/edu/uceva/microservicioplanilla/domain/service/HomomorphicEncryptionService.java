package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.HomomorphicEncryptionResponse;
import org.springframework.stereotype.Service;

import java.util.Random;

@Service
public class HomomorphicEncryptionService {

    private static final byte[] A_SETS = {
            (byte) 0xFC, // 11111100
            (byte) 0xF3, // 11110011
            (byte) 0xCF, // 11001111
            (byte) 0x3F, // 00111111
            (byte) 0x7E, // 01111110
            (byte) 0xF9, // 11111001
            (byte) 0xE7, // 11100111
            (byte) 0x9F  // 10011111
    };

    private final Random random = new Random();

    public HomomorphicEncryptionResponse encrypt(byte[] plaintext) {
        if (plaintext == null) return null;

        byte[] ciphertext = new byte[plaintext.length];
        byte[] key = new byte[plaintext.length];

        for (int i = 0; i < plaintext.length; i += 4) {
            int limit = Math.min(4, plaintext.length - i);
            byte[] p = new byte[4];
            
            for (int j = 0; j < limit; j++) {
                byte a = A_SETS[random.nextInt(A_SETS.length)];
                p[j] = (byte) ((plaintext[i + j] | a) ^ a);
            }

            byte l1_0 = (byte) (p[0] | p[2]);
            byte l1_1 = (byte) (p[1] | p[3]);
            byte l1_2 = (byte) (p[0] ^ p[2]);
            byte l1_3 = (byte) (p[1] ^ p[3]);

            byte y_0 = (byte) (l1_0 | l1_1);
            byte y_1 = (byte) (l1_0 ^ l1_1);
            byte y_2 = (byte) (l1_2 | l1_3);
            byte y_3 = (byte) (l1_2 ^ l1_3);

            byte[] Y = {y_0, y_1, y_2, y_3};

            byte d1_0 = (byte) (y_0 ^ y_1);
            byte d1_1 = (byte) (y_0 ^ y_1);
            byte d1_2 = (byte) (y_2 ^ y_3);
            byte d1_3 = (byte) (y_2 ^ y_3);

            byte z_0 = (byte) (d1_0 ^ d1_2);
            byte z_1 = (byte) (d1_1 ^ d1_3);
            byte z_2 = (byte) (d1_0 ^ d1_2);
            byte z_3 = (byte) (d1_1 ^ d1_3);

            byte[] Z = {z_0, z_1, z_2, z_3};

            for (int j = 0; j < limit; j++) {
                ciphertext[i + j] = Y[j];
                key[i + j] = (byte) (plaintext[i + j] ^ Z[j]);
            }
        }

        return new HomomorphicEncryptionResponse(ciphertext, key);
    }

    public byte[] decrypt(byte[] ciphertext, byte[] key) {
        if (ciphertext == null || key == null || ciphertext.length != key.length) {
            throw new IllegalArgumentException("Invalid ciphertext or key length");
        }

        byte[] plaintext = new byte[ciphertext.length];

        for (int i = 0; i < ciphertext.length; i += 4) {
            int limit = Math.min(4, ciphertext.length - i);
            byte[] c = new byte[4];
            
            for (int j = 0; j < limit; j++) {
                c[j] = ciphertext[i + j];
            }

            byte d1_0 = (byte) (c[0] ^ c[1]);
            byte d1_1 = (byte) (c[0] ^ c[1]);
            byte d1_2 = (byte) (c[2] ^ c[3]);
            byte d1_3 = (byte) (c[2] ^ c[3]);

            byte z_0 = (byte) (d1_0 ^ d1_2);
            byte z_1 = (byte) (d1_1 ^ d1_3);
            byte z_2 = (byte) (d1_0 ^ d1_2);
            byte z_3 = (byte) (d1_1 ^ d1_3);

            byte[] Z = {z_0, z_1, z_2, z_3};

            for (int j = 0; j < limit; j++) {
                plaintext[i + j] = (byte) (Z[j] ^ key[i + j]);
            }
        }

        return plaintext;
    }
}

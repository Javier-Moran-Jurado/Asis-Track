package co.uceva.edu.security.homomorphic;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Random;

public class HomomorphicEncryption {

    private static final Random random = new SecureRandom();

    public static String encrypt(String text, byte[] aSets) {
        if (text == null || text.isEmpty()) return "";

        HomomorphicEncryptionResponse response = encrypt(text.getBytes(StandardCharsets.UTF_8), aSets);
        String ciphertextB64 = Base64.getEncoder().encodeToString(response.getCiphertext());
        String keyB64 = Base64.getEncoder().encodeToString(response.getKey());
        return ciphertextB64 + ":" + keyB64;
    }

    public static String decrypt(String encryptedPayload) {
        if (encryptedPayload == null || encryptedPayload.isEmpty()) return "";

        String[] parts = encryptedPayload.split(":", 2);
        if (parts.length != 2) {
            throw new IllegalArgumentException("Invalid homomorphic payload format");
        }

        byte[] ciphertext = Base64.getDecoder().decode(parts[0]);
        byte[] key = Base64.getDecoder().decode(parts[1]);
        return new String(decrypt(ciphertext, key), StandardCharsets.UTF_8);
    }

    public static HomomorphicEncryptionResponse encrypt(byte[] plaintext, byte[] aSets) {
        if (plaintext == null) return null;

        byte[] masks = validateASets(aSets);

        byte[] ciphertext = new byte[plaintext.length];
        byte[] key = new byte[plaintext.length];

        for (int i = 0; i < plaintext.length; i += 4) {
            int limit = Math.min(4, plaintext.length - i);
            byte[] p = new byte[4];

            for (int j = 0; j < limit; j++) {
                byte a = masks[random.nextInt(masks.length)];
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

    public static byte[] decrypt(byte[] ciphertext, byte[] key) {
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

    private static byte[] validateASets(byte[] aSets) {
        if (aSets == null || aSets.length == 0) {
            throw new IllegalArgumentException("A_SETS cannot be null or empty");
        }
        return aSets.clone();
    }
}
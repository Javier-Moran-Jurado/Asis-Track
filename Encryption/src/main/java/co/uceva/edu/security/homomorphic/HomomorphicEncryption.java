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

        int blocks = (plaintext.length + 3) / 4;
        byte[] ciphertext = new byte[blocks * 4];
        byte[] key = new byte[plaintext.length];

        for (int i = 0; i < plaintext.length; i += 4) {
            int limit = Math.min(4, plaintext.length - i);
            byte[] p = new byte[4];

            byte zTarget = deriveZTarget(plaintext, i, limit, masks);

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

            byte[] noise = new byte[4];
            random.nextBytes(noise);
            for (int j = 0; j < 4; j++) {
                Y[j] = (byte) (Y[j] ^ noise[j]);
            }

            byte zCurrent = (byte) (Y[0] ^ Y[1] ^ Y[2] ^ Y[3]);
            byte delta = (byte) (zCurrent ^ zTarget);
            Y[0] = (byte) (Y[0] ^ delta);

            for (int j = 0; j < 4; j++) {
                ciphertext[i + j] = Y[j];
            }
            for (int j = 0; j < limit; j++) {
                key[i + j] = (byte) (plaintext[i + j] ^ zTarget);
            }
        }

        return new HomomorphicEncryptionResponse(ciphertext, key);
    }

    public static byte[] decrypt(byte[] ciphertext, byte[] key) {
        if (ciphertext == null || key == null) {
            throw new IllegalArgumentException("Invalid ciphertext or key length");
        }
        int paddedCiphertextLength = ((key.length + 3) / 4) * 4;
        boolean isLegacy = ciphertext.length == key.length;
        boolean isPadded = ciphertext.length == paddedCiphertextLength;
        if (!isLegacy && !isPadded) {
            throw new IllegalArgumentException("Invalid ciphertext or key length");
        }

        byte[] plaintext = new byte[ciphertext.length];

        plaintext = new byte[key.length];
        for (int i = 0; i < key.length; i += 4) {
            int limit = Math.min(4, key.length - i);
            byte c0 = 0;
            byte c1 = 0;
            byte c2 = 0;
            byte c3 = 0;

            if (i < ciphertext.length) {
                c0 = ciphertext[i];
            }
            if (i + 1 < ciphertext.length) {
                c1 = ciphertext[i + 1];
            }
            if (i + 2 < ciphertext.length) {
                c2 = ciphertext[i + 2];
            }
            if (i + 3 < ciphertext.length) {
                c3 = ciphertext[i + 3];
            }

            byte z = (byte) (c0 ^ c1 ^ c2 ^ c3);

            for (int j = 0; j < limit; j++) {
                plaintext[i + j] = (byte) (z ^ key[i + j]);
            }
        }

        return plaintext;
    }

    private static byte deriveZTarget(byte[] plaintext, int offset, int limit, byte[] masks) {
        byte z = 0;
        for (int j = 0; j < limit; j++) {
            z ^= plaintext[offset + j];
        }
        for (byte m : masks) {
            z ^= m;
        }
        z ^= (byte) offset;
        z ^= (byte) (offset >>> 8);
        z ^= (byte) limit;
        return z;
    }

    private static byte[] validateASets(byte[] aSets) {
        if (aSets == null || aSets.length == 0) {
            throw new IllegalArgumentException("A_SETS cannot be null or empty");
        }
        return aSets.clone();
    }
}
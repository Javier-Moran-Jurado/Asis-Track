package co.uceva.edu.security.AES;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;

/**
 * Implementación manual de AES-256 en modo CBC con padding PKCS#7.
 * Sin dependencias de javax.crypto.
 */
public class AESEncryption {

    private static final int NB = 4;   // número de columnas (words) en el estado
    private static final int NR = 14;  // rondas para AES-256
    private static final int NK = 8;   // words de 32 bits en la clave (256 bits)
    private static final int BLOCK_SIZE = 16;

    private static final int[] SBOX = {
        0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
        0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
        0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
        0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
        0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
        0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
        0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
        0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
        0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
        0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
        0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
        0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
        0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
        0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
        0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
        0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
    };

    private static final int[] INV_SBOX = {
        0x52,0x09,0x6a,0xd5,0x30,0x36,0xa5,0x38,0xbf,0x40,0xa3,0x9e,0x81,0xf3,0xd7,0xfb,
        0x7c,0xe3,0x39,0x82,0x9b,0x2f,0xff,0x87,0x34,0x8e,0x43,0x44,0xc4,0xde,0xe9,0xcb,
        0x54,0x7b,0x94,0x32,0xa6,0xc2,0x23,0x3d,0xee,0x4c,0x95,0x0b,0x42,0xfa,0xc3,0x4e,
        0x08,0x2e,0xa1,0x66,0x28,0xd9,0x24,0xb2,0x76,0x5b,0xa2,0x49,0x6d,0x8b,0xd1,0x25,
        0x72,0xf8,0xf6,0x64,0x86,0x68,0x98,0x16,0xd4,0xa4,0x5c,0xcc,0x5d,0x65,0xb6,0x92,
        0x6c,0x70,0x48,0x50,0xfd,0xed,0xb9,0xda,0x5e,0x15,0x46,0x57,0xa7,0x8d,0x9d,0x84,
        0x90,0xd8,0xab,0x00,0x8c,0xbc,0xd3,0x0a,0xf7,0xe4,0x58,0x05,0xb8,0xb3,0x45,0x06,
        0xd0,0x2c,0x1e,0x8f,0xca,0x3f,0x0f,0x02,0xc1,0xaf,0xbd,0x03,0x01,0x13,0x8a,0x6b,
        0x3a,0x91,0x11,0x41,0x4f,0x67,0xdc,0xea,0x97,0xf2,0xcf,0xce,0xf0,0xb4,0xe6,0x73,
        0x96,0xac,0x74,0x22,0xe7,0xad,0x35,0x85,0xe2,0xf9,0x37,0xe8,0x1c,0x75,0xdf,0x6e,
        0x47,0xf1,0x1a,0x71,0x1d,0x29,0xc5,0x89,0x6f,0xb7,0x62,0x0e,0xaa,0x18,0xbe,0x1b,
        0xfc,0x56,0x3e,0x4b,0xc6,0xd2,0x79,0x20,0x9a,0xdb,0xc0,0xfe,0x78,0xcd,0x5a,0xf4,
        0x1f,0xdd,0xa8,0x33,0x88,0x07,0xc7,0x31,0xb1,0x12,0x10,0x59,0x27,0x80,0xec,0x5f,
        0x60,0x51,0x7f,0xa9,0x19,0xb5,0x4a,0x0d,0x2d,0xe5,0x7a,0x9f,0x93,0xc9,0x9c,0xef,
        0xa0,0xe0,0x3b,0x4d,0xae,0x2a,0xf5,0xb0,0xc8,0xeb,0xbb,0x3c,0x83,0x53,0x99,0x61,
        0x17,0x2b,0x04,0x7e,0xba,0x77,0xd6,0x26,0xe1,0x69,0x14,0x63,0x55,0x21,0x0c,0x7d
    };

    private static final int[] RCON = {
        0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
    };

    private static final int[] MIX_COL_MATRIX = {
        0x02, 0x03, 0x01, 0x01,
        0x01, 0x02, 0x03, 0x01,
        0x01, 0x01, 0x02, 0x03,
        0x03, 0x01, 0x01, 0x02
    };

    private static final int[] INV_MIX_COL_MATRIX = {
        0x0e, 0x0b, 0x0d, 0x09,
        0x09, 0x0e, 0x0b, 0x0d,
        0x0d, 0x09, 0x0e, 0x0b,
        0x0b, 0x0d, 0x09, 0x0e
    };

    // ==================== Public API ====================

    public static String encrypt(byte[] key, byte[] iv, String plainText) {
        byte[] padded = pkcs7Pad(plainText.getBytes(StandardCharsets.UTF_8));
        byte[] prev = Arrays.copyOf(iv, BLOCK_SIZE);
        byte[] out = new byte[padded.length];

        for (int i = 0; i < padded.length; i += BLOCK_SIZE) {
            byte[] block = new byte[BLOCK_SIZE];
            System.arraycopy(padded, i, block, 0, BLOCK_SIZE);
            xorBytes(block, prev);
            encryptBlock(block, key);
            System.arraycopy(block, 0, out, i, BLOCK_SIZE);
            prev = block;
        }
        return Base64.getEncoder().encodeToString(out);
    }

    public static String decrypt(byte[] key, byte[] iv, String base64CipherText) {
        byte[] cipher = Base64.getDecoder().decode(base64CipherText);
        byte[] prev = Arrays.copyOf(iv, BLOCK_SIZE);
        byte[] out = new byte[cipher.length];

        for (int i = 0; i < cipher.length; i += BLOCK_SIZE) {
            byte[] block = new byte[BLOCK_SIZE];
            System.arraycopy(cipher, i, block, 0, BLOCK_SIZE);
            byte[] cipherBlock = Arrays.copyOf(block, BLOCK_SIZE);
            decryptBlock(block, key);
            xorBytes(block, prev);
            System.arraycopy(block, 0, out, i, BLOCK_SIZE);
            prev = cipherBlock;
        }
        byte[] unpadded = pkcs7Unpad(out);
        return new String(unpadded, StandardCharsets.UTF_8);
    }

    public static byte[] generateRandomKey() {
        byte[] key = new byte[32];
        new SecureRandom().nextBytes(key);
        return key;
    }

    public static byte[] generateIV() {
        byte[] iv = new byte[BLOCK_SIZE];
        new SecureRandom().nextBytes(iv);
        return iv;
    }

    // ==================== AES Block Operations ====================

    private static void encryptBlock(byte[] state, byte[] key) {
        int[] expandedKey = keyExpansion(key);
        addRoundKey(state, expandedKey, 0);
        for (int round = 1; round < NR; round++) {
            subBytes(state);
            shiftRows(state);
            mixColumns(state);
            addRoundKey(state, expandedKey, round * NB);
        }
        subBytes(state);
        shiftRows(state);
        addRoundKey(state, expandedKey, NR * NB);
    }

    private static void decryptBlock(byte[] state, byte[] key) {
        int[] expandedKey = keyExpansion(key);
        addRoundKey(state, expandedKey, NR * NB);
        for (int round = NR - 1; round >= 1; round--) {
            invShiftRows(state);
            invSubBytes(state);
            addRoundKey(state, expandedKey, round * NB);
            invMixColumns(state);
        }
        invShiftRows(state);
        invSubBytes(state);
        addRoundKey(state, expandedKey, 0);
    }

    // ==================== SubBytes / ShiftRows / MixColumns / AddRoundKey ====================

    private static void subBytes(byte[] state) {
        for (int i = 0; i < 16; i++) state[i] = (byte) SBOX[state[i] & 0xFF];
    }

    private static void invSubBytes(byte[] state) {
        for (int i = 0; i < 16; i++) state[i] = (byte) INV_SBOX[state[i] & 0xFF];
    }

    private static void shiftRows(byte[] state) {
        byte[] tmp = new byte[16];
        tmp[0] = state[0]; tmp[1] = state[5]; tmp[2] = state[10]; tmp[3] = state[15];
        tmp[4] = state[4]; tmp[5] = state[9]; tmp[6] = state[14]; tmp[7] = state[3];
        tmp[8] = state[8]; tmp[9] = state[13]; tmp[10] = state[2]; tmp[11] = state[7];
        tmp[12] = state[12]; tmp[13] = state[1]; tmp[14] = state[6]; tmp[15] = state[11];
        System.arraycopy(tmp, 0, state, 0, 16);
    }

    private static void invShiftRows(byte[] state) {
        byte[] tmp = new byte[16];
        tmp[0] = state[0]; tmp[1] = state[13]; tmp[2] = state[10]; tmp[3] = state[7];
        tmp[4] = state[4]; tmp[5] = state[1]; tmp[6] = state[14]; tmp[7] = state[11];
        tmp[8] = state[8]; tmp[9] = state[5]; tmp[10] = state[2]; tmp[11] = state[15];
        tmp[12] = state[12]; tmp[13] = state[9]; tmp[14] = state[6]; tmp[15] = state[3];
        System.arraycopy(tmp, 0, state, 0, 16);
    }

    private static void mixColumns(byte[] state) {
        byte[] tmp = new byte[16];
        for (int c = 0; c < 4; c++) {
            tmp[c] = (byte) (gfMul(state[c], 2) ^ gfMul(state[4 + c], 3) ^ state[8 + c] ^ state[12 + c]);
            tmp[4 + c] = (byte) (state[c] ^ gfMul(state[4 + c], 2) ^ gfMul(state[8 + c], 3) ^ state[12 + c]);
            tmp[8 + c] = (byte) (state[c] ^ state[4 + c] ^ gfMul(state[8 + c], 2) ^ gfMul(state[12 + c], 3));
            tmp[12 + c] = (byte) (gfMul(state[c], 3) ^ state[4 + c] ^ state[8 + c] ^ gfMul(state[12 + c], 2));
        }
        System.arraycopy(tmp, 0, state, 0, 16);
    }

    private static void invMixColumns(byte[] state) {
        byte[] tmp = new byte[16];
        for (int c = 0; c < 4; c++) {
            tmp[c] = (byte) (gfMul(state[c], 0x0e) ^ gfMul(state[4 + c], 0x0b) ^ gfMul(state[8 + c], 0x0d) ^ gfMul(state[12 + c], 0x09));
            tmp[4 + c] = (byte) (gfMul(state[c], 0x09) ^ gfMul(state[4 + c], 0x0e) ^ gfMul(state[8 + c], 0x0b) ^ gfMul(state[12 + c], 0x0d));
            tmp[8 + c] = (byte) (gfMul(state[c], 0x0d) ^ gfMul(state[4 + c], 0x09) ^ gfMul(state[8 + c], 0x0e) ^ gfMul(state[12 + c], 0x0b));
            tmp[12 + c] = (byte) (gfMul(state[c], 0x0b) ^ gfMul(state[4 + c], 0x0d) ^ gfMul(state[8 + c], 0x09) ^ gfMul(state[12 + c], 0x0e));
        }
        System.arraycopy(tmp, 0, state, 0, 16);
    }

    private static void addRoundKey(byte[] state, int[] expandedKey, int startWord) {
        for (int c = 0; c < 4; c++) {
            int word = expandedKey[startWord + c];
            state[c] ^= (byte) (word >> 24);
            state[4 + c] ^= (byte) (word >> 16);
            state[8 + c] ^= (byte) (word >> 8);
            state[12 + c] ^= (byte) word;
        }
    }

    // ==================== Key Expansion ====================

    private static int[] keyExpansion(byte[] key) {
        int[] w = new int[NB * (NR + 1)]; // 60 words para AES-256
        for (int i = 0; i < NK; i++) {
            w[i] = ((key[4 * i] & 0xFF) << 24)
                 | ((key[4 * i + 1] & 0xFF) << 16)
                 | ((key[4 * i + 2] & 0xFF) << 8)
                 | (key[4 * i + 3] & 0xFF);
        }
        for (int i = NK; i < NB * (NR + 1); i++) {
            int temp = w[i - 1];
            if (i % NK == 0) {
                temp = subWord(rotWord(temp)) ^ (RCON[(i / NK) - 1] << 24);
            } else if (NK > 6 && i % NK == 4) {
                temp = subWord(temp);
            }
            w[i] = w[i - NK] ^ temp;
        }
        return w;
    }

    private static int rotWord(int word) {
        return ((word << 8) & 0xFFFFFFFF) | ((word >>> 24) & 0xFF);
    }

    private static int subWord(int word) {
        return (SBOX[(word >>> 24) & 0xFF] << 24)
             | (SBOX[(word >>> 16) & 0xFF] << 16)
             | (SBOX[(word >>> 8) & 0xFF] << 8)
             | (SBOX[word & 0xFF]);
    }

    // ==================== Galois Field Multiplication ====================

    private static int gfMul(int a, int b) {
        int p = 0;
        int hiBitSet;
        for (int i = 0; i < 8; i++) {
            if ((b & 1) != 0) p ^= a;
            hiBitSet = a & 0x80;
            a <<= 1;
            if (hiBitSet != 0) a ^= 0x1b;
            b >>= 1;
        }
        return p & 0xFF;
    }

    // ==================== CBC Helpers ====================

    private static void xorBytes(byte[] a, byte[] b) {
        for (int i = 0; i < BLOCK_SIZE; i++) a[i] ^= b[i];
    }

    private static byte[] pkcs7Pad(byte[] data) {
        int padLen = BLOCK_SIZE - (data.length % BLOCK_SIZE);
        byte[] padded = Arrays.copyOf(data, data.length + padLen);
        for (int i = data.length; i < padded.length; i++) padded[i] = (byte) padLen;
        return padded;
    }

    private static byte[] pkcs7Unpad(byte[] data) {
        int padLen = data[data.length - 1] & 0xFF;
        return Arrays.copyOf(data, data.length - padLen);
    }
}

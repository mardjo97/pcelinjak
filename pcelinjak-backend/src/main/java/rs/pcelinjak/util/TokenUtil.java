package rs.pcelinjak.util;

import java.security.SecureRandom;

/** Generiše sigurne token ključeve za aktivaciju naloga. */
public final class TokenUtil {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int KEY_LENGTH_BYTES = 10; // 20 hex chars

    private TokenUtil() {
    }

    public static String generateActivationKey() {
        byte[] bytes = new byte[KEY_LENGTH_BYTES];
        RANDOM.nextBytes(bytes);
        StringBuilder sb = new StringBuilder(KEY_LENGTH_BYTES * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}

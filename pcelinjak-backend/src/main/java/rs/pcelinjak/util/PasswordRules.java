package rs.pcelinjak.util;

import java.util.ArrayList;
import java.util.List;

public final class PasswordRules {

    public static final int MIN_LENGTH = 6;

    private PasswordRules() {
    }

    public static boolean isValid(String password) {
        return errorMessage(password) == null;
    }

    public static String errorMessage(String password) {
        if (password == null) {
            password = "";
        }
        List<String> missing = new ArrayList<>();
        if (password.length() < MIN_LENGTH) {
            missing.add("najmanje 6 karaktera");
        }
        boolean upper = false;
        boolean lower = false;
        boolean digit = false;
        for (int i = 0; i < password.length(); i++) {
            char c = password.charAt(i);
            if (Character.isUpperCase(c)) {
                upper = true;
            } else if (Character.isLowerCase(c)) {
                lower = true;
            } else if (Character.isDigit(c)) {
                digit = true;
            }
        }
        if (!upper) {
            missing.add("veliko slovo");
        }
        if (!lower) {
            missing.add("malo slovo");
        }
        if (!digit) {
            missing.add("broj");
        }
        if (missing.isEmpty()) {
            return null;
        }
        return "Lozinka mora imati: " + joinSr(missing) + ".";
    }

    private static String joinSr(List<String> parts) {
        if (parts.size() == 1) {
            return parts.get(0);
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < parts.size() - 1; i++) {
            if (i > 0) {
                sb.append(", ");
            }
            sb.append(parts.get(i));
        }
        sb.append(" i ").append(parts.get(parts.size() - 1));
        return sb.toString();
    }
}

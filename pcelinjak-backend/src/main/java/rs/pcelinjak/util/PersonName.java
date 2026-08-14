package rs.pcelinjak.util;

import rs.pcelinjak.entity.User;

public final class PersonName {

    private PersonName() {
    }

    public static void apply(User user, String firstName, String lastName, String fullName) {
        String first = trimToEmpty(firstName);
        String last = trimToEmpty(lastName);
        if (first.isEmpty() && last.isEmpty() && fullName != null && !fullName.isBlank()) {
            String[] parts = split(fullName.trim());
            first = parts[0];
            last = parts[1];
        }
        user.firstName = first;
        user.lastName = last;
        user.name = display(first, last);
    }

    public static String display(String first, String last) {
        String f = trimToEmpty(first);
        String l = trimToEmpty(last);
        if (f.isEmpty()) {
            return l;
        }
        if (l.isEmpty()) {
            return f;
        }
        return f + " " + l;
    }

    public static String[] split(String name) {
        int i = name.indexOf(' ');
        if (i < 0) {
            return new String[]{name, ""};
        }
        return new String[]{name.substring(0, i).trim(), name.substring(i + 1).trim()};
    }

    private static String trimToEmpty(String s) {
        return s == null ? "" : s.trim();
    }
}

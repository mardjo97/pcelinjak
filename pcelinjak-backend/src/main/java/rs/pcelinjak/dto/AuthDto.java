package rs.pcelinjak.dto;

public class AuthDto {

    public static class RegisterRequest {
        public String email;
        public String password;
        public String name;
        public String phone;
        public String deviceUuid;
    }

    public static class LoginRequest {
        public String email;
        public String password;
        public String deviceUuid;
    }

    public static class LoginResponse {
        public String token;
        public Long userId;
        public String email;
        public String name;
        public String phone;
    }

    public static class MessageResponse {
        public String message;

        public MessageResponse() {
        }

        public MessageResponse(String message) {
            this.message = message;
        }
    }

    public static class DeleteAccountRequest {
        public String password;
    }
}

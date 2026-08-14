package rs.pcelinjak;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;
import rs.pcelinjak.entity.User;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

@QuarkusTest
public class MeProfileTest {

    @Test
    public void updateProfileAndChangePassword() {
        String email = "profile-" + UUID.randomUUID() + "@example.com";
        String device = UUID.randomUUID().toString();

        given()
                .contentType(ContentType.JSON)
                .body(Map.of(
                        "email", email,
                        "password", "Secret123",
                        "firstName", "Ana",
                        "lastName", "Marković",
                        "phone", "+381641234567",
                        "deviceUuid", device))
                .when().post("/auth/register")
                .then().statusCode(201);

        User user = User.findByEmail(email);
        given()
                .queryParam("key", user.activationKey)
                .when().get("/auth/activate")
                .then().statusCode(200);

        String token = given()
                .contentType(ContentType.JSON)
                .body(Map.of(
                        "email", email,
                        "password", "Secret123",
                        "deviceUuid", device))
                .when().post("/auth/login")
                .then().statusCode(200)
                .body("firstName", equalTo("Ana"))
                .body("lastName", equalTo("Marković"))
                .body("name", equalTo("Ana Marković"))
                .extract().path("token");

        Map<String, Object> profile = new HashMap<>();
        profile.put("firstName", "Ana");
        profile.put("lastName", "Petrović");
        profile.put("phone", "0641234567");

        given()
                .header("Authorization", "Bearer " + token)
                .header("X-Device-Id", device)
                .contentType(ContentType.JSON)
                .body(profile)
                .when().put("/me")
                .then().statusCode(200)
                .body("lastName", equalTo("Petrović"))
                .body("name", equalTo("Ana Petrović"))
                .body("phone", equalTo("0641234567"));

        given()
                .header("Authorization", "Bearer " + token)
                .header("X-Device-Id", device)
                .when().get("/me")
                .then().statusCode(200)
                .body("firstName", equalTo("Ana"))
                .body("lastName", equalTo("Petrović"));

        Map<String, String> change = new HashMap<>();
        change.put("currentPassword", "Secret123");
        change.put("newPassword", "Newpass1");

        given()
                .header("Authorization", "Bearer " + token)
                .header("X-Device-Id", device)
                .contentType(ContentType.JSON)
                .body(change)
                .when().post("/auth/change-password")
                .then().statusCode(200)
                .body("message", notNullValue());

        given()
                .contentType(ContentType.JSON)
                .body(Map.of(
                        "email", email,
                        "password", "Newpass1",
                        "deviceUuid", device))
                .when().post("/auth/login")
                .then().statusCode(200);
    }
}

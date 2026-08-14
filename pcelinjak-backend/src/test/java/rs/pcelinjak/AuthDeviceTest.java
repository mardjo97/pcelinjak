package rs.pcelinjak;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;
import rs.pcelinjak.entity.User;

import java.util.Map;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

@QuarkusTest
public class AuthDeviceTest {

    @Test
    public void pingOk() {
        given().when().get("/api/ping").then().statusCode(200).body("status", equalTo("ok"));
    }

    @Test
    public void registerActivateLoginAndDeviceMismatch() {
        String email = "test-" + UUID.randomUUID() + "@example.com";
        String deviceA = UUID.randomUUID().toString();
        String deviceB = UUID.randomUUID().toString();

        given()
                .contentType(ContentType.JSON)
                .body(Map.of(
                        "email", email,
                        "password", "Secret123",
                        "name", "Nenad",
                        "deviceUuid", deviceA))
                .when().post("/auth/register")
                .then().statusCode(201)
                .body("message", notNullValue());

        given()
                .contentType(ContentType.JSON)
                .body(Map.of(
                        "email", email,
                        "password", "Secret123",
                        "deviceUuid", deviceA))
                .when().post("/auth/login")
                .then().statusCode(403);

        User user = User.findByEmail(email);
        given()
                .queryParam("key", user.activationKey)
                .when().get("/auth/activate")
                .then().statusCode(200);

        String tokenA = given()
                .contentType(ContentType.JSON)
                .body(Map.of(
                        "email", email,
                        "password", "Secret123",
                        "deviceUuid", deviceA))
                .when().post("/auth/login")
                .then().statusCode(200)
                .body("token", notNullValue())
                .extract().path("token");

        given()
                .header("Authorization", "Bearer " + tokenA)
                .header("X-Device-Id", deviceA)
                .when().get("/api/apiaries/all")
                .then().statusCode(200);

        given()
                .contentType(ContentType.JSON)
                .body(Map.of(
                        "email", email,
                        "password", "Secret123",
                        "deviceUuid", deviceB))
                .when().post("/auth/login")
                .then().statusCode(200);

        given()
                .header("Authorization", "Bearer " + tokenA)
                .header("X-Device-Id", deviceA)
                .when().get("/api/apiaries/all")
                .then().statusCode(401)
                .body("code", equalTo("DEVICE_MISMATCH"));
    }
}

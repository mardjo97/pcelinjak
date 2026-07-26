package rs.pcelinjak.service;

import io.quarkus.mailer.Mail;
import io.quarkus.mailer.Mailer;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import rs.pcelinjak.entity.User;

import java.util.Optional;

/** Slanje emailova za aktivaciju naloga (kao u farmi). */
@ApplicationScoped
public class MailService {

    @ConfigProperty(name = "pcelinjak.mail.base-url")
    String baseUrl;

    private final Mailer mailer;

    public MailService(Mailer mailer) {
        this.mailer = mailer;
    }

    public void sendActivationEmail(User user) {
        if (user.email == null || user.email.isBlank()) {
            return;
        }
        String activationLink = baseUrl + "/auth/activate?key=" + Optional.ofNullable(user.activationKey).orElse("");
        String subject = "Pčelinjak – aktivacija naloga";
        String body = htmlMail(
                "Aktivacija naloga",
                "Poštovani/a " + escape(user.name) + ",",
                "Vaš nalog u aplikaciji Pčelinjak je kreiran. Kliknite na link ispod da ga aktivirate:",
                activationLink,
                "Aktiviraj nalog",
                "S poštovanjem, Pčelinjak");
        mailer.send(Mail.withHtml(user.email, subject, body));
    }

    private static String htmlMail(String title, String greeting, String text, String linkUrl, String linkText, String signature) {
        return """
            <!DOCTYPE html>
            <html>
            <head><meta charset="UTF-8"><title>%s</title></head>
            <body>
            <p>%s</p>
            <p>%s</p>
            <p><a href="%s">%s</a></p>
            <p>%s</p>
            </body>
            </html>
            """.formatted(title, greeting, text, linkUrl, linkText, signature);
    }

    private static String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
}

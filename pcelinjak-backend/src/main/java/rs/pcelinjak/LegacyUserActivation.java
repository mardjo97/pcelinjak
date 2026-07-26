package rs.pcelinjak;

import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.transaction.Transactional;
import rs.pcelinjak.entity.User;

/**
 * Postojeći nalozi (pre aktivacije emailom) ostaju aktivni.
 */
@ApplicationScoped
public class LegacyUserActivation {

    @Transactional
    void onStart(@Observes StartupEvent ev) {
        User.update("activated = true where activated = false and activationKey is null");
    }
}

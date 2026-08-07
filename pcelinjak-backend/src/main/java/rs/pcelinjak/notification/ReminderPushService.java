package rs.pcelinjak.notification;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.jboss.logging.Logger;
import rs.pcelinjak.entity.Apiary;
import rs.pcelinjak.entity.Hive;
import rs.pcelinjak.entity.Reminder;
import rs.pcelinjak.entity.User;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@ApplicationScoped
public class ReminderPushService {

    private static final Logger LOG = Logger.getLogger(ReminderPushService.class);

    @Inject
    NotificationClient client;

    @Transactional
    public void syncReminder(Reminder reminder) {
        if (!client.isConfigured() || reminder == null) {
            return;
        }
        String externalUserId = String.valueOf(reminder.userId);
        boolean cancel = reminder.completed
                || reminder.dateDeleted != null
                || reminder.dueAt == null
                || reminder.dueAt.isBefore(Instant.now());

        if (cancel) {
            cancelRemote(reminder);
            return;
        }

        Map<String, String> data = new HashMap<>();
        data.put("type", "reminder");
        data.put("reminderUuid", reminder.uuid);
        if (reminder.hiveUuid != null) {
            data.put("hiveUuid", reminder.hiveUuid);
        }
        if (reminder.groupHiveUuid != null) {
            data.put("groupHiveUuid", reminder.groupHiveUuid);
        }
        if (reminder.inspectionUuid != null) {
            data.put("inspectionUuid", reminder.inspectionUuid);
        }

        String notifTitle = notificationTitle(reminder);
        String notifBody = reminder.title != null && !reminder.title.isBlank()
                ? reminder.title
                : notifTitle;

        if (reminder.notificationId == null || reminder.notificationId.isBlank()) {
            Optional<NotificationClient.NotificationDto> created = client.createReminder(
                    externalUserId,
                    notifTitle,
                    notifBody,
                    reminder.dueAt,
                    data
            );
            created.ifPresent(dto -> {
                reminder.notificationId = dto.id;
                reminder.persist();
                markInvalidDevices(dto);
                LOG.infof("Zakazan remote reminder %s za user %s", dto.id, externalUserId);
            });
            return;
        }

        Optional<NotificationClient.NotificationDto> patched = client.reschedule(reminder.notificationId, reminder.dueAt);
        if (patched.isPresent()) {
            markInvalidDevices(patched.get());
        } else {
            cancelRemote(reminder);
            Optional<NotificationClient.NotificationDto> created = client.createReminder(
                    externalUserId,
                    notifTitle,
                    notifBody,
                    reminder.dueAt,
                    data
            );
            created.ifPresent(dto -> {
                reminder.notificationId = dto.id;
                reminder.persist();
                markInvalidDevices(dto);
            });
        }
    }

    /** Naslov: „Naziv pčelinjaka - barcode”. */
    private static String notificationTitle(Reminder reminder) {
        if (reminder.hiveUuid == null || reminder.hiveUuid.isBlank()) {
            return "Podsetnik";
        }
        Hive hive = Hive.findByUuid(reminder.hiveUuid);
        if (hive == null) {
            return "Podsetnik";
        }
        String barcode = hive.barcode != null ? hive.barcode.trim() : "";
        Apiary apiary = hive.apiaryUuid != null ? Apiary.findByUuid(hive.apiaryUuid) : null;
        String name = apiary != null && apiary.name != null ? apiary.name.trim() : "";
        if (!name.isEmpty() && !barcode.isEmpty()) {
            return name + " - " + barcode;
        }
        if (!barcode.isEmpty()) {
            return barcode;
        }
        if (!name.isEmpty()) {
            return name;
        }
        return "Podsetnik";
    }

    @Transactional
    public void cancelRemote(Reminder reminder) {
        if (reminder == null || reminder.notificationId == null || reminder.notificationId.isBlank()) {
            return;
        }
        Optional<NotificationClient.NotificationDto> res = client.cancel(reminder.notificationId);
        res.ifPresent(this::markInvalidDevices);
        reminder.notificationId = null;
        reminder.persist();
    }

    @Transactional
    public void markInvalidDevices(NotificationClient.NotificationDto dto) {
        if (dto == null || dto.invalidDevices == null || dto.invalidDevices.isEmpty()) {
            return;
        }
        for (NotificationClient.InvalidDevice d : dto.invalidDevices) {
            if (d.externalUserId == null || d.externalUserId.isBlank()) {
                continue;
            }
            try {
                Long userId = Long.parseLong(d.externalUserId);
                User user = User.findById(userId);
                if (user != null) {
                    user.needsFcmRefresh = true;
                    user.persist();
                    LOG.infof("User %s označen za FCM refresh (invalid device %s)", userId, d.deviceId);
                }
            } catch (NumberFormatException ignored) {
                // ignore
            }
        }
    }

    public void markInvalidFromList(List<NotificationClient.InvalidDevice> devices) {
        if (devices == null) {
            return;
        }
        NotificationClient.NotificationDto wrap = new NotificationClient.NotificationDto();
        wrap.invalidDevices = devices;
        markInvalidDevices(wrap);
    }
}

package rs.pcelinjak.dto;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class SyncDtos {

    public static class SyncMeta {
        public String uuid;
        public Instant dateCreated;
        public Instant dateModified;
        public Instant dateSynched;
        public Instant dateDeleted;
    }

    public static class ApiaryItem extends SyncMeta {
        public String name;
        public String location;
        public int workNumber;
        public String color;
        public int sortOrder;
        public String officialId;
    }

    public static class HiveItem extends SyncMeta {
        public String barcode;
        public int orderNumber;
        public String hiveType;
        public String apiaryUuid;
        public String description;
        public String status;
    }

    public static class QueenItem extends SyncMeta {
        public String hiveUuid;
        public Integer queenYear;
        public boolean marked;
        public String origin;
        public Instant activeFrom;
        public Instant activeTo;
        public boolean active;
        public String endReason;
    }

    public static class NoteItem extends SyncMeta {
        public String hiveUuid;
        public String content;
        public String groupType;
        public String groupRecordUuid;
        public Instant reminderAt;
    }

    public static class HarvestItem extends SyncMeta {
        public String hiveUuid;
        public String pastureType;
        public double amountKg;
        public Instant collectedAt;
        public int harvestYear;
        public String workGroupHiveUuid;
    }

    public static class InspectionItem extends SyncMeta {
        public String hiveUuid;
        public Instant inspectedAt;
        public String summary;
        public String outcomeStatus;
        public String queenStatus;
        public String broodStatus;
        public String foodStatus;
        public String temperStatus;
        public String strengthStatus;
        public Instant followUpAt;
        public String sourceType;
        public String sourceGroupHiveUuid;
        public String sourceReminderUuid;
    }

    public static class WorkGroupItem extends SyncMeta {
        public String groupType;
        public String pastureType;
        public String locationName;
        public boolean finished;
    }

    public static class WorkGroupHiveItem extends SyncMeta {
        public String groupUuid;
        public String hiveUuid;
        public Double amount;
        public String note;
        public Instant checkDate;
        public Instant reminderAt;
        public String pastureType;
        public String locationName;
        public boolean done;
        public String membershipStatus;
        public Instant activeFrom;
        public Instant activeTo;
    }

    public static class ReminderItem extends SyncMeta {
        public String hiveUuid;
        public String groupHiveUuid;
        public String inspectionUuid;
        public Instant dueAt;
        public String title;
        public boolean completed;
    }

    public static class SyncResponse<T> {
        public List<T> items = new ArrayList<>();
    }

    public static class HiveCodeItem {
        public String barcode;
        public int orderNumber;
        public String hiveType;
        public String apiaryName;
        public int workNumber;
    }

    public static class HiveCodesResponse {
        public String ownerName;
        public String ownerEmail;
        public String ownerPhone;
        public List<HiveCodeItem> codes = new ArrayList<>();
    }
}

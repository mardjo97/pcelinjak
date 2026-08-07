class SyncRecord {
  final String uuid;
  DateTime dateCreated;
  DateTime dateModified;
  DateTime? dateSynched;
  DateTime? dateDeleted;

  SyncRecord({
    required this.uuid,
    DateTime? dateCreated,
    DateTime? dateModified,
    this.dateSynched,
    this.dateDeleted,
  }) : dateCreated = dateCreated ?? DateTime.now(),
       dateModified = dateModified ?? DateTime.now();

  void touch() => dateModified = DateTime.now();

  Map<String, dynamic> syncMeta() => {
    'uuid': uuid,
    'dateCreated': dateCreated.toUtc().toIso8601String(),
    'dateModified': dateModified.toUtc().toIso8601String(),
    'dateSynched': dateSynched?.toUtc().toIso8601String(),
    'dateDeleted': dateDeleted?.toUtc().toIso8601String(),
  };
}

class Apiary extends SyncRecord {
  String name;
  String? location;
  int workNumber;
  String color;
  int sortOrder;

  /// Zvanični ID broj pčelinjaka (Prilog 4).
  String? officialId;

  Apiary({
    required super.uuid,
    required this.name,
    this.location,
    required this.workNumber,
    required this.color,
    this.sortOrder = 0,
    this.officialId,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'name': name,
    'location': location,
    'workNumber': workNumber,
    'color': color,
    'sortOrder': sortOrder,
    'officialId': officialId,
  };

  factory Apiary.fromMap(Map<String, dynamic> m) => Apiary(
    uuid: m['uuid'] as String,
    name: m['name'] as String,
    location: m['location'] as String?,
    workNumber: m['workNumber'] as int,
    color: m['color'] as String,
    sortOrder: (m['sortOrder'] as int?) ?? 0,
    officialId: m['officialId'] as String?,
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

class Hive extends SyncRecord {
  String barcode;
  int orderNumber;
  String hiveType;
  String apiaryUuid;
  String? description;

  /// ACTIVE | ARCHIVED | DEAD
  String status;

  Hive({
    required super.uuid,
    required this.barcode,
    required this.orderNumber,
    required this.hiveType,
    required this.apiaryUuid,
    this.description,
    this.status = 'ACTIVE',
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'barcode': barcode,
    'orderNumber': orderNumber,
    'hiveType': hiveType,
    'apiaryUuid': apiaryUuid,
    'description': description,
    'status': status,
  };

  factory Hive.fromMap(Map<String, dynamic> m) => Hive(
    uuid: m['uuid'] as String,
    barcode: m['barcode'] as String,
    orderNumber: m['orderNumber'] as int,
    hiveType: m['hiveType'] as String,
    apiaryUuid: m['apiaryUuid'] as String,
    description: m['description'] as String?,
    status: (m['status'] as String?) ?? 'ACTIVE',
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

class Queen extends SyncRecord {
  String hiveUuid;
  int? queenYear;
  bool marked;
  String? origin;
  DateTime? activeFrom;
  DateTime? activeTo;
  bool active;

  /// DIED | REPLACED | SUPERSEDED | OTHER — razlog završetka
  String? endReason;

  Queen({
    required super.uuid,
    required this.hiveUuid,
    this.queenYear,
    this.marked = false,
    this.origin,
    this.activeFrom,
    this.activeTo,
    this.active = true,
    this.endReason,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  String get periodLabel {
    final from = (activeFrom ?? dateCreated)
        .toLocal()
        .toString()
        .split(' ')
        .first;
    if (activeTo == null) return 'Od $from';
    return '$from → ${activeTo!.toLocal().toString().split(' ').first}';
  }

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'queenYear': queenYear,
    'marked': marked ? 1 : 0,
    'origin': origin,
    'activeFrom': activeFrom?.toUtc().toIso8601String(),
    'activeTo': activeTo?.toUtc().toIso8601String(),
    'active': active ? 1 : 0,
    'endReason': endReason,
  };

  Map<String, dynamic> toJson() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'queenYear': queenYear,
    'marked': marked,
    'origin': origin,
    'activeFrom': activeFrom?.toUtc().toIso8601String(),
    'activeTo': activeTo?.toUtc().toIso8601String(),
    'active': active,
    'endReason': endReason,
  };

  factory Queen.fromMap(Map<String, dynamic> m) => Queen(
    uuid: m['uuid'] as String,
    hiveUuid: m['hiveUuid'] as String,
    queenYear: m['queenYear'] as int?,
    marked: (m['marked'] == true || m['marked'] == 1),
    origin: m['origin'] as String?,
    activeFrom: m['activeFrom'] != null
        ? DateTime.tryParse('${m['activeFrom']}')
        : null,
    activeTo: m['activeTo'] != null
        ? DateTime.tryParse('${m['activeTo']}')
        : null,
    active: m['active'] == null
        ? true
        : (m['active'] == true || m['active'] == 1),
    endReason: m['endReason'] as String?,
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

class HiveSearchHit {
  final Hive hive;
  final Apiary? apiary;
  final Queen? queen;

  const HiveSearchHit({required this.hive, this.apiary, this.queen});
}

const inspectionSourceTypes = {
  'MANUAL': 'Ručno',
  'CONTROL_GROUP': 'Grupa kontrole',
  'REMINDER': 'Podsetnik',
};

const inspectionOutcomeStatuses = {
  'OK': 'U redu',
  'FOLLOW_UP': 'Potrebna kontrola',
  'URGENT': 'Hitno',
  'RESOLVED': 'Rešeno',
};

const inspectionQueenStatuses = {
  'NOT_CHECKED': 'Nije provereno',
  'SEEN': 'Viđena',
  'NOT_SEEN': 'Nije viđena',
  'ISSUE': 'Problem',
};

const inspectionChecklistStatuses = {
  'NOT_CHECKED': 'Nije provereno',
  'GOOD': 'Dobro',
  'ATTENTION': 'Pažnja',
  'CRITICAL': 'Kritično',
};

const inspectionStrengthStatuses = {
  'NOT_CHECKED': 'Nije provereno',
  'WEAK': 'Slaba',
  'MEDIUM': 'Srednja',
  'STRONG': 'Jaka',
};

class Inspection extends SyncRecord {
  String hiveUuid;
  DateTime inspectedAt;
  String? summary;
  String outcomeStatus;
  String queenStatus;
  String broodStatus;
  String foodStatus;
  String temperStatus;
  String strengthStatus;
  DateTime? followUpAt;
  String? sourceType;
  String? sourceGroupHiveUuid;
  String? sourceReminderUuid;

  Inspection({
    required super.uuid,
    required this.hiveUuid,
    required this.inspectedAt,
    this.summary,
    this.outcomeStatus = 'OK',
    this.queenStatus = 'NOT_CHECKED',
    this.broodStatus = 'NOT_CHECKED',
    this.foodStatus = 'NOT_CHECKED',
    this.temperStatus = 'NOT_CHECKED',
    this.strengthStatus = 'NOT_CHECKED',
    this.followUpAt,
    this.sourceType,
    this.sourceGroupHiveUuid,
    this.sourceReminderUuid,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'inspectedAt': inspectedAt.toUtc().toIso8601String(),
    'summary': summary,
    'outcomeStatus': outcomeStatus,
    'queenStatus': queenStatus,
    'broodStatus': broodStatus,
    'foodStatus': foodStatus,
    'temperStatus': temperStatus,
    'strengthStatus': strengthStatus,
    'followUpAt': followUpAt?.toUtc().toIso8601String(),
    'sourceType': sourceType,
    'sourceGroupHiveUuid': sourceGroupHiveUuid,
    'sourceReminderUuid': sourceReminderUuid,
  };

  Map<String, dynamic> toJson() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'inspectedAt': inspectedAt.toUtc().toIso8601String(),
    'summary': summary,
    'outcomeStatus': outcomeStatus,
    'queenStatus': queenStatus,
    'broodStatus': broodStatus,
    'foodStatus': foodStatus,
    'temperStatus': temperStatus,
    'strengthStatus': strengthStatus,
    'followUpAt': followUpAt?.toUtc().toIso8601String(),
    'sourceType': sourceType,
    'sourceGroupHiveUuid': sourceGroupHiveUuid,
    'sourceReminderUuid': sourceReminderUuid,
  };

  factory Inspection.fromMap(Map<String, dynamic> m) => Inspection(
    uuid: m['uuid'] as String,
    hiveUuid: m['hiveUuid'] as String,
    inspectedAt: DateTime.tryParse('${m['inspectedAt']}') ?? DateTime.now(),
    summary: m['summary'] as String?,
    outcomeStatus: (m['outcomeStatus'] as String?) ?? 'OK',
    queenStatus: (m['queenStatus'] as String?) ?? 'NOT_CHECKED',
    broodStatus: (m['broodStatus'] as String?) ?? 'NOT_CHECKED',
    foodStatus: (m['foodStatus'] as String?) ?? 'NOT_CHECKED',
    temperStatus: (m['temperStatus'] as String?) ?? 'NOT_CHECKED',
    strengthStatus: (m['strengthStatus'] as String?) ?? 'NOT_CHECKED',
    followUpAt: m['followUpAt'] != null
        ? DateTime.tryParse('${m['followUpAt']}')
        : null,
    sourceType: m['sourceType'] as String?,
    sourceGroupHiveUuid: m['sourceGroupHiveUuid'] as String?,
    sourceReminderUuid: m['sourceReminderUuid'] as String?,
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

class Note extends SyncRecord {
  String hiveUuid;
  String content;
  String? groupType;
  String? groupRecordUuid;

  /// Opcioni lokalni/server podsetnik.
  DateTime? reminderAt;

  Note({
    required super.uuid,
    required this.hiveUuid,
    required this.content,
    this.groupType,
    this.groupRecordUuid,
    this.reminderAt,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'content': content,
    'groupType': groupType,
    'groupRecordUuid': groupRecordUuid,
    'reminderAt': reminderAt?.toUtc().toIso8601String(),
  };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
    uuid: m['uuid'] as String,
    hiveUuid: m['hiveUuid'] as String,
    content: m['content'] as String,
    groupType: m['groupType'] as String?,
    groupRecordUuid: m['groupRecordUuid'] as String?,
    reminderAt: m['reminderAt'] != null
        ? DateTime.tryParse('${m['reminderAt']}')
        : null,
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

class Harvest extends SyncRecord {
  String hiveUuid;
  String pastureType;
  double amountKg;
  DateTime? collectedAt;
  int harvestYear;

  /// Veza sa članstvom u grupi (MOVED / GOOD_PASTURE) — deljeni podaci.
  String? workGroupHiveUuid;

  Harvest({
    required super.uuid,
    required this.hiveUuid,
    required this.pastureType,
    required this.amountKg,
    this.collectedAt,
    required this.harvestYear,
    this.workGroupHiveUuid,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'pastureType': pastureType,
    'amountKg': amountKg,
    'collectedAt': collectedAt?.toUtc().toIso8601String(),
    'harvestYear': harvestYear,
    'workGroupHiveUuid': workGroupHiveUuid,
  };

  factory Harvest.fromMap(Map<String, dynamic> m) => Harvest(
    uuid: m['uuid'] as String,
    hiveUuid: m['hiveUuid'] as String,
    pastureType: m['pastureType'] as String,
    amountKg: (m['amountKg'] as num).toDouble(),
    collectedAt: m['collectedAt'] != null
        ? DateTime.tryParse('${m['collectedAt']}')
        : null,
    harvestYear: m['harvestYear'] as int,
    workGroupHiveUuid: m['workGroupHiveUuid'] as String?,
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

class WorkGroup extends SyncRecord {
  String groupType;
  String? pastureType;
  String? locationName;
  bool finished;

  WorkGroup({
    required super.uuid,
    required this.groupType,
    this.pastureType,
    this.locationName,
    this.finished = false,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'groupType': groupType,
    'pastureType': pastureType,
    'locationName': locationName,
    'finished': finished ? 1 : 0,
  };

  Map<String, dynamic> toJson() => {
    ...syncMeta(),
    'groupType': groupType,
    'pastureType': pastureType,
    'locationName': locationName,
    'finished': finished,
  };

  factory WorkGroup.fromMap(Map<String, dynamic> m) => WorkGroup(
    uuid: m['uuid'] as String,
    groupType: m['groupType'] as String,
    pastureType: m['pastureType'] as String?,
    locationName: m['locationName'] as String?,
    finished: m['finished'] == true || m['finished'] == 1,
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

class WorkGroupHive extends SyncRecord {
  String groupUuid;
  String hiveUuid;
  double? amount;
  String? note;
  DateTime? checkDate;
  DateTime? reminderAt;

  /// Po članstvu (npr. selidba) — paša / lokacija u tom periodu.
  String? pastureType;
  String? locationName;

  /// ACTIVE | FINISHED | REMOVED
  String membershipStatus;
  DateTime? activeFrom;
  DateTime? activeTo;

  WorkGroupHive({
    required super.uuid,
    required this.groupUuid,
    required this.hiveUuid,
    this.amount,
    this.note,
    this.checkDate,
    this.reminderAt,
    this.pastureType,
    this.locationName,
    this.membershipStatus = 'ACTIVE',
    this.activeFrom,
    this.activeTo,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  bool get isActive => membershipStatus == 'ACTIVE';
  bool get isFinished => membershipStatus == 'FINISHED';
  bool get isRemoved => membershipStatus == 'REMOVED';
  bool get done => !isActive;

  DateTime get joinedAt => activeFrom ?? dateCreated;

  String get periodLabel {
    final from = joinedAt.toLocal().toString().split(' ').first;
    if (activeTo == null) return 'Od $from';
    final to = activeTo!.toLocal().toString().split(' ').first;
    return '$from → $to';
  }

  String get statusLabel {
    switch (membershipStatus) {
      case 'FINISHED':
        return 'Završena';
      case 'REMOVED':
        return 'Uklonjena';
      default:
        return 'Aktivna';
    }
  }

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'groupUuid': groupUuid,
    'hiveUuid': hiveUuid,
    'amount': amount,
    'note': note,
    'checkDate': checkDate?.toUtc().toIso8601String(),
    'reminderAt': reminderAt?.toUtc().toIso8601String(),
    'pastureType': pastureType,
    'locationName': locationName,
    'done': done ? 1 : 0,
    'membershipStatus': membershipStatus,
    'activeFrom': joinedAt.toUtc().toIso8601String(),
    'activeTo': activeTo?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toJson() => {
    ...syncMeta(),
    'groupUuid': groupUuid,
    'hiveUuid': hiveUuid,
    'amount': amount,
    'note': note,
    'checkDate': checkDate?.toUtc().toIso8601String(),
    'reminderAt': reminderAt?.toUtc().toIso8601String(),
    'pastureType': pastureType,
    'locationName': locationName,
    'done': done,
    'membershipStatus': membershipStatus,
    'activeFrom': joinedAt.toUtc().toIso8601String(),
    'activeTo': activeTo?.toUtc().toIso8601String(),
  };

  factory WorkGroupHive.fromMap(Map<String, dynamic> m) {
    final doneFlag = m['done'] == true || m['done'] == 1;
    final status =
        (m['membershipStatus'] as String?) ??
        (doneFlag ? 'FINISHED' : 'ACTIVE');
    return WorkGroupHive(
      uuid: m['uuid'] as String,
      groupUuid: m['groupUuid'] as String,
      hiveUuid: m['hiveUuid'] as String,
      amount: m['amount'] == null ? null : (m['amount'] as num).toDouble(),
      note: m['note'] as String?,
      checkDate: m['checkDate'] != null
          ? DateTime.tryParse('${m['checkDate']}')
          : null,
      reminderAt: m['reminderAt'] != null
          ? DateTime.tryParse('${m['reminderAt']}')
          : null,
      pastureType: m['pastureType'] as String?,
      locationName: m['locationName'] as String?,
      membershipStatus: status,
      activeFrom: m['activeFrom'] != null
          ? DateTime.tryParse('${m['activeFrom']}')
          : DateTime.tryParse('${m['dateCreated']}'),
      activeTo: m['activeTo'] != null
          ? DateTime.tryParse('${m['activeTo']}')
          : null,
      dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
      dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
      dateSynched: m['dateSynched'] != null
          ? DateTime.tryParse('${m['dateSynched']}')
          : null,
      dateDeleted: m['dateDeleted'] != null
          ? DateTime.tryParse('${m['dateDeleted']}')
          : null,
    );
  }
}

class Reminder extends SyncRecord {
  String? hiveUuid;
  String? groupHiveUuid;
  String? inspectionUuid;
  DateTime dueAt;
  String title;
  bool completed;

  Reminder({
    required super.uuid,
    this.hiveUuid,
    this.groupHiveUuid,
    this.inspectionUuid,
    required this.dueAt,
    required this.title,
    this.completed = false,
    super.dateCreated,
    super.dateModified,
    super.dateSynched,
    super.dateDeleted,
  });

  Map<String, dynamic> toMap() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'groupHiveUuid': groupHiveUuid,
    'inspectionUuid': inspectionUuid,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'title': title,
    'completed': completed ? 1 : 0,
  };

  Map<String, dynamic> toJson() => {
    ...syncMeta(),
    'hiveUuid': hiveUuid,
    'groupHiveUuid': groupHiveUuid,
    'inspectionUuid': inspectionUuid,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'title': title,
    'completed': completed,
  };

  factory Reminder.fromMap(Map<String, dynamic> m) => Reminder(
    uuid: m['uuid'] as String,
    hiveUuid: m['hiveUuid'] as String?,
    groupHiveUuid: m['groupHiveUuid'] as String?,
    inspectionUuid: m['inspectionUuid'] as String?,
    dueAt: DateTime.tryParse('${m['dueAt']}') ?? DateTime.now(),
    title: m['title'] as String,
    completed: m['completed'] == true || m['completed'] == 1,
    dateCreated: DateTime.tryParse('${m['dateCreated']}') ?? DateTime.now(),
    dateModified: DateTime.tryParse('${m['dateModified']}') ?? DateTime.now(),
    dateSynched: m['dateSynched'] != null
        ? DateTime.tryParse('${m['dateSynched']}')
        : null,
    dateDeleted: m['dateDeleted'] != null
        ? DateTime.tryParse('${m['dateDeleted']}')
        : null,
  );
}

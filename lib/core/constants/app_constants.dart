enum QueueStatus {
  joined,
  waiting,
  approaching,
  called,
  serving,
  completed,
  cancelled,
  missed,
  waitlisted,
  expired;

  String get displayName {
    switch (this) {
      case QueueStatus.joined:
        return 'Joined';
      case QueueStatus.waiting:
        return 'Waiting';
      case QueueStatus.approaching:
        return 'Approaching Turn';
      case QueueStatus.called:
        return 'Called to Counter';
      case QueueStatus.serving:
        return 'In Service';
      case QueueStatus.completed:
        return 'Completed';
      case QueueStatus.cancelled:
        return 'Cancelled';
      case QueueStatus.missed:
        return 'Missed Call';
      case QueueStatus.waitlisted:
        return 'Waitlisted';
      case QueueStatus.expired:
        return 'Expired';
    }
  }

  bool get isActive {
    return this == QueueStatus.joined ||
        this == QueueStatus.waiting ||
        this == QueueStatus.approaching ||
        this == QueueStatus.called ||
        this == QueueStatus.serving;
  }
}

enum PriorityType {
  standard,
  senior,
  accessibility,
  emergency;

  String get displayName {
    switch (this) {
      case PriorityType.standard:
        return 'Standard';
      case PriorityType.senior:
        return 'Senior Citizen (60+)';
      case PriorityType.accessibility:
        return 'Special Assistance / Accessibility';
      case PriorityType.emergency:
        return 'Urgent / Priority Care';
    }
  }
}

enum QueueSource {
  mobileApp,
  qrCode,
  website,
  kiosk,
  receptionist;

  String get displayName {
    switch (this) {
      case QueueSource.mobileApp:
        return 'Easy Queue App';
      case QueueSource.qrCode:
        return 'QR Scan';
      case QueueSource.website:
        return 'Web Portal';
      case QueueSource.kiosk:
        return 'Self-service Kiosk';
      case QueueSource.receptionist:
        return 'Reception Desk';
    }
  }
}

enum BusinessCategory {
  all,
  hospital,
  diagnostic,
  bank,
  salon,
  restaurant,
  government,
  automotive,
  retail,
  events;

  String get displayName {
    switch (this) {
      case BusinessCategory.all:
        return 'All';
      case BusinessCategory.hospital:
        return 'Hospitals & Clinics';
      case BusinessCategory.diagnostic:
        return 'Diagnostics & Labs';
      case BusinessCategory.bank:
        return 'Banks & Finance';
      case BusinessCategory.salon:
        return 'Salons & Spas';
      case BusinessCategory.restaurant:
        return 'Restaurants & Cafes';
      case BusinessCategory.government:
        return 'Government Offices';
      case BusinessCategory.automotive:
        return 'Auto & Service';
      case BusinessCategory.retail:
        return 'Retail Stores';
      case BusinessCategory.events:
        return 'Events & Venues';
    }
  }

  String get iconName {
    switch (this) {
      case BusinessCategory.all:
        return 'grid_view';
      case BusinessCategory.hospital:
        return 'local_hospital';
      case BusinessCategory.diagnostic:
        return 'biotech';
      case BusinessCategory.bank:
        return 'account_balance';
      case BusinessCategory.salon:
        return 'content_cut';
      case BusinessCategory.restaurant:
        return 'restaurant';
      case BusinessCategory.government:
        return 'assured_workload';
      case BusinessCategory.automotive:
        return 'directions_car';
      case BusinessCategory.retail:
        return 'shopping_bag';
      case BusinessCategory.events:
        return 'event';
    }
  }
}

class AppConstants {
  static const String appName = 'Easy Queue';
  static const String appTagline = 'Skip the wait. Join the queue.';
  static const String packageId = 'in.mahato.easyqueue';

  /// Navigation padding to ensure content clears bottom navigation bars,
  /// floating action buttons, and system home indicators across all devices.
  static const double bottomNavPadding = 80.0;
  static const double navigationPadding = 80.0;

  // Local storage keys
  static const String keyUserId = 'eq_user_id';
  static const String keyIsGuest = 'eq_is_guest';
  static const String keyGuestToken = 'eq_guest_token';
  static const String keyLanguage = 'eq_language';
  static const String keyOnboarded = 'eq_onboarded';
}

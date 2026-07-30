/// Paths to the icons/images exported from the MediCarry Figma design.
///
/// The SVGs are the exact vectors from Figma; only their CSS `var(--fill-N,…)`
/// fills were resolved to the literal fallback colour so flutter_svg can parse
/// them. Tint at the call site with a `ColorFilter` where the design varies.
abstract final class AppAssets {
  AppAssets._();

  static const _icons = 'assets/icons';
  static const _images = 'assets/images';

  // Bottom navigation.
  static const navHome = '$_icons/nav_home.svg';
  static const navHistory = '$_icons/nav_history.svg';
  static const navScan = '$_icons/nav_scan.svg';
  static const navCards = '$_icons/nav_cards.svg';
  static const navProfile = '$_icons/nav_profile.svg';

  // Dashboard.
  static const search = '$_icons/search.svg';
  static const emergency = '$_icons/emergency.svg';
  static const medication = '$_icons/medication.svg';
  static const heart = '$_icons/heart.svg';
  static const trendDown = '$_icons/trend_down.svg';
  static const plus = '$_icons/plus.svg';
  static const chevronRight = '$_icons/chevron_right.svg';

  // Activity list.
  static const activityLab = '$_icons/activity_lab.svg';
  static const activityPrescription = '$_icons/activity_prescription.svg';
  static const activityCheckup = '$_icons/activity_checkup.svg';

  // Medical Records. The record cards' category icons and search glyph are the
  // activity/search assets above — verified identical path data, differing only
  // in fill — so they are tinted per card rather than duplicated.
  static const recordArrow = '$_icons/record_arrow.svg';
  static const calendar = '$_icons/calendar.svg';
  static const clock = '$_icons/clock.svg';
  static const fabAdd = '$_icons/fab_add.svg';

  // User Profile. The top-bar action is the shared `notifications` glyph —
  // verified byte-identical — so it is not duplicated here.
  static const profilePerson = '$_icons/profile_person.svg';
  static const profileInsurance = '$_icons/profile_insurance.svg';
  static const profileBell = '$_icons/profile_bell.svg';
  static const profileSecurity = '$_icons/profile_security.svg';
  static const profileChevron = '$_icons/profile_chevron.svg';
  static const profileEditBadge = '$_icons/profile_edit_badge.svg';
  static const profileLogout = '$_icons/profile_logout.svg';

  // Edit Profile. The full-name and dropdown glyphs are the shared
  // `profilePerson` / `dropdownChevron` assets — verified identical — so they
  // are not duplicated here.
  static const editBack = '$_icons/edit_back.svg';
  static const editCamera = '$_icons/edit_camera.svg';
  static const editCalendar = '$_icons/edit_calendar.svg';
  static const editBlood = '$_icons/edit_blood.svg';
  static const editGender = '$_icons/edit_gender.svg';
  static const editContact = '$_icons/edit_contact.svg';
  static const editPhone = '$_icons/edit_phone.svg';
  static const editCheck = '$_icons/edit_check.svg';

  // Record Details.
  static const detailBack = '$_icons/detail_back.svg';
  static const detailMore = '$_icons/detail_more.svg';
  static const detailAlert = '$_icons/detail_alert.svg';
  static const detailMetaDate = '$_icons/detail_meta_date.svg';
  static const detailMetaPlace = '$_icons/detail_meta_place.svg';
  static const detailClinical = '$_icons/detail_clinical.svg';
  static const detailEye = '$_icons/detail_eye.svg';
  static const detailNotes = '$_icons/detail_notes.svg';
  static const detailSigned = '$_icons/detail_signed.svg';
  static const detailShareRecord = '$_icons/detail_share_record.svg';
  static const detailPrint = '$_icons/detail_print.svg';

  /// Sample scans from the design. Placeholders — real attachments come from
  /// the patient's stored documents.
  static const attachment1 = '$_images/attachment_1.png';
  static const attachment2 = '$_images/attachment_2.png';

  // Share Records.
  static const notifications = '$_icons/notifications.svg';
  static const quickShareBadge = '$_icons/quick_share_badge.svg';
  static const showQr = '$_icons/show_qr.svg';
  static const exportHistory = '$_icons/export_history.svg';
  static const download = '$_icons/download.svg';
  static const settingsGear = '$_icons/settings_gear.svg';
  static const dropdownChevron = '$_icons/dropdown_chevron.svg';
  static const shieldLock = '$_icons/shield_lock.svg';
  static const sendLink = '$_icons/send_link.svg';
  static const hospital = '$_icons/hospital.svg';
  static const revoke = '$_icons/revoke.svg';

  /// The design's sample QR artwork. This is a STATIC placeholder — the real
  /// screen must render a QR generated from the patient's share payload so it
  /// works offline. See ShareRecordsScreen.
  static const qrPlaceholder = '$_icons/qr_placeholder.svg';

  /// Stand-in avatar. Replace with the patient's real photo once profile
  /// images are wired to the user's data.
  static const avatarPlaceholder = '$_images/avatar_placeholder.jpg';
}

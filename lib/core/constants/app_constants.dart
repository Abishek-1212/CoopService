class AppConstants {
  static const String appName = 'CoopService';
  static const String appTagline = 'Trusted Services. Stronger Communities.';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String cooperativesCollection = 'cooperatives';
  static const String servicesCollection = 'services';
  static const String categoriesCollection = 'categories';
  static const String cooperativeJoinRequestsCollection = 'cooperative_join_requests';
  static const String bookingsCollection = 'bookings';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleWorker = 'worker';
  static const String roleCooperativeHead = 'cooperative_head';
  static const String roleAdmin = 'admin';

  // Statuses
  static const String statusPending = 'pending';
  static const String statusVerified = 'verified';
  static const String statusRejected = 'rejected';
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  // Booking Statuses
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingInProgress = 'in_progress';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';

  // Worker Membership Statuses
  static const String membershipNotRequested = 'not_requested';
  static const String membershipPending = 'pending';
  static const String membershipApproved = 'approved';
  static const String membershipRejected = 'rejected';
  static const String membershipMoreInfoRequired = 'more_information_required';

  // Identity Proof Types
  static const List<String> identityDocumentTypes = [
    'Aadhaar',
    'Voter ID',
    'Driving Licence',
    'Passport',
    'Other Government ID',
  ];

  // Common Districts in Tamil Nadu (for quick selection)
  static const List<String> popularDistricts = [
    'Coimbatore',
    'Chennai',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
    'Erode',
    'Tiruppur',
    'Dindigul',
    'Thanjavur',
    'Vellore',
    'Kanchipuram',
    'Cuddalore',
    'Villupuram',
    'Tirunelveli',
    'Kanyakumari',
    'Namakkal',
    'Karur',
    'Theni',
    'Virudhunagar',
    'Sivaganga',
    'Ramanathapuram',
    'Nagapattinam',
    'Tiruvarur',
    'Pudukkottai',
    'Perambalur',
    'Ariyalur',
    'Dharmapuri',
    'Krishnagiri',
    'Tiruvannamalai',
    'Ranipet',
    'Tirupattur',
    'Chengalpattu',
    'Tenkasi',
    'Kallakurichi',
    'Mayiladuthurai',
    'Nilgiris',
  ];

  // Service Category High-Level Classifications
  static const List<String> serviceCategories = [
    'Home Maintenance & Repair',
    'Electrical & Utilities',
    'Plumbing & Sanitation',
    'Cleaning & Housekeeping',
    'Painting & Renovation',
    'Gardening & Outdoor',
    'Logistics & Transport',
    'Personal & Caregiving',
    'Appliance & Tech Support',
    'Security & Protection',
    'Construction & Masonry',
    'General Services',
  ];
}

# Implementation Plan — Worker Verification + Cooperative Society Joining Flow

This plan implements the complete end-to-end worker onboarding, identity & skill verification, dynamic cooperative society matching, join request workflow, cooperative head review & approval/rejection/info-request dashboard, role access guards, and security rules.

## User Review Required

> [!IMPORTANT]
> - **Existing Users Migration**: Workers created previously without `membershipStatus` or `primaryServiceId` will be routed to the new onboarding flow to complete their profile and select a cooperative society.
> - **Storage Rules & Firestore Security**: Production security rules will enforce that identity and skill documents in `workers/{workerId}/...` and requests in `cooperative_join_requests` are accessible only to the worker, assigned Cooperative Head, and Admins.

## Open Questions

None. All requirements, document schemas, status values, and access controls are fully specified in the master prompt.

---

## Proposed Changes

### Models & Core Constants

#### [MODIFY] [app_constants.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/core/constants/app_constants.dart)
- Add constants for `cooperativeJoinRequestsCollection = 'cooperative_join_requests'`.
- Add membership statuses: `membershipNotRequested`, `membershipPending`, `membershipApproved`, `membershipRejected`, `membershipMoreInfoRequired`.
- Add identity proof types: `Aadhaar`, `Voter ID`, `Driving Licence`, `Passport`, `Other Government ID`.

#### [MODIFY] [user_model.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/models/user_model.dart)
- Extend `AppUser` model with onboarding and verification fields:
  - `fullAddress`, `state`, `district`, `city`, `pincode`
  - `primaryServiceId`, `secondaryServiceIds`
  - `yearsOfExperience`, `bio`, `previousWorkExperience`, `languagesKnown`
  - `identityType`, `identityDocumentUrl`, `addressProofUrl`, `profilePhotoUrl`
  - `skillCertificateUrls`, `experienceCertificateUrls`, `otherDocumentUrls`
  - `membershipStatus`, `availableForJobs`

#### [NEW] [cooperative_join_request_model.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/models/cooperative_join_request_model.dart)
- Create data model for `cooperative_join_requests/{requestId}`:
  - `requestId`, `workerId`, `cooperativeId`, `cooperativeHeadId`
  - Worker contact info (`workerName`, `workerEmail`, `workerPhone`)
  - Location details (`workerState`, `workerDistrict`, `workerCity`, `workerPincode`)
  - Services (`primaryServiceId`, `secondaryServiceIds`)
  - Document URLs (`profilePhotoUrl`, `identityType`, `identityDocumentUrl`, `addressProofUrl`, `skillCertificateUrls`, `experienceCertificateUrls`, `otherDocumentUrls`)
  - Status fields (`status`, `submittedAt`, `reviewedAt`, `reviewedBy`, `rejectionReason`, `requestedInfoMessage`)

---

### Services & Logic Layer

#### [NEW] [worker_verification_service.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/services/worker_verification_service.dart)
- Implement `WorkerVerificationService`:
  - `streamSuitableCooperatives(String serviceId, String location/district)`: Loads active cooperatives offering `serviceId` matching location.
  - `submitWorkerJoinRequest(...)`: Creates Firestore document in `cooperative_join_requests` and updates worker `membershipStatus` to `pending`.
  - `streamJoinRequestsForCooperative(String coopId)`: Streams requests filtered by cooperative ID for Cooperative Head dashboard.
  - `streamWorkerJoinRequest(String workerId)`: Streams active join request for the worker.
  - `approveWorkerRequest(...)`: Updates request to `approved`, updates user profile (`cooperativeId`, `membershipStatus = 'approved'`, `verificationStatus = 'verified'`, `availableForJobs = true`), and creates worker entry in `cooperatives/{cooperativeId}/workers/{workerId}`.
  - `rejectWorkerRequest(...)`: Updates request to `rejected` with rejection reason, updates user `membershipStatus = 'rejected'`.
  - `requestMoreInfo(...)`: Updates request to `more_information_required` with message, updates user `membershipStatus = 'more_information_required'`.
  - `resubmitWorkerRequest(...)`: Resubmits request with updated documents and resets status to `pending`.

#### [MODIFY] [storage_service.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/services/storage_service.dart)
- Add secure upload methods for worker files:
  - `uploadWorkerProfilePhoto(workerId, file/bytes)` -> `workers/{workerId}/profile/profile.jpg`
  - `uploadWorkerIdentityDocument(workerId, docType, file/bytes)` -> `workers/{workerId}/identity/{docType}.jpg`
  - `uploadWorkerSkillCertificate(workerId, certName, file/bytes)` -> `workers/{workerId}/certificates/{certName}.pdf`

---

### Worker Onboarding & Verification UI

#### [NEW] [worker_onboarding_screen.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/screens/worker/onboarding/worker_onboarding_screen.dart)
- Multi-step onboarding stepper:
  - **Step 1 — Profile Details**: Name, Phone, Email (disabled), Full Address, State, District, City, Pincode, Primary Service (dropdown dynamically loaded from active services in `services` collection), Years of Experience, Optional Bio/Languages.
  - **Step 2 — Proof of Identity & Certificates**:
    - Identity Type selector (Aadhaar, Voter ID, Driving Licence, etc.)
    - File pickers for Govt ID, Address Proof, Profile Photo.
    - Skill / Trade certificate upload. Conditional requirement: Driving Licence required if service is "Driver".
  - **Step 3 — Cooperative Selection & Confirmation**:
    - Query and display suitable active cooperatives offering the selected `primaryServiceId` matching location.
    - Rich Cooperative Card displaying logo, name, reg number, services offered, operating area, city/district, head status.
    - "Request to Join" button with confirmation dialog.

#### [NEW] [worker_pending_verification_screen.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/screens/worker/onboarding/worker_pending_verification_screen.dart)
- Displays current verification & membership status:
  - Header with Status Chip (Pending Approval: Amber / Rejected: Red / More Info Required: Blue).
  - Summary card with Cooperative Name, Primary Service, Submitted Date.
  - Informational message on status and access restrictions.
  - If status is `rejected`: displays Rejection Reason with "Edit & Resubmit" button.
  - If status is `more_information_required`: displays requested message from Cooperative Head with "Upload Document & Resubmit" button.
  - Read-only tab to view submitted profile & documents.

---

### Cooperative Head Management UI

#### [NEW] [cooperative_worker_requests_tab.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/screens/cooperative/worker_requests/cooperative_worker_requests_tab.dart)
- Tabbed interface (`Pending`, `Approved`, `Rejected`) for Cooperative Head to review join requests for their cooperative.
- Request Cards showing Profile Photo, Worker Name, Phone, Email, Primary Service Name, Experience, Location, Submitted Date.
- Action Buttons: `View Details`, `Approve`, `Reject`.

#### [NEW] [worker_request_detail_screen.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/screens/cooperative/worker_requests/worker_request_detail_screen.dart)
- Comprehensive detail page for Cooperative Head:
  - **WORKER PROFILE**: Full name, contact, address, experience, primary service, secondary services.
  - **IDENTITY DOCUMENTS**: Government ID type, preview link for Govt ID, Address Proof, Profile Photo.
  - **SKILL DOCUMENTS**: Preview links for skill certificates, experience certs, driving licence, etc.
  - **COOPERATIVE REQUEST**: Submitted date, current status.
  - **Action Dialogs**:
    - `Approve Worker` (Confirmation dialog)
    - `Reject Request` (Rejection reason picker + custom notes)
    - `Request More Information` (Text input dialog for custom message)

#### [MODIFY] [cooperative_dashboard.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/screens/cooperative/cooperative_dashboard.dart)
- Replace static Workers tab with `CooperativeWorkerRequestsTab` so Cooperative Head can review pending worker requests for their society.

---

### Navigation & Security Rules

#### [MODIFY] [auth_wrapper.dart](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/lib/screens/auth/auth_wrapper.dart)
- Update role routing for `roleWorker`:
  - `membershipStatus == 'approved'` && `verificationStatus == 'verified'` -> `WorkerDashboard()`
  - `membershipStatus == 'pending'` || `'more_information_required'` || `'rejected'` -> `WorkerPendingVerificationScreen()`
  - Otherwise -> `WorkerOnboardingScreen()`

#### [NEW] [firestore.rules](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/firestore.rules) & [storage.rules](file:///c:/Users/abish/OneDrive/Desktop/Gigs/coop_service/storage.rules)
- Security rules enforcing strict role-based access to `cooperative_join_requests` and `workers/{workerId}/...` storage bucket.

---

## Verification Plan

### Automated Tests
- Static code analysis (`flutter analyze`) to ensure zero syntax or type warnings.

### Manual Verification
1. **Worker Onboarding & Selection**:
   - Register a new Worker account.
   - Verify redirection to `WorkerOnboardingScreen`.
   - Verify dynamic loading of active services from Firestore `services` collection.
   - Complete profile, upload identity/skill documents.
   - Verify matching cooperatives list displayed based on primary service ID and location.
   - Send Join Request and confirm request document created in `cooperative_join_requests`.
2. **Pending & Access Guard**:
   - Verify worker is redirected to `WorkerPendingVerificationScreen`.
   - Verify worker cannot navigate to `WorkerDashboard` / jobs while pending.
3. **Cooperative Head Approval**:
   - Log in as Cooperative Head.
   - Navigate to Worker Requests tab and open pending request.
   - Inspect identity and skill documents.
   - Approve worker -> Verify `users/{workerId}` updated (`membershipStatus = 'approved'`, `verificationStatus = 'verified'`, `availableForJobs = true`), request status `approved`.
4. **Worker Dashboard Access**:
   - Log in as worker -> Verify immediate access to full `WorkerDashboard`.
5. **Rejection & Info Request Flow**:
   - Test Rejection with reason -> verify worker sees rejection reason and can resubmit.
   - Test Request More Info -> verify worker sees prompt message and can upload updated documents.

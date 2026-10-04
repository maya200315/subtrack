# SubTrack — Personal Subscription & Spending Tracker

A Flutter application for managing recurring subscriptions, monitoring monthly spending, tracking renewal dates, and staying within a personal budget — built with a clean, testable architecture, multi-currency support, and secure per-user data isolation.

> Answers three simple questions: **How much am I paying? On what? And when does it renew?**

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Design Patterns](#design-patterns)
- [Data Model](#data-model)
- [Security](#security)
- [Non-Functional Requirements](#non-functional-requirements)
- [Testing](#testing)
- [Engineering Decisions & Trade-offs](#engineering-decisions--trade-offs)
- [Getting Started](#getting-started)
- [Roadmap](#roadmap)

---

## Overview

SubTrack helps users keep track of recurring subscriptions , understand their monthly spending at a glance, and stay within a self-defined budget — across multiple currencies. The project was built with production-grade practices in mind: a layered architecture, clear separation between business logic and framework code, automated tests for the logic that actually carries risk, and security enforced at the database level rather than trusted to the client alone.

---
## Screenshots
<img width="451" height="835" alt="login-register" src="https://github.com/user-attachments/assets/4e4fc8cf-4107-40ae-b188-1996872f3dc5" />
<img width="427" height="826" alt="splash" src="https://github.com/user-attachments/assets/04845363-a1ca-4281-a218-12d2aec2d669" />
<img width="465" height="838" alt="Screenshot (1005)" src="https://github.com/user-attachments/assets/c5f94611-ac03-4eb9-8b00-5bf5e3833526" />
<img width="433" height="832" alt="Screenshot (997)" src="https://github.com/user-attachments/assets/1e9b5340-46f8-4a06-aa25-4232fb25fd96" />
<img width="451" height="836" alt="Screenshot (999)" src="https://github.com/user-attachments/assets/fdcfb46b-de70-4fff-a542-d65d048d53f7" />
<img width="438" height="835" alt="Edit" src="https://github.com/user-attachments/assets/12f0ce54-df6c-48c4-b1d6-ae3beba36ff7" />
<img width="448" height="846" alt="add-arabic" src="https://github.com/user-attachments/assets/3596b945-809e-4609-b0c5-70947a2fc2c3" />

## Features

- **Authentication** — sign up and log in with email/password, with email verification required before accessing the app, and a logout option available at any time
- **Subscription management** — add, edit, and delete subscriptions (monthly or yearly billing)
- **Upcoming renewals** — see which subscriptions are renewing soonest, with days remaining
- **Spending breakdown** — pie chart visualizing spend by category (Entertainment / Productivity / Other)
- **Monthly budget tracking** — set a monthly budget and see real-time usage with a color-coded progress bar (normal / warning / exceeded)
- **Multi-currency support** — subscriptions can be tracked and converted between USD, EUR, TRY, and SYP; all values are converted to the budget's currency for accurate totals
- **Per-user data isolation** — each user only ever sees their own subscriptions, enforced both in the app logic and at the database level via Firestore Security Rules
- **Bilingual UI** — full Arabic/English support with a single toggle that switches the entire app at once (no mixed-language screens)
- **Personalized greeting** — a time-aware "Good morning / Good evening" greeting using the logged-in user's name
- **Real-time sync** — powered by Cloud Firestore streams, so the UI updates instantly on any change
- **Light, custom theme** — a warm, cohesive color palette applied consistently across the app instead of Flutter's default styling

---

## Tech Stack

| Layer | Technology | Reasoning |
|---|---|---|
| Framework | Flutter | Single codebase, native performance |
| State Management | Riverpod | Compile-safe, testable, scales better than scattered `setState` across layers |
| Backend / Database | Firebase (Cloud Firestore) | Real-time sync out of the box; NoSQL model avoided the need for a relational schema for a dataset this shape |
| Authentication | Firebase Authentication | Managed auth with built-in email verification, avoids hand-rolling password storage/hashing |
| Local Storage | shared_preferences | Lightweight, appropriate for a single scalar value (budget settings) — no need for a full local database |
| Localization | easy_localization | Key-based translations, avoids hardcoded strings scattered across widgets |
| Charts | fl_chart | Native Flutter charting, no platform-specific dependencies |
| Currency Conversion | Frankfurter API | Free, no API key required, sufficient accuracy for personal budgeting (not financial-grade trading) |
| Testing | flutter_test 

---

## Architecture

The project follows **Clean Architecture**, separating the codebase into three layers with a strict dependency direction: `presentation` depends on `domain`, `data` depends on `domain`, but `domain` depends on nothing.

```
lib/
├── core/                  # Shared utilities (app theme, colors)
├── domain/                # Framework-independent business logic
│   ├── entities/          # Subscription (pure Dart object, no Firebase/Flutter imports)
│   ├── repositories/      # Abstract contracts (interfaces) — define WHAT, not HOW
│   ├── strategies/        # CurrencyConversionStrategy contract
│   └── usecases/          # CalculateBudgetUsage — single-responsibility business logic
├── data/                  # Implementation details
│   ├── models/            # SubscriptionModel (Firestore <-> Entity mapping)
│   ├── repositories/      # SubscriptionRepositoryImpl, AuthRepositoryImpl (Firebase)
│   └── strategies/        # FrankfurterConversionStrategy (API implementation)
└── presentation/          # UI layer
    ├── providers/         # Riverpod providers (wiring between layers)
    └── screens/           # HomeScreen, AddSubscriptionScreen, AuthScreen, EmailVerificationScreen

---

## Design Patterns

Patterns were applied where they solved a concrete problem in this codebase — not added for their own sake.

| Pattern | Where | Problem it solves |
|---|---|---|
| **Repository** | `SubscriptionRepository` / `AuthRepository` (contracts) → `SubscriptionRepositoryImpl` / `AuthRepositoryImpl` (Firebase) | Without it, Firestore calls would be scattered across UI widgets and use cases, making the code hard to test and hard to change. With it, the UI and business logic depend only on an abstract contract, never on Firebase directly. |
| **Strategy** | `CurrencyConversionStrategy` (contract) → `FrankfurterConversionStrategy` (implementation) | The budget calculation needs to convert between currencies, but shouldn't need to know *how* — whether that's via a live API, a cached rate, or a fake value in a test. The Strategy pattern lets `CalculateBudgetUsage` stay oblivious to that detail, and made it possible to unit-test the budget logic using a fake, deterministic conversion strategy instead of hitting a real API in every test run. |
---

## Data Model

Each subscription document in Firestore has the following shape:

| Field | Type | Notes |
|---|---|---|
| `userId` | `String` | Owner's Firebase Auth UID — the basis for all access control |
| `name` | `String` | e.g. "Netflix" |
| `price` | `double` | Stored in the subscription's own currency |
| `currency` | `String` | ISO-style code: `USD`, `EUR`, `TRY`, `SYP` |
| `billingCycle` | `String` | `monthly` or `yearly` |
| `category` | `String` | `entertainment`, `productivity`, or `other` |
| `nextBillingDate` | `Timestamp` | Used for the "Upcoming" list and days-remaining calculation |
| `note` | `String?` | Optional, nullable |
| `createdAt` | `Timestamp` | Record creation time |

Yearly subscriptions are normalized to a monthly-equivalent value (`price / 12`) wherever they're aggregated — in both the budget calculation and the category breakdown chart — so a $120/year and a $10/month subscription contribute comparably to the totals.

---

## Security

- **Authentication-gated access** — the app routes unauthenticated users to a login/signup screen, and unverified users to an email-verification screen, before they can reach the main app. This is enforced in the widget tree itself (`AuthGate`), not just assumed.
- **Firestore Security Rules** enforce per-user data isolation at the database level, independent of the client app — meaning the protection holds even if the Flutter app were bypassed entirely and someone queried Firestore directly:

rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {
match /subscriptions/{subscriptionId} {
allow read, update, delete: if request.auth != null
&& resource.data.userId == request.auth.uid;
allow create: if request.auth != null
&& request.resource.data.userId == request.auth.uid;
}
}
}


This means a read, write, or delete request is rejected unless the requester is authenticated **and** the document's `userId` matches their own UID. Email verification is currently enforced at the UI level only (via `AuthGate` routing) — it is not yet reflected in the Firestore Rules themselves, since doing so requires forcing an ID token refresh after verification, which is listed as a known follow-up 
---

## Non-Functional Requirements

| Requirement | How it's addressed |
|---|---|
| **Security** | Firestore Security Rules scoped by `userId` + `email_verified`; no client-side-only access control |
| **Maintainability** | Clean Architecture layering keeps business logic, data access, and UI independently modifiable |
| **Testability** | Repository and Strategy contracts allow business logic to be unit-tested in isolation, without a live Firebase connection |
| **Reliability** | Network operations (Firestore writes, currency API calls) are wrapped with timeouts and explicit error handling instead of failing silently or hanging indefinitely |
| **Usability** | Bilingual interface with a single-tap language switch, consistent color system, clear empty/loading/error states |
| **Scalability (codebase)** | The `domain` layer's independence from Firebase means swapping or adding a data source does not require restructuring the app |

---

## Testing

Unit tests cover the core business logic — the parts of the app where a silent bug would actually produce wrong numbers for the user — with both happy paths and edge cases:

- **`calculate_budget_usage_test.dart`** — verifies budget percentage, status thresholds (normal/warning/exceeded), and monthly-equivalent conversion for yearly subscriptions, using a fake currency strategy so the test is deterministic and network-independent
- **`subscription_model_test.dart`** — verifies Firestore serialization/deserialization (`fromMap`/`toMap`), including null notes, integer-vs-double price handling, and round-trip data integrity

Run all tests:
```bash
flutter test
```

---

## Engineering Decisions & Trade-offs

A few deliberate choices worth calling out, since the reasoning behind them matters as much as the code:

- **SYP exchange rate is a manually configured approximation** — no free, reliable exchange-rate API currently supports the Syrian Pound. Rather than silently omitting the currency or blocking on an unavailable integration, a documented manual fallback rate is used, with the trade-off made explicit here rather than hidden in the code.
- **Riverpod over Provider** — chosen for compile-time safety and to avoid the common runtime "provider not found" class of errors, at the cost of a slightly steeper initial learning curve.

---

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/<your-username>/subtrack.git
   cd subtrack
   ```
2. Install dependencies
   ```bash
   flutter pub get
   ```
3. Connect your own Firebase project
   ```bash
   flutterfire configure
   ```
4. In the Firebase Console: enable Email/Password authentication, create a Cloud Firestore database, and publish the security rules shown above.
5. Run the app
   ```bash
   flutter run
   ```

---

## Roadmap

Potential next steps, in rough priority order:

- [ ] Google Sign-In as an additional authentication option, alongside email/password
- [ ] Push notifications ahead of upcoming renewal dates
- [ ] Dark mode, extending the existing theme system

---

## License

This project was built as a personal portfolio project to demonstrate Flutter, clean architecture, state management, and secure backend integration skills.

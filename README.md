# Ascended Athletics — Customer M-Commerce App

Dark, minimal, athletic Flutter mobile application for martial arts and
combat-sports apparel. Academic M-Commerce project built on **Flutter + Dart**
with a **Firebase** backend, **Riverpod** state management, and **GoRouter**
navigation.

Reference documents: `ascended_athletics_blueprint.md` (system blueprint) and
`ite_7_module.md` (module requirements).

---

## Features

| Module | Capabilities |
| :--- | :--- |
| **Auth (Entry)** | Login, Register (Name/Email/Password), Forgot Password, **Guest entry** to Home/Shop browsing |
| **Home** | Promotional banner, shop-by-discipline tiles, featured products, new arrivals, search & cart shortcuts |
| **Shop** | Product grid from Firestore `products`, live search, discipline + product-type filters, sort (Newest / Price ↑↓ / Name A–Z) |
| **Product Details** | Image gallery, price, description, discipline tags, dynamic variations (size/color), stock check, quantity, wishlist, Add to Cart |
| **Wishlist** | Save/remove products (login-gated), empty state with Shop shortcut |
| **Cart** | Quantity stepper, remove item, subtotal, simulated shipping fee, totals |
| **Checkout** | Guest → forced login that **returns to checkout** (form preserved), shipping form, order summary, simulated **COD / GCash** |
| **Order Logic** | Firestore **transaction**: validate authoritative price/stock → create `orders/{id}` → deduct variant stock → clear purchased cart items |
| **Profile** | View/edit personal info, change password, order history, order details, **cancel pending order** (restores stock exactly once), logout |

Navigation: five-item bottom bar — **Home | Shop | Wishlist | Cart | Profile**
(hidden on focused flows like Checkout and Order Confirmation).

---

## UI Design Tokens

| Token | Hex | Use |
| :--- | :--- | :--- |
| Primary background | `#0B0B0F` | Near-black screens |
| Secondary surfaces | `#17171F` | Charcoal cards/panels |
| Primary accent | `#8B5CF6` | Electric purple actions/active states |
| Deep accent | `#6D28D9` | Gradient emphasis |
| Primary text | `#FFFFFF` | White |
| Secondary text | `#A1A1AA` | Muted gray |
| Borders | `#27272A` | Subtle dividers |
| Success / Error | `#22C55E` / `#EF4444` | Feedback states |

Typography: **Inter** (via `google_fonts`).

---

## Folder Structure

```text
lib/
├── core/
│   ├── constants/       # app_colors, app_constants (disciplines, types, fees)
│   ├── router/          # app_router (GoRouter: shells + focused routes)
│   └── theme/           # app_theme (dark ThemeData)
├── models/              # user, product (+variants), cart_item, order models
├── services/            # auth, firestore, cart (persistence), order (transactions)
├── providers/           # Riverpod: auth, products/shop filters, cart, wishlist, orders
└── features/
    ├── navigation/      # MainScaffold (5-tab bottom nav)
    ├── auth/            # splash, login, register
    ├── home/            # home screen, promo banner, section headers
    ├── products/        # shop (grid/search/filter/sort), product details, product card
    ├── wishlist/        # wishlist screen
    ├── cart/            # cart screen
    ├── checkout/        # checkout + order confirmation
    └── profile/         # profile, edit profile, order history, order details
```

---

## Firestore Data Model

```text
users/{uid}                 fullName, email, phone, role, createdAt
products/{productId}        name, description, price, categoryId,
                            disciplines[], images[], isActive, createdAt
products/{productId}/variants[] (embedded list)
                            size, color, stock  (per-variant inventory)
carts/{uid}/items/{itemId}  authenticated cart persistence (guest = local)
orders/{orderId}            customerId, items[] (snapshots), shippingAddress,
                            subtotal, shippingFee, total, paymentMethod,
                            orderStatus, createdAt, updatedAt
notifications/{id}          userId, title, body, type, read, orderId, createdAt
```

`orderStatus` is one of `Pending`, `Processing`, `Shipped`, `Completed`, or
`Cancelled`. The legacy `status` field is mirrored on every write for older
reports/dashboards, but new code should read `orderStatus`.

Order lifecycle: `Pending → Processing → Shipped → Completed` and
`Pending → Cancelled` (admin dashboard handles transitions; customer may cancel
**Pending** only). The customer app keeps a live Firestore listener on its
orders, shows an in-app alert when the admin changes a status, and stores an
unread `notifications/{id}` record that can be opened from Notifications.
Payment is **simulated** (informational field only — no gateway).

---

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase (required for live data)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This replaces the placeholder `lib/firebase_options.dart` and installs
`google-services.json` (Android) / `GoogleService-Info.plist` (iOS).

In the **Firebase Console**:

1. Enable **Authentication → Email/Password**.
2. Create a **Cloud Firestore** database (production mode).
3. (Optional) Seed sample products into `products` with the structure above,
   e.g.:

```json
{
  "name": "Ascend Rash Guard",
  "description": "Compression fit, moisture-wicking.",
  "price": 1299.0,
  "categoryId": "Tops",
  "disciplines": ["MMA", "BJJ"],
  "images": ["https://.../rashguard.jpg"],
  "isActive": true,
  "createdAt": "2026-10-27T08:00:00Z",
  "variants": [
    { "size": "M", "color": "Black", "stock": 12 },
    { "size": "L", "color": "Black", "stock": 8 }
  ]
}
```

### 3. Suggested Firestore security rules (academic baseline)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }

    match /users/{uid} {
      allow read: if isSignedIn() && request.auth.uid == uid;
      allow create, update: if isSignedIn() && request.auth.uid == uid;
    }

    match /products/{productId} {
      allow read: if true;            // public catalog
      allow write: if false;          // admin only (dashboard/backend)
    }

    match /carts/{uid}/{doc=**} {
      allow read, write: if isSignedIn() && request.auth.uid == uid;
    }

    match /orders/{orderId} {
      allow read: if isSignedIn() &&
        (resource.data.customerId == request.auth.uid);
      allow create: if isSignedIn() &&
        request.resource.data.customerId == request.auth.uid;
      // Status changes happen through the client transaction today;
      // move cancellation/status updates to Cloud Functions or restrict
      // here for stronger guarantees in a production build.
      allow update: if isSignedIn() &&
        resource.data.customerId == request.auth.uid &&
        request.resource.data.status == 'Cancelled' &&
        resource.data.status == 'Pending';
    }
  }
}
```

> Note: for the strongest stock/order atomicity guarantee, mirror
> `services/order_service.dart`'s transactions in Cloud Functions — client
> transactions already serialize correctly, but trusted server-side writes
> remove the need for permissive client write rules.

### 4. Run

```bash
flutter run
```

---

## Key Flows

* **Guest browsing** → Home/Shop/Details work signed-out; Wishlist requires
  login; Checkout forces login (`/login?redirect=checkout`) and **returns to
  the checkout form** with the cart merged after auth.
* **Place order** → `OrderService.placeOrder()` runs a single Firestore
  transaction: price + stock validated → variant stock deducted → order
  document written → purchased cart items cleared.
* **Cancel pending order** → `OrderService.cancelOrder()` re-checks
  `status == 'Pending'` inside a transaction (duplicate submissions fail
  safely) and restores stock exactly once.

## Build & Test

```bash
flutter analyze   # lint (clean)
flutter test      # widget tests
flutter build apk # release APK for submission
```

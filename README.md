# Estimate Pro - Flutter App

Complete construction estimate management app with authentication, orders management, and estimate generation.

## 🚀 Features

- ✅ **OTP Authentication** - Email-based OTP login
- ✅ **Auto Login** - Token stored locally, auto login on app restart
- ✅ **My Orders** - View, Update, Delete orders
- ✅ **Generate Estimate** - Create new estimates with userId in header
- ✅ **Beautiful UI** - Modern Material Design 3
- ✅ **Complete CRUD** - All API operations implemented

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── services/
│   ├── token_service.dart       # Token management (save/get/check)
│   └── api_helper.dart          # All API calls
└── screens/
    ├── splash_screen.dart       # Token check & auto navigation
    ├── login_screen.dart        # Email input & send OTP
    ├── otp_screen.dart          # OTP verification
    ├── home_screen.dart         # Dashboard with actions
    ├── my_orders_screen.dart    # Orders list with CRUD
    └── estimate_screen.dart     # Generate estimate form
```

---

## 🛠️ Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

---

## 🔥 Key Features Explained

### 1️⃣ **Auto Login with Token**

```dart
// App start pe token check hota hai
// Splash Screen:
bool isLoggedIn = await TokenService.isLoggedIn();

if (isLoggedIn) {
  // Token hai → Home Screen
} else {
  // Token nahi → Login Screen
}
```

### 2️⃣ **OTP Verification & Token Save**

```dart
// OTP verify karo
final response = await ApiHelper.verifyOtp(email, otp);

// Token automatically save ho gaya! ✅
// Response:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "6933d21edf36a3f5bbb7b965",
    "email": "anujgupta596@gmail.com",
    "isVerified": true
  }
}
```

### 3️⃣ **Get User Orders**

```dart
// userId automatically use hoti hai
List<dynamic> orders = await ApiHelper.getUserOrders();

// Response:
[
  {
    "_id": "6986f229d17bb757074fc147",
    "customerId": {...},
    "requestType": "ESTIMATE",
    "payment": {
      "amount": 300,
      "currency": "INR"
    },
    "status": "PENDING",
    ...
  }
]
```

### 4️⃣ **Update Order**

```dart
final updatedData = {
  'customerId': '69208f06b1f585a66f3f2054',
  'requestType': 'estimate',
  'inputs': {...},
  'payment': {
    'amount': 500,
    'status': 'pending'
  }
};

await ApiHelper.updateOrder(orderId, updatedData);
```

### 5️⃣ **Delete Order**

```dart
await ApiHelper.deleteOrder(orderId);
```

### 6️⃣ **Generate Estimate**

```dart
// userId automatically header me jayega
final estimateData = {
  'dimensions': {
    'length': 60,
    'width': 30,
    'groundFloor': 1500,
    'firstFloor': 1000
  },
  'ownerDetais': {
    'name': 'Mr Sufiyan Khan',
    'address': 'Plot - 101, Kohka, Bhilai'
  },
  'sheetType': 'gf_ff_with_interior',
  'status': 'paid'
};

await ApiHelper.generateEstimate(estimateData);
```

---

## 📱 Screens Flow

```
Splash Screen
    ↓
[Token Check]
    ↓
┌─────────────┬─────────────┐
│ No Token    │ Has Token   │
↓             ↓
Login Screen  Home Screen
    ↓             ↓
OTP Screen    [Dashboard]
    ↓             ↓
[Verify]      ┌───┴───┐
    ↓         ↓       ↓
Home Screen   My      Generate
              Orders  Estimate
              ↓
          [View/Edit/Delete]
```

---

## 🔑 API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/send-otp` | POST | Send OTP to email |
| `/auth/verify-otp` | POST | Verify OTP & get token |
| `/orders/order/user/:userId` | GET | Get user orders |
| `/orders/order/:orderId` | PUT | Update order |
| `/orders/order/:orderId` | DELETE | Delete order |
| `/estimate/generate` | POST | Generate estimate (userId in header) |

---

## 💾 Token Storage

Token `shared_preferences` me save hota hai:

```dart
// Save
await TokenService.saveToken(token, userId, email);

// Get
String? token = await TokenService.getToken();
String? userId = await TokenService.getUserId();
String? email = await TokenService.getUserEmail();

// Check
bool isLoggedIn = await TokenService.isLoggedIn();

// Logout
await TokenService.logout();
```

---

## 🎨 UI Features

- ✨ Material Design 3
- 📱 Responsive cards
- 🔄 Pull to refresh on orders
- ⚠️ Error handling with retry
- 🎯 Loading states
- ✅ Form validation
- 💬 Confirmation dialogs
- 📢 Snackbar notifications

---

## 🚦 Testing Flow

1. **Run the app** → Shows splash screen
2. **No token** → Goes to Login Screen
3. **Enter email** → OTP sent
4. **Enter OTP** → Token saved, goes to Home
5. **Close app completely**
6. **Open app again** → Splash → Automatically goes to Home (token exists!)
7. **Click My Orders** → Shows all orders
8. **Update/Delete** → Works perfectly
9. **Generate Estimate** → userId in header automatically
10. **Logout** → Token cleared, back to Login

---

## 🔧 Customization

### Change API Base URL

```dart
// lib/services/api_helper.dart
static const String baseUrl = 'YOUR_API_URL';
```

### Change App Theme

```dart
// lib/main.dart
theme: ThemeData(
  primarySwatch: Colors.blue, // Change color
  useMaterial3: true,
)
```

---

## 📦 Dependencies

```yaml
dependencies:
  http: ^1.1.0              # API calls
  shared_preferences: ^2.2.2 # Local storage
```

---

## ✅ Complete Checklist

- ✅ OTP Authentication
- ✅ Token Storage
- ✅ Auto Login on App Start
- ✅ Get User Orders (uses userId automatically)
- ✅ Update Order
- ✅ Delete Order
- ✅ Generate Estimate (userId in header)
- ✅ Logout Functionality
- ✅ Error Handling
- ✅ Loading States
- ✅ Beautiful UI
- ✅ Form Validation

---

## 🎯 Ready to Use!

Bas `flutter pub get` karo aur run karo! 🚀

All functionality complete hai with beautiful UI! 💯

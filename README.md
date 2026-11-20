# BSS Attendance Mobile

Aplikasi Presensi Mobile Karyawan Operasional & Lapangan **PT Bumi Sukses Sinergi**. Dibangun dengan **Flutter** menerapkan standar **Clean Architecture**, **Arsitektur Offline-First Sejati (SQLite)**, **Desain Berbasis Komponen Modular**, dan **Proteksi Keamanan Tingkat Tinggi (Mobile Security Hardening)**.

---

## 🏛️ Arsitektur Sistem (Clean Architecture)

Aplikasi mengadopsi prinsip Clean Architecture dengan pemisahan tanggung jawab yang jelas:

```text
lib/
├── core/
│   ├── config/              # Environment (.env), AppConfig
│   ├── database/            # DatabaseHelper (SQLite openDatabase, skema & index)
│   ├── di/                  # Service Locator (GetIt dependency injection)
│   ├── network/             # DioClient, AuthInterceptor, ApiResponse, ApiExceptions
│   ├── security/            # AntiMockLocationService, SecureStorageService, BiometricAuthService
│   ├── sync/                # SyncManager (Debounced auto-sync engine)
│   ├── theme/               # AppColors, AppTextStyles (Plus Jakarta Sans, Tabular Figures)
│   └── utils/               # UuidHelper (RFC-4122 v4 UUID generator)
├── data/
│   ├── datasources/         # SqliteAttendanceLocalDataSource, AttendanceRemoteDataSource, AuthRemoteDataSource
│   ├── models/              # AttendanceModel, UserModel, TodayStatusModel, SyncBatchResultModel
│   └── repositories/        # AttendanceRepositoryImpl, AuthRepositoryImpl
├── domain/
│   ├── entities/            # AttendanceRecord, User, TodayStatus, SyncBatchResult
│   ├── repositories/        # IAttendanceRepository, IAuthRepository
│   └── usecases/            # Login, Logout, CheckIn, CheckOut, SyncBatchOffline, GetTodayStatus, dll.
└── presentation/
    ├── components/          # Reusable Component Library (Buttons, Cards, Inputs, Feedback, Dialogs)
    ├── providers/           # AuthProvider, AttendanceProvider
    └── screens/             # HomeScreen, HistoryScreen, ProfileScreen, LoginScreen
```

---

## ✨ Fitur Unggulan

### 1. Arsitektur Offline-First Sejati (Local-First Pattern)
* **SQLite Engine (`sqflite`)**: Database lokal relasional berfungsi sebagai *Single Source of Truth*. Data kehadiran dan riwayat langsung dimuat seketika tanpa layar putih/error koneksi.
* **Instant Offline Check-in/Check-out**: Karyawan dapat melakukan presensi kapan saja tanpa koneksi internet. Setiap presensi lokal langsung dibuatkan **UUID v4 unik** dan disimpan dengan status `sync_status = 0`.
* **Batch Auto-Sync Otomatis**: Saat koneksi internet terhubung kembali, `SyncManager` secara otomatis mengirimkan kumpulan presensi offline ke endpoint `POST /attendance/sync-offline` dalam satu transaksi atomik.

### 2. Kepatuhan Penuh Kontrak API Backend Laravel
* `POST /auth/login`: Autentikasi karyawan & token Sanctum.
* `POST /auth/logout`: Menghapus token di server dan membersihkan sesi lokal.
* `GET /user`: Auto-refresh data profil karyawan.
* `GET /attendance/today`: Menentukan status kehadiran harian (`can_checkin`, `can_checkout`).
* `POST /attendance/save`: Presensi real-time dengan UUID standar.
* `GET /attendance/history`: Riwayat kehadiran dengan filter pencarian dan paginasi.
* `POST /attendance/sync-offline`: Sinkronisasi batch transaksi dengan deduplikasi UUID.

### 3. Keamanan Tingkat Tinggi (Mobile Security Hardening)
* **Anti-Mock Location (Anti-Fake GPS)**: Mendeteksi penggunaan aplikasi Fake GPS via `position.isMocked` hardware flag dan menolak presensi palsu.
* **Validasi Akurasi GPS**: Menolak sinyal GPS yang tidak akurat (> 100m) atau koordinat palsu (0,0).
* **Penyimpanan Terenkripsi**: Token Sanctum disimpan di **Android Keystore (AES-GCM)** dan **iOS Keychain** via `flutter_secure_storage`.
* **Biometric Authentication**: Opsi verifikasi sidik jari/Face ID sebelum presensi dieksekusi.
* **Deteksi Root / Jailbreak**: Pengecekan jejak instalasi binary superuser/su.

### 4. UI Modern & Ergonomi UX Lapangan (Anti-"AI Slop")
* **Desain Industrial Elegan**: Palet warna profesional (*Deep Slate Navy*, *Steel Blue*, *Emerald Green*, *Safety Amber*).
* **Jam Digital Live dengan Tabular Figures**: Angka jam, menit, dan detik tidak bergetar berkat `FontFeature.tabularFigures()`.
* **Swipe-to-Confirm Interaction**: Menggunakan tombol geser (`SwipeActionButton`) untuk Check-in dan Check-out guna mencegah tombol terpencet tidak sengaja di dalam saku baju/celana.
* **App Lifecycle Auto-Refresh**: Menggunakan `WidgetsBindingObserver` (`AppLifecycleState.resumed`) sehingga saat aplikasi dibuka kembali dari background di sore hari, status `GET /attendance/today` otomatis diperbarui tanpa restart aplikasi.

---

## 🚀 Memulai Pengembangan

### 1. Prasyarat
* Flutter SDK: ^3.12.0
* Dart SDK: ^3.12.0
* Backend Laravel aktif di `http://bss-attendance-be.test/api`

### 2. Konfigurasi Environment
Salin file konfigurasi `.env.example` menjadi `.env`:
```bash
cp .env.example .env
```
Isi konfigurasi dalam file `.env`:
```env
API_BASE_URL=http://bss-attendance-be.test/api
APP_ENV=development
```

### 3. Mengunduh Dependensi
```bash
flutter pub get
```

### 4. Menjalankan Tes Otomatis
```bash
flutter test
```

### 5. Memeriksa Linter
```bash
flutter analyze
```

### 6. Menjalankan Aplikasi
```bash
flutter run
```

---

## 🧪 Matriks Pengujian
Aplikasi dilengkapi dengan 27 pengujian otomatis yang mencakup:
* Pengujian unit parser & format payload DTO API (`AttendanceModel`, `UserModel`, `SyncBatchResultModel`).
* Pengujian unit generator & validator UUID v4 (`UuidHelper`).
* Pengujian unit database lokal SQLite in-memory FFI (`SqliteAttendanceLocalDataSource`).
* Pengujian unit keamanan Anti-Mock GPS (`AntiMockLocationService`).
* Pengujian unit penyimpanan aman Keystore (`SecureStorageService`).
* Pengujian integrasi komponen UI (`AppButton`, `LocationInfoCard`, `OfflineStatusBanner`).
* Pengujian siklus hidup resume aplikasi (`WidgetsBindingObserver`).

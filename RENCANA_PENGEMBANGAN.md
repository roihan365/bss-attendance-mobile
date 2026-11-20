# Blueprint & Rencana Pengembangan BSS Attendance Mobile

Dokumen ini berisi cetak biru arsitektur, hasil analisis menyeluruh terhadap kode Flutter `d:\bss-attendance-mobile`, pemetaan kontrak API backend `C:\laragon\www\bss-attendance-be\Absensi BSS 1`, serta status implementasi bertahap (*phase-by-phase*).

---

## 1. Status Penyelesaian Rencana Pengembangan (100% Selesai)

| Fase | Fokus Pengembangan | Branch Fitur | Status |
|---|---|---|:---:|
| **Fase 1** | Fondasi Core, Networking Dio, UuidHelper & Komponen Modular | `feature/fase-1-core-networking-components` | ✅ Selesai & Merged |
| **Fase 2** | Integrasi Penuh Seluruh API, Batch Sync & Clean Architecture | `feature/fase-2-api-batch-sync` | ✅ Selesai & Merged |
| **Refinement** | Lifecycle Auto-Refresh (`AppLifecycleState.resumed`) | `feature/auto-refresh-lifecycle` | ✅ Selesai & Merged |
| **Fase 3** | Arsitektur Offline-First & SQLite Local Engine | `feature/fase-3-sqlite-offline-engine` | ✅ Selesai & Merged |
| **Fase 4** | Keamanan Aplikasi & Anti-Fraud (Anti-Mock GPS, Keystore, Biometrik) | `feature/fase-4-security-antifraud` | ✅ Selesai & Merged |
| **Fase 5** | Redesain UI Modern & Ergonomi UX Lapangan (Anti-AI Slop) | `feature/fase-5-modern-ui-ux` | ✅ Selesai & Merged |
| **Fase 6** | Testing Menyeluruh, Hardening R8/ProGuard & Persiapan Rilis | `feature/fase-6-testing-hardening` | ✅ Selesai & Merged |

---

## 2. Pemetaan Lengkap API Backend (Laravel Sanctum)

| Endpoint | Method | Status Integrasi | Keterangan Implementasi |
|---|---|:---:|---|
| `/auth/login` | POST | ✅ Selesai | Mengautentikasi pengguna, menyimpan data user & token terenkripsi. |
| `/auth/logout` | POST | ✅ Selesai | Menghapus token di server dan membersihkan sesi lokal. |
| `/user` | GET | ✅ Selesai | Auto-refresh detail profil pengguna dari server. |
| `/attendance/today` | GET | ✅ Selesai | Sumber kebenaran status harian (`can_checkin`, `can_checkout`). |
| `/attendance/save` | POST | ✅ Selesai | Presensi real-time dengan UUID v4 standar. |
| `/attendance/history` | GET | ✅ Selesai | Riwayat kehadiran dengan filter tipe/tanggal & pagination support. |
| `/attendance/sync-offline` | POST | ✅ Selesai | Batch sync transaksi atomik dengan deduplikasi UUID. |

---

## 3. Fitur Utama & Proteksi Keamanan yang Diterapkan

1. **Clean Architecture Penuh**:
   * *Domain*: Objek entitas murni (`User`, `AttendanceRecord`, `TodayStatus`, `SyncBatchResult`), repository interface, dan single-responsibility use cases.
   * *Data*: DTO models (`AttendanceModel`, `UserModel`, dsb), remote data source (`DioClient`), SQLite local data source.
   * *Presentation*: State management terisolasi via `Provider`, UI components library.
   * *Dependency Injection*: Service locator modular via `get_it`.
2. **Arsitektur Offline-First Sejati**:
   * Database relasional SQLite (`sqflite`) sebagai *Single Source of Truth*.
   * Transaksi presensi offline instan dengan UUID v4 standar RFC-4122.
   * Otomatisasi batch sync saat koneksi internet kembali aktif dengan *debouncer*.
3. **Keamanan & Anti-Fraud (Mobile Security Hardening)**:
   * **Anti-Mock Location**: Blokir otomatis jika terdeteksi Fake GPS via `position.isMocked`.
   * **Ambang Batas Akurasi**: Menolak koordinat GPS dengan akurasi buruk (> 100m).
   * **Penyimpanan Terenkripsi**: Token Sanctum diamankan di Android Keystore (AES-GCM) dan iOS Keychain.
   * **Autentikasi Biometrik**: Integrasi sidik jari/Face ID via `local_auth`.
4. **UI Modern & Ergonomi UX Lapangan**:
   * Jam digital live dengan *tabular figures* (angka tidak bergetar).
   * Tombol geser interaktif `SwipeActionButton` untuk Check-in dan Check-out.
   * Auto-refresh status kehadiran saat aplikasi dibuka kembali dari background (`WidgetsBindingObserver`).

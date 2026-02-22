# Election Watch — final66106337

ระบบเฝ้าระวังการเลือกตั้ง (Election Violation Reporting App)  
สร้างด้วย Flutter + SQLite (sqflite) + Firebase Firestore + TensorFlow Lite

- **Firebase Project:** `ele-192`
- **Firebase Account:** `patiphat.je@gmail.com`
- **Firestore Collection:** `incident_reports`

---

## โครงสร้างโปรเจกต์

```
lib/
├── constants/
│   └── theme.dart               # ธีมสี Material 3 โทนเขียว
├── helpers/
│   ├── db_helper.dart           # SQLite: สร้าง DB v2, seed data, sync queries
│   ├── firebase_helper.dart     # Firestore: save, sync batch, connectivity check
│   └── ai_helper.dart           # TFLite: โหลดโมเดล, วิเคราะห์ภาพ, mapping
├── models/
│   ├── polling_station.dart
│   ├── violation_type.dart
│   └── incident_report.dart     # มี synced field (0=offline, 1=synced)
├── screens/
│   ├── home_screen.dart         # Screen 1: Dashboard + Sync Banner + Drawer
│   ├── report_incident_screen.dart  # Screen 2: รายงาน + AI + Dual Save
│   ├── edit_station_list_screen.dart  # Screen 3a: รายการหน่วยเลือกตั้ง
│   ├── edit_station_form_screen.dart  # Screen 3b: แก้ไขหน่วย + Validation
│   ├── incident_list_screen.dart    # Screen 4: รายการ + Sync Badge + Sync All
│   └── search_filter_screen.dart    # Screen 5: ค้นหา + กรอง + Sync Badge
├── widgets/
│   ├── severity_badge.dart      # Widget แสดงระดับความรุนแรง (High/Medium/Low)
│   └── sync_status_badge.dart   # Widget แสดงสถานะ Online/Offline ต่อรายการ
├── firebase_options.dart        # ← สร้างโดย FlutterFire CLI (ele-192)
└── main.dart

assets/
└── models/
    └── election_model.tflite    # โมเดล TFLite สำหรับ AI classification

web/
└── database_setup.sql           # SQL script สร้างตารางและ seed data
```

---

## ขั้นตอนการติดตั้งและรันโปรเจกต์

### 1. ติดตั้ง Dependencies

```bash
flutter pub get
```

### 2. Firebase 

Firebase ถูกเชื่อมต่อกับโปรเจกต์ `ele-192` เรียบร้อยแล้ว:
- ไฟล์ `lib/firebase_options.dart` ถูกสร้างโดย FlutterFire CLI
- `lib/main.dart` เรียก `Firebase.initializeApp()` อัตโนมัติ
- รองรับ: **Android, iOS, Web, Windows, macOS**

**สิ่งที่ต้องทำบน Firebase Console (ครั้งเดียว):**
1. เปิด [Firebase Console → ele-192 → Firestore Database](https://console.firebase.google.com/project/ele-192/firestore)
2. กด **"Create database"** → เลือก **"Start in test mode"** → เลือก location `asia-southeast1` → **Done**
3. เมื่อ submit report จากแอป หรือกดปุ่ม **Sync** บน Dashboard ข้อมูลจะปรากฏใน collection `incident_reports`

> **หมายเหตุ:** หาก Firebase ยังไม่ได้สร้าง Firestore Database แอปยังทำงานได้ปกติในโหมด Offline (SQLite)  
> Dashboard จะแสดงสถานะ "Firebase Offline" และปุ่ม Sync จะถูก disable อัตโนมัติ

### 3. ตั้งค่าโมเดล TFLite (AI)

1. วางไฟล์โมเดล TensorFlow Lite ของคุณที่:
   ```
   assets/models/election_model.tflite
   ```
2. โมเดลต้องมี output 3 class ตามลำดับ:
   - `0` → Money (ซื้อเสียง) → auto-map to type_id=1
   - `1` → Crowd (ขนคน) → auto-map to type_id=2
   - `2` → Poster (ทำลายป้าย) → auto-map to type_id=4
3. Input: tensor ขนาด `[1, 224, 224, 3]` float32 (normalize 0.0–1.0)

> **หมายเหตุ:** `tflite_flutter ^0.10.4` ไม่รองรับ Dart SDK >=3.11 (UnmodifiableUint8ListView removed)  
> แอปจะใช้ผลลัพธ์จำลอง (Money, 95%) โค้ด TFLite จริงอยู่ใน comment ของ `ai_helper.dart` พร้อมใช้เมื่อ package อัปเดต

### 4. รันแอป

```bash
# รันบน Android
flutter run

# รันบน Windows
flutter run -d windows

# Build APK
flutter build apk --release
```

---

## ระบบ Sync Online/Offline

แอปรองรับการทำงานแบบ **Hybrid** ทั้ง Offline (SQLite) และ Online (Firestore):

| ฟีเจอร์ | คำอธิบาย |
|---|---|
| **Sync Status Banner** | Dashboard แสดงสถานะ Firebase Connected/Offline + จำนวน Synced/Pending |
| **Sync All Button** | ปุ่ม Sync บน Dashboard และ Incident List สำหรับ sync ข้อมูลทั้งหมดที่ยังไม่ได้ sync |
| **Per-Item Badge** | ทุก incident แสดง badge 🟢 Online หรือ 🟠 Offline ในหน้า Incident List และ Search |
| **Auto Sync on Save** | เมื่อ submit report จะบันทึก SQLite ก่อน แล้ว sync ขึ้น Firebase ทันที |
| **Detailed Notification** | SnackBar แสดงผลชัดเจน: "Saved: SQLite + Firebase ✅" หรือ "SQLite only ⚠️" |
| **synced column** | SQLite column `synced` (0=offline, 1=synced) ติดตามสถานะทุก record |

---

## ฐานข้อมูล SQLite

ฐานข้อมูลชื่อ `election_watch.db` (version 2) จะถูกสร้างอัตโนมัติเมื่อเปิดแอปครั้งแรก:

| ตาราง | จำนวน seed rows | คำอธิบาย |
|---|---|---|
| `polling_station` | 4 หน่วย | หน่วยเลือกตั้ง (station_id = 101–104) |
| `violation_type` | 5 ประเภท | ประเภทการทุจริต (type_id = 1–5) |
| `incident_report` | 3 รายการ | รายงานเหตุการณ์ตัวอย่าง + synced column |

SQL script ดูได้ที่: `web/database_setup.sql`

---

## Dependencies หลัก

| Package | เวอร์ชัน | การใช้งาน |
|---|---|---|
| `sqflite` | ^2.3.3 | SQLite offline database |
| `path_provider` | ^2.1.3 | หา path สำหรับ DB |
| `path` | ^1.9.0 | จัดการ path ไฟล์ |
| `image_picker` | ^1.1.2 | ถ่ายภาพ / เลือกจาก Gallery |
| `firebase_core` | ^3.6.0 | Firebase initialization |
| `cloud_firestore` | ^5.4.3 | บันทึกข้อมูลออนไลน์ (Firestore) |
| `tflite_flutter` | ^0.10.4 | AI classification (commented — Dart 3.11 compat) |

---

## 5 หน้าจอหลัก

| # | หน้าจอ | ฟีเจอร์หลัก |
|---|---|---|
| 1 | **Dashboard** | Sync Banner (Connected/Offline), ปุ่ม Sync All, Total Incidents, Top 3 Bar Chart, Drawer + Grid |
| 2 | **Report Incident** | ถ่ายภาพ + AI วิเคราะห์ (label + %), auto-select dropdown, บันทึก SQLite + Firestore, SnackBar แจ้งผล |
| 3 | **Edit Station** | แก้ไขชื่อหน่วย, ตรวจ prefix + duplicate, Dialog ยืนยันหากมี report |
| 4 | **Incident List** | JOIN 3 ตาราง, thumbnail, Sync Badge per item, ปุ่ม Sync All, ลบ + confirm |
| 5 | **Search & Filter** | ค้นหา LIKE + กรอง severity, Sync Badge per item, "No records found" |

---

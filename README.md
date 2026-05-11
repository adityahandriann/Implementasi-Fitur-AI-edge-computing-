# 🏢 SobatKost - Smart Boarding House Management App

**Nama:** Muhammad Aditya Handrian  
**NRP:** 5025231292  
**Tugas:** Implementasi Fitur AI (Edge Computing)  

**GitHub Repository Link (Public):** [https://github.com/adityahandriann/Implementasi-Fitur-AI-edge-computing-.git](https://github.com/adityahandriann/Implementasi-Fitur-AI-edge-computing-.git)

---

## 📖 Deskripsi Proyek

SobatKost adalah aplikasi manajemen kost modern yang mengintegrasikan teknologi **Edge Computing (Artificial Intelligence On-Device)** untuk mempermudah proses registrasi, pemantauan status kamar, dan pelaporan kerusakan. 

Dibangun dengan Flutter, aplikasi ini menggabungkan database lokal (SQLite) untuk Admin dan sinkronisasi Cloud (Firebase Firestore) untuk memastikan keakuratan data secara global dan real-time.

### ✨ Fitur Unggulan & Implementasi AI

1. **AI Edge KTP Scanner (Google ML Kit)**
   - **Fungsi:** Ekstraksi otomatis data NIK, Nama, dan Alamat dari KTP fisik saat proses verifikasi penghuni baru.
   - **Inovasi Edge Computing:** Pemrosesan gambar dan pengenalan teks (*Optical Character Recognition*) dilakukan 100% secara *offline* di perangkat (*on-device*). Ini menjamin privasi data KTP yang sensitif tanpa perlu mengirim gambar ke server, serta memberikan respons deteksi yang sangat cepat. Dilengkapi dengan algoritma filter cerdas (*Pattern Matching*) untuk memisahkan Label ("Nama") dengan Nilai Asli (Nama Penghuni).

2. **AI Real-Time Damage Scanner (YOLOv11)**
   - **Fungsi:** Pemindaian kerusakan fasilitas kost secara langsung melalui kamera.
   - **Inovasi Edge Computing:** Menggunakan model AI YOLO (*You Only Look Once*) versi *lite* yang dijalankan langsung di HP menggunakan `ultralytics_yolo`. Fitur ini membantu penghuni dan admin mendeteksi kerusakan secara visual dan otomatis membuat deskripsi laporan tanpa perlu mengetik manual.

3. **Global Real-Time Room Availability Map**
   - Menggantikan dropdown tradisional dengan peta grid kamar yang interaktif. (Hijau: Kosong, Merah: Terisi/FULL).
   - Menggunakan sinkronisasi cerdas antara *SQLite (Local Admin DB)* dan *Firestore (Cloud)* sehingga calon pendaftar selalu melihat status ketersediaan kamar yang akurat meskipun Admin melakukan penambahan data secara manual (*offline*).

---

## 📸 Screenshots

*(Ganti URL gambar di bawah dengan link screenshot asli Anda. Cara termudah: Seret & lepas (drag-and-drop) gambar dari komputer ke area editor GitHub, dan GitHub akan otomatis membuatkan link gambarnya).*

### 1. Fitur AI: Scan KTP (Edge OCR)
![AI KTP Scanner](URL_GAMBAR_SCAN_KTP)
> *Sistem secara otomatis mengekstrak NIK dan Nama dari KTP fisik tanpa internet.*

### 2. Fitur AI: Damage Scanner (YOLO)
![YOLO Damage Scanner](URL_GAMBAR_YOLO_SCANNER)
> *Deteksi objek dan kerusakan secara real-time melalui kamera HP.*

### 3. Peta Kamar & Registrasi (Real-time Sync)
![Visual Room Map](URL_GAMBAR_PETA_KAMAR)
> *Sistem grid kamar visual. Kamar yang sudah dikonfirmasi Admin di database lokal otomatis menjadi merah (FULL) bagi pengguna baru di aplikasi.*

### 4. Admin Dashboard
![Admin Dashboard](URL_GAMBAR_ADMIN_DASHBOARD)
> *Halaman Admin untuk manajemen data penghuni (CRUD SQLite).*

---

**Project ini dibuat untuk memenuhi tugas Implementasi Fitur AI (Edge Computing).**

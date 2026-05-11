# 🏢 SobatKost - Smart Boarding House Management App

**Nama:** Muhammad Aditya Handrian  
**NRP:** 5025231292  
**Tugas:** Implementasi Fitur AI (Edge Computing)  

**GitHub Repository Link (Public):** [https://github.com/adityahandriann/Implementasi-Fitur-AI-edge-computing-.git](https://github.com/adityahandriann/Implementasi-Fitur-AI-edge-computing-.git)

---

## 📝 Deskripsi Project
**SobatKost** adalah aplikasi manajemen kost cerdas yang mengimplementasikan teknologi **Edge Computing (AI On-Device)** untuk memproses data langsung di perangkat Android pengguna tanpa bergantung pada server internet. Pendekatan ini meningkatkan kecepatan, efisiensi bandwidth, dan keamanan privasi data penghuni.

Project ini menggunakan arsitektur hybrid database (Firebase Firestore untuk sinkronisasi global & SQLite untuk manajemen lokal) beserta UI grid visual interaktif untuk pemilihan kamar.

---

## 🤖 Implementasi Fitur AI (Edge Computing)

Project ini mengintegrasikan dua model AI Edge Computing utama yang sangat fungsional untuk manajemen kost:

### 1. Smart KTP Scanner (Edge OCR)
Fitur otomatisasi pendataan penghuni baru menggunakan **Google ML Kit Text Recognition**.
* **Cara Kerja**: Kamera memindai KTP fisik dan AI mengekstrak data sensitif (NIK, Nama, Alamat) secara *real-time*.
* **Konsep Edge**: Pemrosesan *Computer Vision* dilakukan sepenuhnya di dalam *smartphone* pengguna (On-Device). Data KTP tidak pernah dikirim ke server/API pihak ketiga untuk dibaca, sehingga privasi NIK sangat aman.
* **Smart Filtering**: Algoritma AI dilengkapi filter *Pattern Matching* untuk membedakan antara "Label" (seperti tulisan "Tempat/Tgl Lahir") dengan "Value" (Nama sebenarnya) di tengah pola *watermark* KTP.

### 2. YOLO Damage Scanner (Real-Time Object Detection)
Fitur pelaporan kerusakan fasilitas menggunakan model **Ultralytics YOLO (You Only Look Once)** format `.tflite`.
* **Cara Kerja**: Penghuni atau Admin mengarahkan kamera ke fasilitas kost yang rusak. AI langsung mengenali jenis objek yang mengalami kerusakan (misal: kursi, kipas, lampu) dan menggenerasi kalimat laporan otomatis (contoh: *"Kerusakan terdeteksi pada: Kursi. Mohon segera ditangani"*).
* **Konsep Edge**: Model AI Neural Network (YOLOv11 Int8) ditanamkan (*embedded*) langsung di dalam aplikasi (folder assets) dengan kecepatan deteksi (FPS) tinggi meski tanpa sinyal internet.

---

## 📸 Screenshots Implementasi

*(Silakan unggah gambar Anda ke GitHub / Imgur dan masukkan link gambarnya di bawah ini)*

### 1. KTP Scanner (Google ML Kit)
> Menampilkan AI mendeteksi dan mengekstrak NIK serta Nama dari KTP.
![KTP Scanner AI](<[Masukkan URL Gambar Screenshot KTP Scanner]>)

### 2. YOLO Damage Scanner
> Menampilkan deteksi objek real-time menggunakan YOLO Camera.
![YOLO Scanner](<[Masukkan URL Gambar Screenshot YOLO Scanner]>)



# 🏢 SobatKost - Smart Boarding House Management App

**Nama:** Muhammad Aditya Handrian  
**NRP:** 5025231292  
**Tugas:** Implementasi Fitur AI (Edge Computing)  

**GitHub Repository:** [https://github.com/adityahandriann/Implementasi-Fitur-AI-edge-computing-.git](https://github.com/adityahandriann/Implementasi-Fitur-AI-edge-computing-.git)

---

## 📝 Deskripsi Project
**SobatKost** adalah aplikasi manajemen kost cerdas yang mengimplementasikan teknologi **Edge Computing (AI On-Device)** untuk memproses data langsung di perangkat Android pengguna tanpa bergantung pada server internet. Pendekatan ini meningkatkan kecepatan, efisiensi bandwidth, dan keamanan privasi data penghuni.

Project ini menggunakan arsitektur hybrid database (Firebase Firestore untuk sinkronisasi global & SQLite untuk manajemen lokal) beserta UI grid visual interaktif untuk pemilihan kamar.

---

## 🤖 Implementasi Fitur AI (Edge Computing)

Project ini mengintegrasikan tiga model AI Edge Computing utama yang fungsional untuk manajemen operasional kost:

### 1. Smart KTP Scanner (Edge OCR)
Fitur otomatisasi pendataan penghuni baru menggunakan **Google ML Kit Text Recognition**.
* **Cara Kerja**: Kamera memindai KTP fisik dan AI mengekstrak data sensitif (NIK, Nama, Alamat) secara *real-time*.
* **Konsep Edge**: Pemrosesan *Computer Vision* dilakukan sepenuhnya di dalam *smartphone* pengguna (On-Device). Data KTP tidak pernah dikirim ke server pihak ketiga, menjamin privasi NIK tetap aman.
* **Smart Filtering**: Algoritma AI dilengkapi filter *Pattern Matching* untuk membedakan antara label teks dengan nilai data sebenarnya di tengah pola *watermark* KTP.

### 2. YOLO Damage Scanner (Real-Time Object Detection)
Fitur pelaporan kerusakan fasilitas menggunakan model **Ultralytics YOLO** dalam format `.tflite`.
* **Cara Kerja**: Penghuni atau Admin mengarahkan kamera ke fasilitas kost. AI langsung mengenali jenis objek yang rusak (kursi, kipas, lampu) dan menggenerasi kalimat laporan otomatis.
* **Konsep Edge**: Model AI Neural Network (YOLOv11 Int8) ditanamkan (*embedded*) langsung di dalam folder assets aplikasi dengan kecepatan deteksi (FPS) tinggi tanpa memerlukan koneksi internet.

### 3. Scan Nota/Kwitansi OCR (Edge OCR)
Fitur digitalisasi bukti pembayaran atau nota pengeluaran operasional kost.
* **Cara Kerja**: Menggunakan **Google ML Kit OCR** untuk mendeteksi teks pada nota fisik secara instan.
* **Fungsi**: AI mendeteksi angka nominal (total harga), tanggal transaksi, dan nama vendor secara otomatis untuk meminimalisir kesalahan input manual.
* **Konsep Edge**: Memastikan data keuangan diproses secara instan di sisi klien (On-Device), mempercepat proses administrasi keuangan.

---

## 📸 Screenshots Implementasi

### 1. KTP Scanner (Google ML Kit)
> Menampilkan AI mendeteksi dan mengekstrak NIK serta Nama dari KTP secara otomatis.

<p align="center">
  <img width="30%" src="https://github.com/user-attachments/assets/fd8827d9-0eed-43da-9052-1e437bc06a5c" />
  <img width="30%" src="https://github.com/user-attachments/assets/603057dc-092e-4780-8ef4-741cfa3cd46e" />
  <img width="30%" src="https://github.com/user-attachments/assets/0979d459-9dbb-4cde-9347-31dc072a07b3" />
</p>
<p align="center">
  <img width="30%" src="https://github.com/user-attachments/assets/9a2f4279-0aa7-4b42-8caf-fcfc0a2fdb05" />
  <img width="30%" src="https://github.com/user-attachments/assets/89cf174e-5cd6-4f5c-8ec8-c14936db4baa" />
</p>

### 2. YOLO Damage Scanner
> Menampilkan deteksi objek secara real-time menggunakan YOLO Camera untuk pelaporan fasilitas.

<p align="center">
  <img width="24%" src="https://github.com/user-attachments/assets/0238b21c-5493-421c-8ef0-9e2c697e8253" />
  <img width="24%" src="https://github.com/user-attachments/assets/83fd3982-9c26-403b-8bc7-ae07b2f32054" />
  <img width="24%" src="https://github.com/user-attachments/assets/c7aadfb0-fb9c-4dbd-b47c-2a14224e744d" />
  <img width="24%" src="https://github.com/user-attachments/assets/9d6f8382-4346-4568-96ff-2b09a154c923" />
</p>

### 3. Scan Nota OCR
> Menampilkan deteksi angka nominal serta detail isi dari nota pembayaran digital.

<p align="center">
  <img width="30%" src="https://github.com/user-attachments/assets/54a3d810-06b6-4941-9e54-31e92aee680b" />
  <img width="30%" src="https://github.com/user-attachments/assets/af72588d-0544-45dc-8762-8cd380ea9305" />
  <img width="30%" src="https://github.com/user-attachments/assets/2d058d14-e644-4ac9-915b-3413fe126342" />
</p>

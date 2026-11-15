# Haven - Click The Slime

Sebuah game 2D incremental clicker santai dan memuaskan (*juicy*) yang dibangun menggunakan **Godot Engine 4.x**. Pemain mengklik Slime untuk mengumpulkan koin, meningkatkan level hingga batas maksimal 150, membuka lokasi baru setiap 30 level, serta menyaksikan evolusi Slime sepanjang perjalanan dari padang rumput hingga ke dalam gua kristal.

Dokumentasi ini mengintegrasikan seluruh spesifikasi resmi **Game Design Document v2 (GDD v2)**, arsitektur kode modular, serta daftar referensi aset dan tutorial pengembangan.

---

## 1. Ringkasan & Tujuan Proyek (Project Goal)

Tujuan utama dari proyek **Haven - Click The Slime** adalah:
1. **Mengimplementasikan Game Design Document (GDD v2) Secara Presisi:**
   - Progresi 150 Level dengan batas akhir (*tamatan*).
   - Menjelajahi 5 tempat bertema unik dengan transisi latar dan pergantian visual/warna Slime di setiap kelipatan 30 level.
   - Sistem ekonomi dan kurva pertumbuhan koin berbasis eksponensial yang teruji dan seimbang.
   - Sistem Shop tanpa gacha: 3 item makanan (pengali koin dan memperbesar ukuran Slime) dan 3 item minuman (mempercepat loncatan/cooldown) yang sekali pakai dengan durasi boost.
2. **Memberikan Game Feel & Tactile Feedback yang Kuat (Juicy):**
   - Memberikan respons visual (squash & stretch, bounce, partikel koin, floating text, screen flash) serta efek suara renyah di setiap interaksi klik.
   - Menerapkan arsitektur kode modular (terpisah antara Coordinator Gameplay Logic, UI Manager, dan Audio/Feedback Manager) agar kode bersih, terorganisir, dan mudah dipresentasikan pada kompetisi hackathon.

---

## 2. Alur Game (Core Game Loop)

1. **Permulaan:** Pemain membuka game. Slime level 1 berwarna hijau berada di Padang Rumput dengan koin awal 0.
2. **Interaksi Klik (Anti-Spam Timing):** Pemain menekan tombol klik (`ClickButton`). Slime meloncat ke udara lalu memantul kembali (*bounce-back*). Klik saat Slime masih berada di udara tidak dihitung.
3. **Penghasilan Koin:** Setiap klik yang diterima menghasilkan koin sesuai rumus level Slime dan pengali aktif dari makanan atau combo boost.
4. **Upgrade Level:** Pemain menekan tombol Upgrade saat koin mencukupi. Level naik, koin per klik bertambah, dan loncatan makin cepat.
5. **Transisi Tempat (Milestone 30 Level):** Pada level 30, 60, 90, dan 120, tombol Upgrade berubah menjadi tombol **Pindah Tempat**. Menekannya menaikkan level ke 31, 61, 91, atau 121, mengganti gambar latar belakang secara otomatis, dan memperbarui varian animasi Slime.
6. **Belanja Shop (Makanan & Minuman):** Pemain membeli item sekali pakai di Shop selama koin cukup untuk mendapatkan boost sementara.
7. **Akhir Permainan (Level 150 MAX):** Pada level 150, tombol Upgrade berubah menjadi **MAX** dan layar tamat muncul. Pemain tetap diperbolehkan mengklik untuk terus mengumpulkan koin.

---

## 3. Lima Tempat dan Warna Slime (GDD v2)

Setiap tempat memiliki karakteristik visual latar belakang dan palet warna Slime masing-masing:

| Tempat | Level | Suasana Latar Belakang | Palet Warna Slime | Animasi Resource |
| :---: | :---: | :--- | :--- | :---: |
| **1. Padang Rumput** | 1 - 30 | Langit cerah, rumput luas, bunga kecil | Hijau (#52EA1A, #FCFFFB) | `jump_0` (Slime Hijau) |
| **2. Hutan Penuh Pepohonan** | 31 - 60 | Pohon tinggi dan rimbun, cahaya matahari menembus daun | Coklat (#68493A, #977B5E) | `jump_1` (Slime Mochi) |
| **3. Di Depan Mulut Gua** | 61 - 90 | Tebing batu, mulut gua gelap, obor di sisi kiri dan kanan | Abu (#5D4C44, #68594C) | `jump_2` |
| **4. Di Dalam Gua** | 91 - 120 | Dinding batu, stalaktit, cahaya remang | Biru (#2EFFFF, #01BEBE) | `jump_3` |
| **5. Di Dalam Gua Penuh Kristal** | 121 - 150 | Kristal besar bercahaya di dinding dan lantai | Ungu (#3A0DF2, #FD0DE7) | `jump_4` |

*Catatan Mekanik:*
- Warna dan visual Slime berganti otomatis saat pindah tempat. Tidak ada sistem gacha atau skin berbayar.
- Rute perjalanan bersifat satu arah: tempat yang sudah dilewati tidak dapat dikunjungi kembali.

---

## 4. Sistem Upgrade & Formula Matematis (Level 1 sampai 150)

Formula progresi matematis dirancang untuk mencegah angka *overflow* sambil tetap memberikan kepuasan peningkatan bertahap:
* **Koin per klik dasar:**
  `Koin = max(level, round(1.10^(level - 1)))`
* **Biaya upgrade level berikutnya:**
  `Biaya = round(10 * 1.12^(level - 1))`
* **Durasi loncatan dasar:**
  `Durasi = max(0.30, 0.97^(level - 1)) detik`
  *(Saat boost minuman aktif, batas durasi tercepat turun dari 0.30 detik menjadi 0.15 detik).*

### Tabel Contoh Progresi Level:

| Level | Koin per Klik | Durasi Loncatan | Biaya ke Level Berikutnya | Keterangan Milestone |
| :---: | :---: | :---: | :---: | :--- |
| **1** | 1 | 1.00 detik | 10 | Awal permainan di Padang Rumput |
| **10** | 2 | 0.76 detik | 28 | Fase awal |
| **20** | 6 | 0.56 detik | 86 | Pertengahan Phase 1 |
| **30** | 16 | 0.41 detik | 267 | Tombol berubah: Pindah ke Hutan |
| **45** | 66 | 0.30 detik | 1.464 | Kecepatan loncat mencapai batas dasar (0.3s) |
| **60** | 277 | 0.30 detik | 8.014 | Tombol berubah: Pindah ke Depan Gua |
| **90** | 4.830 | 0.30 detik | 240.107 | Tombol berubah: Pindah ke Dalam Gua |
| **120** | 84.281 | 0.30 detik | 7.193.574 | Tombol berubah: Pindah ke Gua Kristal |
| **149** | 1.336.957 | 0.30 detik | 192.427.596 | Ambang batas akhir |
| **150 (MAX)** | 1.470.653 | 0.30 detik | Selesai | Level Tamat / Tombol MAX aktif |

---

## 5. Item Shop: Makanan dan Minuman (GDD v2 Final)

Sistem gacha sepenuhnya dihapus. Semua item dapat dibeli langsung di antarmuka toko cepat melayang (*quick floating rounded cards*) di sudut kanan atas layar.

### Aturan Mekanika Item:
1. **Sekali Pakai (Single-Use Consumable):** Setiap item yang dibeli langsung mengaktifkan efek buff selama durasi yang ditentukan.
2. **Sistem Cooldown & Anti-Spam:** Selama masa durasi aktif, item tersebut masuk ke masa cooldown hitung mundur detik (`20s`, `19s`...). Item sejenis yang sedang aktif tidak dapat dibeli kembali hingga cooldown tuntas.
3. **Kombinasi Makanan & Minuman:** Pemain diperbolehkan mengaktifkan 1 item Makanan dan 1 item Minuman secara bersamaan. Efek dari kategori yang sama tidak dapat ditumpuk (*no stacking for same category*).
4. **Ketersediaan Universal:** Seluruh 6 item langsung tersedia sejak level 1 tanpa batasan kunci zona.

### A. Item Makanan (Memperbesar Slime & Pengali Koin)
Koin per klik akhir dihitung: `Koin Dasar * (1.0 + Pengali Makanan)`.

| Nama Item | File Gambar | Efek Koin | Harga | Durasi Boost & Cooldown |
| :--- | :--- | :---: | :---: | :---: |
| **Strawberry** | `item_strawberry.png` | +25% (+0.25x) | 2.500 Koin | 20 detik |
| **Jeruk** | `item_orange.png` | +50% (+0.50x) | 7.500 Koin | 25 detik |
| **Nanas** | `item_pineapple.png` | +75% (+0.75x) | 17.500 Koin | 25 detik |

### B. Item Minuman (Mempercepat Loncatan Slime)
Durasi loncat akhir dihitung: `Durasi Dasar * (1.0 - Pengurangan Cooldown)`. Batas tercepat loncatan turun menjadi 0.15 detik selama boost aktif.

| Nama Item | File Gambar | Efek Cooldown | Harga | Durasi Boost & Cooldown |
| :--- | :--- | :---: | :---: | :---: |
| **Diet Koke** (*Diet Coke*) | `item_diet_coke.png` | -15% Cooldown | 3.500 Koin | 15 detik |
| **Mtn Dow** (*Mtn Dew*) | `item_mtn_dew.png` | -25% Cooldown | 10.500 Koin | 15 detik |
| **Monstar Energy** (*Monster*) | `item_monster.png` | -35% Cooldown | 24.500 Koin | 10 detik |

---

## 6. Referensi & Inspirasi

Game ini mengadaptasi prinsip dasar game incremental terkemuka seperti **Cookie Clicker**:
* **Core Click Loop:** Mekanisme fundamental di mana klik manual menghasilkan mata uang dasar untuk investasi peningkatan.
* **Progression Satisfaction:** Eksponensial angka koin dan kecepatan loncat yang bertumbuh seiring waktu, menciptakan rasa pencapaian.
* **Combo Frenzy Boost:** Mirip fitur Frenzy di Cookie Clicker, game memiliki indikator Combo (10 klik beruntun sebelum bar habis) yang mengaktifkan mode Frenzy Boost 2X koin selama 7 detik.

---

## 7. Sumber Aset (Audio & Visual)

### A. Sumber Efek Suara (Audio SFX - Freesound.org)
Seluruh aset efek suara bersumber dari **Freesound.org** di bawah lisensi **Creative Commons 0 (CC0 Public Domain)** dan telah dioptimalkan ke format 16-bit PCM WAV Mono 44.1 kHz:

1. **`sfx_click.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: Pop UI button click sound
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Memberikan respon instan (*tactile click*) saat tombol klik utama ditekan.

2. **`sfx_jump.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: Cartoon slime bounce / spring jump sweep
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Diputar saat Slime melompat ke udara.

3. **`sfx_upgrade.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: Positive bell chime / ding arpeggio
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Diputar saat pemain berhasil membeli upgrade level.

4. **`sfx_level_up.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: High-pitch celebration fanfare jingle
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Diputar saat level naik atau milestone kelipatan level tercapai.

5. **`sfx_phase_change.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: Magic warp / portal teleport transition sound
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Diputar saat pemain menekan tombol Pindah Tempat.

6. **`sfx_boost.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: 8-Bit laser charge power-up sound
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Diputar saat Combo Frenzy Boost 2X aktif.

### B. Sumber Visual & Tipografi
* **Font UI:** *Melon Squishy* (`Melon Squishy.otf`) untuk tipografi ramah dan kasual.
* **Latar Belakang:** 5 file gambar latar (`Phase 1 (#1).jpeg` s/d `Phase 1 (#5).jpeg`) beresolusi tinggi bertema padang rumput, hutan, mulut gua, dalam gua, dan gua kristal.
* **Karakter Slime:** Sprite animasi 2D frame-by-frame (`slime_transparent_*.png` untuk Phase 1 dan `slime_phase2_*.png` untuk Phase 2).
* **Ikon Item Toko:** File ikon PNG transparan untuk 3 makanan dan 3 minuman.

---

## 8. Referensi Tutorial YouTube (Hackathon / Game Feel & Juice)

Daftar tutorial video YouTube yang relevan dengan implementasi teknik pada game ini:

1. **Godot 4 - In Depth Clicker Tutorial (Beginner & Intermediate)**
   - Link: https://www.youtube.com/watch?v=jQep5yqtvZ4
   - Relevansi: Membahas scene clicker dasar, struktur data upgrade, dan manipulasi sprite button.

2. **Reusable Tweens - Godot 4 Game Juice Component (Squash & Stretch, Button Pop)**
   - Link: https://www.youtube.com/watch?v=CV_BQ-wCZ8s
   - Relevansi: Menjelaskan cara menerapkan efek "pop" menggunakan Godot 4 Tween (`TRANS_BACK`, `EASE_OUT`) serta teknik squash and stretch agar tombol terasa kenyal dan hidup.

3. **Make a Game JUICIER with Me and Godot 4**
   - Link: https://www.youtube.com/watch?v=LSfkme6m18M
   - Relevansi: Panduan menambahkan feedback visual (*game feel / juiciness*), seperti screen flash, partikel feedback, dan transisi halus.

4. **How To Display Damage / Score Number Popups in Godot 4**
   - Link: https://www.youtube.com/watch?v=zGng3u9Y6dg
   - Relevansi: Tutorial membuat teks angka melayang (*floating text effect*) yang memantul dan memudar ke atas saat koin diperoleh.

---

## 9. Struktur Folder & Arsitektur Kode (Clean Hierarchy)

Proyek ini telah ditata dengan struktur hierarki folder yang bersih, rapi, dan modular:

```text
haven-click-the-slime/
├── assets/
│   ├── audio/                 # Aset audio SFX (sfx_*.wav)
│   ├── backgrounds/           # Aset gambar latar belakang 5 tempat
│   ├── fonts/                 # Tipografi font (Melon Squishy.otf)
│   ├── items/                 # Ikon item toko makanan & minuman
│   └── slimes/                # Kumpulan frame animasi Slime (Phase 1 - 5)
├── scripts/
│   ├── main.gd                # Coordinator: State game, level, koin, belanja, tween loncat
│   ├── ui_manager.gd          # UI Controller: HUD, kartu item toko, cooldown bar, tombol upgrade
│   └── feedback_manager.gd    # Game Feel: Pemutar audio SFX, partikel koin, pop effect
├── .editorconfig
├── .gitattributes
├── .gitignore
├── icon.svg
├── index.html                 # Halaman web info ringkas (quick info landing page)
├── main.tscn                  # Scene utama game (CanvasLayer, UI, Slime, Audio)
├── project.godot
└── README.md
```

### Penjelasan Setiap Script:
1. **`scripts/main.gd` (Coordinator):**
   - Menyimpan state utama (koin, level, phase, combo, status aktif item).
   - Menghitung rumus eksponensial koin, biaya upgrade, durasi loncatan, dan batas cooldown minimum (0.15s).
   - Mengatur tween loncat slime secara programmatic.
2. **`scripts/ui_manager.gd` (UI Controller):**
   - Menangani tombol klik khusus (`ClickButton`) dan mencegah klik sembarang tempat di layar.
   - Mengatur teks HUD (level, koin, durasi loncat, nama zona).
   - Mengatur tombol Upgrade / Pindah Tempat / MAX.
   - Mengontrol tampilan toko makanan dan minuman beserta label countdown detik.
3. **`scripts/feedback_manager.gd` (Game Feel / Juiciness):**
   - Memutar audio SFX yang tepat sesuai aksi pemain.
   - Menampilkan angka koin melayang (*floating coin numbers*).
   - Menjalankan efek squash-and-stretch pada tombol saat ditekan.

---

## 10. Panduan Menambah Animasi Slime Sendiri

Script `main.gd` dirancang untuk **mendeteksi animasi baru secara otomatis**. Anda tidak perlu menulis ulang kode script untuk menambah fase berikutnya:

1. **Siapkan Gambar:** Simpan 5 file frame animasi slime baru ke dalam folder `assets/slimes/`.
2. **Buka SpriteFrames di Godot:**
   - Buka scene `scenes/main.tscn`.
   - Pilih node `CanvasLayer/Slime` di panel Scene.
   - Di panel Inspector, klik resource `SpriteFrames`.
3. **Tambah Animasi Baru Sesuai Index:**
   - **Phase 3** (Depan Gua) -> Beri nama: `jump_2`
   - **Phase 4** (Dalam Gua) -> Beri nama: `jump_3`
   - **Phase 5** (Gua Kristal) -> Beri nama: `jump_4`
4. **Atur Frame & Kecepatan:**
   - Set **Speed (FPS)** ke `10.0`.
   - Matikan **Looping** (animasi tidak berulang sendiri).
   - Susun urutan 7 frame berikut:
     `Image 1 -> Image 2 -> Image 3 -> Image 4 -> Image 5 -> Image 2 -> Image 1`
5. **Simpan Scene (`Ctrl + S`)**: Ketika game dimainkan dan pemain mencapai fase tersebut, animasi baru akan langsung dimuat dengan warna aslinya secara otomatis.
   - **Phase 4** (Dalam Gua) -> Beri nama: `jump_3`
   - **Phase 5** (Gua Kristal) -> Beri nama: `jump_4`
4. **Atur Frame & Kecepatan:**
   - Set **Speed (FPS)** ke `10.0`.
   - Matikan **Looping** (animasi tidak berulang sendiri).
   - Susun urutan 7 frame berikut:
     `Image 1 -> Image 2 -> Image 3 -> Image 4 -> Image 5 -> Image 2 -> Image 1`
5. **Simpan Scene (`Ctrl + S`)**: Ketika game dimainkan dan pemain mencapai fase tersebut, animasi baru akan langsung dimuat dengan warna aslinya secara otomatis.

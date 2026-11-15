# Haven - Click The Slime

Sebuah game 2D incremental clicker santai dan memuaskan (*juicy*) yang dibangun menggunakan **Godot Engine 4.x**. Pemain mengklik Slime untuk mengumpulkan koin, meningkatkan level, membuka lokasi baru, serta menyaksikan evolusi Slime sepanjang perjalanan dari padang rumput hingga ke dalam gua kristal.

Proyek ini dibuat dan didokumentasikan dengan pendekatan Game Design Document (GDD) terstruktur, arsitektur kode modular, dan visual feedback yang responsif.

---

## 1. Tujuan Proyek (Project Goal)

Tujuan utama dari proyek **Haven - Click The Slime** adalah:
1. **Mengimplementasikan Game Design Document (GDD v2)** secara presisi:
   - Progresi 150 Level dengan batas akhir (*tamatan*).
   - Menjelajahi 5 tempat bertema unik dengan transisi latar dan evolusi wujud Slime di setiap kelipatan 30 level.
   - Sistem ekonomi dan kurva pertumbuhan koin berbasis eksponensial yang seimbang.
2. **Memberikan Game Feel & Tactile Feedback yang Kuat (Juicy):**
   - Memberikan respons visual (squash & stretch, bounce, partikel koin, floating text, screen flash) serta efek suara renyah di setiap interaksi klik.
   - Menerapkan arsitektur kode modular (terpisah antara Coordinator Gameplay Logic, UI Manager, dan Audio/Feedback Manager) agar kode bersih, terorganisir, dan mudah dijelaskan saat presentasi hackathon.

---

## 2. Referensi & Inspirasi

Game ini terinspirasi oleh mekanisme inti game clicker klasik seperti **Cookie Clicker**:
* **Core Click Loop:** Mekanisme dasar di mana klik manual menghasilkan mata uang (koin) untuk membeli peningkatan (*upgrade*).
* **Progression Satisfaction:** Pertumbuhan nilai koin per klik yang terus berlipat ganda, memotivasi pemain untuk mencapai milestone level dan membuka visual baru.
* **Frenzy / Combo Boost:** Mirip dengan efek Frenzy Cookie di Cookie Clicker, game ini memiliki Combo Meter (10 klik beruntun) yang memicu mode Frenzy Boost 2X koin berdurasi 7 detik.

---

## 3. Fitur Utama Gameplay

### A. Sistem 150 Level & 5 Lokasi (Phases)
Setiap kelipatan 30 level, tombol upgrade berubah menjadi tombol **Pindah Tempat**, memindahkan pemain ke zona baru:

| Phase | Lokasi | Rentang Level | Animasi Slime |
| :---: | :--- | :---: | :---: |
| **1** | Padang Rumput | Level 1 - 30 | `jump_0` (Slime Hijau) |
| **2** | Hutan Penuh Pepohonan | Level 31 - 60 | `jump_1` (Slime Cokelat Mochi) |
| **3** | Di Depan Mulut Gua | Level 61 - 90 | `jump_2` |
| **4** | Di Dalam Gua | Level 91 - 120 | `jump_3` |
| **5** | Gua Penuh Kristal | Level 121 - 150 (MAX) | `jump_4` |

### B. Mekanika Loncat & Cooldown (Anti-Spam Timing)
Sesuai aturan GDD: *"Klik saat Slime masih di udara tidak dihitung."*
* Slime melakukan animasi loncat 7-frame yang memantul kembali (*bounce-back*) dengan efek squash & stretch.
* Terdapat Cooldown Bar di atas tombol klik; klik baru hanya diproses setelah slime mendarat kembali di tanah.

### C. Toko Item Cepat & Sistem Cooldown (Makanan & Minuman)
Terletak melayang di sudut kanan atas layar dengan desain minimalis melengkung (*floating rounded cards*):
* **Makanan (Fruits):** Memberikan Coin Boost (+25% s/d +100%) selama durasi aktif.
* **Minuman (Drinks):** Mempercepat waktu loncat / Reduce Cooldown (-15% s/d -40%) selama durasi aktif.
* **Sistem Cooldown (Balanced Anti-Spam):** Setiap kali item dibeli, tombol langsung masuk ke masa Cooldown (hitung mundur detik). Selama masa cooldown, efek aktif dan item tidak dapat dibeli berulang kali secara instan. Setelah cooldown selesai, item siap dibeli kembali.

Tabel Keseimbangan Harga, Efek & Durasi Cooldown:

| Item | Tipe | Efek Aktif | Durasi & Cooldown | Harga | Target Progresi |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Stroberi** | Makanan | +25% Koin | 20 detik | 30 Koin | Awal Phase 1 (Level 5-15) |
| **Diet Coke** | Minuman | -15% Cooldown | 20 detik | 50 Koin | Awal Phase 1 (Level 10-20) |
| **Jeruk** | Makanan | +50% Koin | 25 detik | 200 Koin | Mid Phase 1 (Level 20-30) |
| **Mtn Dew** | Minuman | -25% Cooldown | 25 detik | 400 Koin | Transisi Phase 1 -> 2 |
| **Nanas** | Makanan | +100% Koin (2x) | 30 detik | 1.500 Koin | Phase 2 (Level 35-45) |
| **Monster** | Minuman | -40% Cooldown | 30 detik | 3.000 Koin | Phase 2 -> 3 (Level 50+) |

Format tampilan item:
`(Foto Item) -> Nama Item -> Fungsi -> Harga (atau Countdown sisa detik misal: "18s")`

### D. Rumus Matematis Progresi
* **Koin per klik dasar:**
  `Koin = max(level, round(1.10^(level - 1)))`
* **Biaya upgrade level:**
  `Biaya = round(10 * 1.12^(level - 1))`
* **Durasi loncat (kecepatan bertambah seiring level):**
  `Durasi = max(0.30, 0.97^(level - 1)) detik`

---

## 4. Sumber Aset (Audio & Visual)

### A. Sumber Efek Suara (Audio SFX - Freesound.org)
Semua aset audio pada game ini bersumber dari repositori domain publik **Freesound.org** dengan lisensi **Creative Commons 0 (CC0 Public Domain)**, kemudian diproses dan dioptimalkan ke format 16-bit PCM WAV Mono 44.1 kHz untuk performa audio latensi rendah:

1. **`sfx_click.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: Pop UI button click sound
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Memberikan respon instan (*tactile click*) saat tombol klik utama ditekan.

2. **`sfx_jump.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: Cartoon slime bounce / spring jump sweep
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Diputar saat Slime memulai loncatan ke udara.

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
   - Fungsi: Diputar saat pemain berpindah ke latar dan fase tempat baru.

6. **`sfx_boost.wav`**
   - Sumber: [Freesound.org](https://freesound.org/)
   - Deskripsi: 8-Bit laser charge power-up sound
   - Lisensi: Creative Commons 0 (CC0)
   - Fungsi: Diputar saat Combo Frenzy Boost 2X aktif.

### B. Sumber Visual & Tipografi
* **Font UI:** *Melon Squishy* (`Melon Squishy.otf`) untuk tipografi ramah dan kasual.
* **Latar Belakang:** 5 gambar latar resolusi tinggi bertema alam, hutan, dan gua kristal.
* **Karakter Slime:** Sprite animasi 2D frame-by-frame dengan alpha transparansi (Phase 1 Hijau dan Phase 2 Cokelat).
* **Ikon Item Toko:** Aset gambar PNG transparan untuk item makanan dan minuman.

---

## 5. Referensi Tutorial YouTube (Hackathon / Game Feel & Juice)

Berikut adalah daftar referensi video tutorial YouTube yang relevan dengan teknik implementasi game ini (terutama seputar Godot 4, Game Juice, Tween Pop Effect, dan Clicker Game):

1. **Godot 4 - In Depth Clicker Tutorial (Beginner & Intermediate)**
   - Link: https://www.youtube.com/watch?v=jQep5yqtvZ4
   - Relevansi: Membahas struktur scene clicker dasar, sistem data upgrade, dan manipulasi sprite button.

2. **Reusable Tweens - Godot 4 Game Juice Component (Squash & Stretch, Button Pop)**
   - Link: https://www.youtube.com/watch?v=CV_BQ-wCZ8s
   - Relevansi: Menjelaskan cara menerapkan efek "pop" menggunakan Godot 4 Tween (`TRANS_BACK`, `EASE_OUT`) serta teknik squash and stretch agar tombol terasa kenyal dan hidup.

3. **Make a Game JUICIER with Me and Godot 4**
   - Link: https://www.youtube.com/watch?v=LSfkme6m18M
   - Relevansi: Panduan menambahkan kepuasan visual (*game feel / juiciness*), seperti screen flash, partikel feedback, dan transisi halus saat pemain berinteraksi.

4. **How To Display Damage / Score Number Popups in Godot 4**
   - Link: https://www.youtube.com/watch?v=zGng3u9Y6dg
   - Relevansi: Tutorial membuat teks angka melayang (*floating text effect*) yang memantul dan memudar ke atas saat koin didapatkan.

---

## 6. Arsitektur Kode (Modular Scripts)

Proyek ini menggunakan pemisahan tanggung jawab 3 script agar kode tidak terlalu panjang dan mudah dipahami:

```text
haven-click-the-slime/
├── main.tscn                  # Scene utama (Node2D, CanvasLayer, AnimatedSprite2D, Audio)
├── main.gd                    # Game Coordinator: Menangani formula GDD, timer boost, level, belanja item & tween loncat
├── ui_manager.gd              # UI Controller: Menangani HUD card, Shop card, cooldown bar, tombol upgrade & combo meter
├── feedback_manager.gd        # Juiciness & Audio: Mengontrol playback audio SFX, partikel koin & screen flash
├── Melon Squishy.otf          # Font utama game
├── sfx_*.wav                  # Aset efek suara WAV
├── slime_transparent_*.png    # Aset animasi Slime Phase 1
├── slime_phase2_*.png         # Aset animasi Slime Phase 2
├── item_*.png                 # Aset gambar item toko (Makanan & Minuman)
└── Phase 1 (#1..#5).jpeg      # Aset latar 5 tempat (Background)
```

### Penjelasan Setiap Script:
1. **`main.gd` (Coordinator):**
   - Menyimpan state utama (koin, level, phase, combo, active item buffs).
   - Menghitung rumus eksponensial koin, biaya upgrade, dan durasi cooldown.
   - Mengatur tween loncat slime secara programmatic.
2. **`ui_manager.gd` (UI Controller):**
   - Mengatur tampilan teks HUD (level, koin, durasi loncat).
   - Mengatur tampilan tombol Upgrade / Pindah Tempat.
   - Mengontrol visual toko makanan dan minuman beserta label countdown cooldown.
3. **`feedback_manager.gd` (Game Feel / Juiciness):**
   - Memutar audio SFX yang tepat sesuai aksi pemain.
   - Menampilkan angka koin melayang (*floating coin numbers*).
   - Menjalankan efek squash-and-stretch pada tombol saat diklik.

---

## 7. Panduan Menambah Animasi Slime Sendiri

Script `main.gd` dirancang untuk **mendeteksi animasi baru secara otomatis**. Anda tidak perlu menulis ulang kode script untuk menambah fase berikutnya:

1. **Siapkan Gambar:** Simpan 5 file frame animasi slime baru (misal: `slime_phase3_1.png` s/d `slime_phase3_5.png`) ke dalam folder proyek.
2. **Buka SpriteFrames di Godot:**
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

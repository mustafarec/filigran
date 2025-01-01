# Proje: Flutter Filigran Ekleme Uygulaması

## 1. Amaç
Kullanıcıların bir resme logo ve metin içeren filigran eklemelerine ve bunu cihazlarına kaydetmelerine olanak tanıyan bir mobil uygulama geliştirmek.

---

## 2. Hedefler
- **MVP (Minimum Viable Product):**
  - [x] Kullanıcıdan resim seçme (galeri/kamera).
  - [x] Filigran olarak metin ve logo ekleme.
  - [ ] Filigran eklenmiş resmi cihazda kaydetme.
- **Geliştirilmiş Özellikler:**
  - [ ] Filigranın boyutunu ve konumunu sürükleyerek ayarlama.
  - [ ] Farklı yazı tipleri ve renk seçenekleri ekleme.

---

## 3. Teknolojiler ve Araçlar
- **Framework:** Flutter
- **Dil:** Dart
- **Kütüphaneler:** 
  - `image_picker` (resim seçme)
  - `custom_painter` (filigran oluşturma)
  - `permission_handler` (dosya izinleri)

---

## 4. Görevler

### Tamamlanan Görevler
- [x] Proje oluşturuldu ve temel yapı hazırlandı.
- [x] `image_picker` entegre edildi ve resim seçme işlevi eklendi.

### Devam Eden Görevler
- [ ] Filigranın metin ve logo olarak eklenmesi.
  - **Sorumlu:** [Geliştirici adı]
  - **Tahmini Süre:** 2 gün.

### Bekleyen Görevler
- [ ] Filigranlı resmin cihazda kaydedilmesi.
  - **Engel:** Depolama izinleri test edilmedi.

---

## 5. Zaman Çizelgesi

| Görev                     | Sorumlu       | Başlangıç   | Bitiş       | Durum   |
|---------------------------|---------------|-------------|-------------|---------|
| Resim seçme               | [Geliştirici] | [Tarih]     | [Tarih]     | Tamamlandı |
| Filigran ekleme           | [Geliştirici] | [Tarih]     | [Tarih]     | Devam ediyor |
| Resim kaydetme            | [Geliştirici] | [Tarih]     | [Tarih]     | Bekliyor |

---

## 6. Kaynaklar ve Referanslar
- [Flutter Documentation](https://flutter.dev)
- [ImagePicker Kütüphanesi](https://pub.dev/packages/image_picker)
- [CustomPainter Kullanımı](https://flutter.dev/docs/development/ui/advanced/custom-paint)

---

## 7. Notlar
- Uygulama iOS'ta izin yönetiminde sorun çıkarabilir, bu yüzden iOS testlerine öncelik verilmeli.
- Kullanıcı deneyimi için daha modern bir UI tasarımı düşünülüyor. 
# YonTugma 🖱

**Siçqonçaning yon tugmalari Mac'da ham işlasin.**

YonTugma — macOS uçun kiçik, bepul va oçiq kodli menyu-bar ilovasi. U siçqonçaning yon tugmalarini
Safari, Chrome, Finder va boşqa ilovalarda **Orqaga** (4-tugma) va **Oldinga** (5-tugma) vazifasiga aylantiradi.
Xohlasangiz, tugmalarga boşqa amallarni ham berasiz.

🌐 Veb sahifa: **https://alharitm.com/yontugma/**  
⬇️ Yuklab oliş: **[YonTugma.zip](https://github.com/Kinjobek/yontugma/releases/latest/download/YonTugma.zip)** (macOS 13+, Apple Silicon va Intel)

## Imkoniyatlar

- 4-tugma → Orqaga (⌘[), 5-tugma → Oldinga (⌘]) — odatiy sozlama
- Har bir tugmaga boşqa amal: Mission Control, iş stollari orasida ötiş, tablar, nusxa oliş/qöyiş va boşqalar
- Istalgan klaviatura birikmasini yozib olib, tugmaga biriktiriş
- Har bir ilova uçun alohida sozlama
- “Yaşirin” yon tugmalarni ham taniydi: baʼzi siçqonçalar (masalan, Xiaomi Mi Silent Mouse) ularni macOS körmaydigan tarzda yuboradi
- Bir bosişda yoqiş/öçiriş, kompyuter yonganda avtomatik işga tuşiş
- Internetga ulanmaydi, heç qanday maʼlumot yubormaydi; faqat Apple kutubxonalari işlatilgan

## Örnatiş

1. [YonTugma.zip](https://github.com/Kinjobek/yontugma/releases/latest/download/YonTugma.zip) ni yuklab oling, oçing va **YonTugma**'ni **Programmalar** (Applications) papkasiga torting.
2. Ikki marta bosib oçing. macOS ilovani töxtatsa: **Tizim sozlamalari → Maxfiylik va xavfsizlik** → pastdagi **«Baribir oçiş»** (Open Anyway).
3. **Tizim sozlamalari → Maxfiylik va xavfsizlik** bölimida YonTugma'ga ikkita ruxsat bering:
   - **Universal kiriş** (Accessibility)
   - **Kiritişni kuzatiş** (Input Monitoring)
4. 🖱 → «YonTugma'dan çiqiş», keyin ilovani qayta oçing. Menyuda ⚠️ yozuvlari qolmasa, hammasi tayyor.

Batafsil qöllanma: [QOLLANMA.md](QOLLANMA.md).

## Muammo bölsa

Yon tugmalar işlamay qolsa (ayniqsa yangilangandan keyin): ikkala ruxsat röyxatida YonTugma'ni «–» bilan öçiring,
«+» bilan qayta qöşing va ilovani qayta oçing. Siçqonça nima yuborayotganini 🖱 → «Tugmalarni sinaş…» oynasida köriş mumkin.

## Manba koddan yiğiş

Kerak böladi: Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/Kinjobek/yontugma.git
cd yontugma
bash build.sh
```

Natija: `YonTugma.app` (Apple Silicon + Intel uçun universal). Butun dastur bitta faylda — [`main.swift`](main.swift).

> Ilova Apple dasturçi sertifikatisiz (ad-hoc) imzolanadi. Şuning uçun har safar qayta yiğilganda
> macOS uni yangi ilova deb hisoblaydi va ruxsatlarni qaytadan beriş kerak böladi.

### Qanday işlaydi

- `CGEventTap` orqali 3/4/5-tugma bosilişini uşlaydi va tanlangan klaviatura buyruğini yuboradi.
- `IOHIDManager` orqali siçqonçaning xom hisobotlarini (raw HID reports) öqiydi. Agar siçqonçaning HID tavsifi
  tugmalarni kam eʼlon qilsa (masalan, “3 tugma” deb, lekin 5 bit yuborsa), ortiqça bitlarni 4/5-tugma sifatida taniydi.

## Litsenziya

[MIT](LICENSE) © 2026 Sarvarbek Nazarov — [ALHARITM](https://alharitm.com/)

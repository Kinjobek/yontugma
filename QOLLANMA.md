# YonTugma — qisqa qöllanma

YonTugma — menyu satrida (ekranning yuqori öng burçagida) 🖱 belgisi bilan turadigan kiçik ilova.
U siçqonçaning yon tugmalarini işlatadi: **4-tugma → Orqaga**, **5-tugma → Oldinga**.
Bu Safari, Chrome, Finder va ⌘[ / ⌘] ni tuşunadigan boşqa ilovalarda işlaydi.

> ℹ️ **Xiaomi Mi Silent Mouse** özini 3 tugmali deb körsatadi, lekin 4/5-tugmalarni "yaşirin" yuboradi.
> macOS ularni körmaydi, YonTugma esa ularni siçqonçadan töğridan-töğri öqiydi (buning uçun «Kiritişni kuzatiş» ruxsati kerak).

## 1. Örnatiş
1. [YonTugma.zip](https://github.com/Kinjobek/yontugma/releases/latest/download/YonTugma.zip) ni yuklab oling, oçing va
   `YonTugma.app` faylini **Programmalar** (Applications) papkasiga köçiring.
2. Uni ikki marta bosib oçing. Menyu satrida 🖱 belgisi paydo böladi.
   - Agar macOS ilovani töxtatsa: **Tizim sozlamalari → Maxfiylik va xavfsizlik** → pastdagi **«Baribir oçiş»** (Open Anyway).

## 2. Ruxsat beriş (faqat bir marta)
Siçqonça tugmalarini uşlaş uçun macOS **Accessibility** (Universal kiriş) ruxsatini talab qiladi.
Bu ruxsatni faqat siz özingiz bera olasiz:

1. Birinçi oçilganda YonTugma oyna körsatadi → **«Sozlamalarni oçiş»** tugmasini bosing.
2. **Tizim sozlamalari → Maxfiylik va xavfsizlik → Universal kiriş** (Accessibility) bölimi oçiladi.
3. Röyxatdan **YonTugma**'ni topib, yonidagi kalitni yoqing (parol yoki Touch ID söralişi mumkin).
4. Bir neça soniyada 🖱 belgisi töq rangga kiradi. Demak, ilova işlayapti.

5. Ikkinçi ruxsat — **Kiritişni kuzatiş** (Input Monitoring): Tizim sozlamalari → Maxfiylik va xavfsizlik →
   **Kiritişni kuzatiş** bölimida ham **YonTugma**'ni yoqing. Bu Xiaomi kabi siçqonçalar uçun kerak: ular
   yon tugmalarni "yaşirin" yuboradi va YonTugma ularni töğridan-töğri siçqonçadan öqiydi.
   Menyuda ⚠️ yozuvlari qolmagan bölsa, ikkala ruxsat ham berilgan.
6. **Muhim:** ruxsatlarni bergandan keyin 🖱 → «YonTugma'dan çiqiş» ni bosing va YonTugma'ni Programmalar
   papkasidan qayta oçing. «Kiritişni kuzatiş» ruxsati faqat qayta işga tuşirilgandan keyin kuçga kiradi.

Agar ilova keyinroq qayta yiğilsa (yangilansa), macOS uni yangi ilova deb hisoblaydi. U holda röyxatdagi
eski YonTugma'ni «–» bilan olib taşlang va ruxsatni qaytadan bering.

## 3. Amallarni özgartiriş
🖱 belgisini bosing:

| Menyu bandi | Nima qiladi |
|---|---|
| **Yoqilgan** | Hammasini bir bosişda yoqadi yoki öçiradi |
| **Barça ilovalar uçun → 4-tugma / 5-tugma / Ğildirak** | Tugmaga amal tanlaysiz: Orqaga, Oldinga, Mission Control, iş stollari orasida ötiş, tablar, nusxa oliş/qöyiş va boşqalar |
| **Faqat «…» uçun** | Hozir oçiq turgan ilova uçun alohida sozlama (masalan, Chrome'da 4-tugma = tabni yopiş) |
| **Boşqa tugmalar birikmasi…** | Istalgan klaviatura birikmasini bosib, tugmaga biriktirasiz |
| **Alohida sozlangan ilovalar** | Ilovaga xos sozlamani öçiriş |
| **Tugmalarni sinaş…** | Siçqonça qaysi tugma raqamini yuborayotganini körsatadi |
| **Kompyuter yonganda işga tuşiriş** | Mac yoqilganda YonTugma özi oçiladi |
| **Standart sozlamalarga qaytariş** | 4 = Orqaga, 5 = Oldinga holatiga qaytaradi |

«Iş stoliga ötiş» va «Ilova oynalari» amallari macOS'ning standart ⌃← / ⌃→ / ⌃↓ tugmalariga tayanadi.
Ular **Tizim sozlamalari → Klaviatura → Klaviatura qisqa tugmalari → Mission Control** bölimida yoqilgan bölişi kerak.

## 4. Öçirib taşlaş
1. 🖱 → **YonTugma'dan çiqiş**.
2. Agar yoqilgan bölsa: Tizim sozlamalari → Umumiy → **Login elementlari** bölimidan YonTugma'ni olib taşlang.
3. Tizim sozlamalari → Maxfiylik va xavfsizlik → **Universal kiriş** va **Kiritişni kuzatiş** röyxatlaridan YonTugma'ni «–» bilan öçiring.
4. Programmalar papkasidagi `YonTugma.app` ni Savatga taşlang.
5. (Ixtiyoriy) Sozlamalarni ham öçiriş uçun Terminal'da: `defaults delete uz.sarvarbek.yontugma`

## 5. Qayta yiğiş (dasturçilar uçun)
`main.swift` — ilovaning töliq kodi. Unda faqat Apple kutubxonalari bor. Yiğiş uçun: `bash build.sh`

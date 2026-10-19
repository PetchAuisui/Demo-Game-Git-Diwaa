# รายการและการใช้งานฟอนต์ในโปรเจกต์ (Fonts & Typography Guide)

เอกสารนี้รวบรวมรายการฟอนต์ทั้งหมดในโปรเจกต์ **Git-Diwaa** (`res://assets/fonts/`), มาตรฐานการจัดวางข้อความบทสนทนา (Cutscene Typography), และคู่มือการตั้งค่าใน Godot Engine

---

## 1. ฟอนต์หลักสำหรับฉากคัตซีนและบทสนทนา (Cutscene Dialogue Standard)

### ฟอนต์: `TA-8-bit.ttf`
* **ที่อยู่ไฟล์:** `res://assets/fonts/TA-8-bit.ttf`
* **ลักษณะ:** ฟอนต์พิกเซล 8-bit แท้ รองรับภาษาไทยและอังกฤษ มีเอกลักษณ์สไตล์ Retro Game ชัดเจน วรรณยุกต์และสระลงล็อกช่องพิกเซล
* **ฉากที่ใช้งาน:**
  * [`Scenes/cutscene/central_tower_cutscene.tscn`](file:///c:/Users/67030311/Documents/Game-Git-Diwaa/src/GitDiwaa.Godot/Scenes/cutscene/central_tower_cutscene.tscn) (หอคอยเวทกลาง)
  * `Scenes/cutscene/intro_cutscene.tscn` (ฉากเปิดเรื่อง)
  * `Scenes/cutscene/outside_cutscene.tscn` (ฉากนอกหอคอย)
  * `Scenes/cutscene/ending_cutscene.tscn` (ฉากจบ)

---

### ข้อกำหนดและสเปกการตั้งค่าในฉากหอคอยเวทกลาง (`central_tower_cutscene.tscn`)

| องค์ประกอบ | โหนด (Node) | ฟอนต์ | ขนาด (Size) | สีตัวอักษร (Color) | ขอบ (Outline) | ระยะห่างบรรทัด | รายละเอียดเพิ่มเติม |
|---|---|---|---|---|---|---|---|
| **ชื่อผู้พูด** | `SpeakerLabel` | `TA-8-bit.ttf` (FontVariation) | **28 px** | สีทอง `#F0D273` | 3 px (`#120D17`) | - | ใช้ `FontVariation` โดยตั้งค่า `variation_embolden = 0.3` เพื่อให้เป็นตัวหนา เด่นกว่าบทพูด |
| **บทสนทนา** | `DialogueLabel` | `TA-8-bit.ttf` (ปกติ) | **26 px** | สีขาวจั๊ว `#FFFFFF` | 2 px (`#120D17`) | **8 px** | ขนาด 26 px สระและวรรณยุกต์ไทยอ่านง่าย ไม่จม และไม่ตัดตกกล่อง |
| **เครื่องหมายคำถาม** | `QuestionMark/Label` | `TA-8-bit.ttf` | **20 px** | สีขาว `#FFFFFF` | 4 px (`#000000`) | - | ไอคอน emote แสดงเหนือศีรษะเวล |

#### กฎการตัดคำและช่องไฟบทสนทนา:
1. **ป้องกันคำเฉพาะตัดแยกบรรทัด:** ใช้ Non-breaking space (`\u00A0` หรือ `\u00A0`) ระหว่างคำเฉพาะ เช่น `'Git\u00A0Flow'` และ `'GitHub\u00A0Flow'` เพื่อไม่ให้คำว่า Flow หลุดไปอยู่เดี่ยวๆ ในบรรทัดใหม่
2. **การขึ้นบรรทัดใหม่ด้วยตนเอง (`\n`):** ใส่เครื่องหมาย `\n` แบ่งวรรคประโยคยาวที่มี 2 ใจความในบทที่ 3 และบทที่ 11 เพื่อให้อ่านสบายตา

---

### 1.1 มาตรฐานการแยกสีและขนาดชื่อตัวละคร (Character Nameplate Theming & Sizing Standard)

เพื่อช่วยให้ผู้เล่นสามารถแยกแยะผู้พูดได้ทันทีโดยไม่ต้องเพ่งอ่านชื่อตัวละคร ระบบบทสนทนาจะกำหนดชุดสีเฉพาะตามบทบาทตัวละคร (Role-Based Color Theming) และกำหนดขนาดตัวอักษรที่ชัดเจนให้กับ `SpeakerLabel`:

* **ขนาดและความหนาของตัวอักษรชื่อผู้พูด (Font Size 30 px, Embolden 0.6):** ปรับขนาดขึ้นเป็น **30 px** และเพิ่มความหนาตัวอักษรผ่าน `FontVariation (variation_embolden = 0.6)` (เพิ่มจากเดิม 0.3 ที่บางเกินไป) เพื่อสร้างลำดับชั้นทางสายตา (Visual Hierarchy) ให้ชื่อผู้พูดเป็นตัวหนาชัดเจน โดดเด่นกว่าข้อความบทสนทนาขนาด 26 px อย่างเป็นธรรมชาติ โดยคงขนาดและความหนาเท่ากันทุกตัวละคร (ไม่ปรับเฉพาะตัวเอก เพื่อป้องกันอาการกล่องข้อความหรือชื่อกระตุกเมื่อสลับบทพูด)

| บทบาทตัวละคร | ชื่อในเกม (ปัจจุบัน) | โทนสี | Hex Code | Godot Color Value | ความหมาย / เอกลักษณ์ |
|---|---|:---:|:---:|:---:|---|
| **ตัวละครหลัก / ผู้เล่น (Player Protagonist)** | **เวล (Vel)** *(ชื่อตั้งต้น/Placeholder)* | ฟ้าอ่อนสดใส (Sky Cyan) | `#7AC7FF` | `Color(0.48, 0.78, 1.0, 1.0)` | สีประจำตัวเอก/ผู้เล่น สอดคล้องกับฮู้ดคลุมสีฟ้า เมื่อเปิดฟีเจอร์ตั้งชื่อผู้เล่นเองในอนาคต ชื่อที่ผู้เล่นตั้งจะใช้สีฟ้าอ่อนนี้อัตโนมัติ |
| **ผู้ดูแลกิลด์ / ผู้สอน (Guild NPC)** | **มิวรา (Mewla)** | สีทองอบอุ่น (Warm Gold) | `#F0D273` | `Color(0.941, 0.824, 0.451, 1.0)` | สีทองหม่นประกายอบอุ่น สไตล์กิลด์หอคอยเวทมนตร์ |
| **ผู้พิทักษ์หอคอย (Tower Guardian)** | **ผู้พิทักษ์** | สีทองอบอุ่น (Warm Gold) | `#F0D273` | `Color(0.941, 0.824, 0.451, 1.0)` | สีทองหม่นของตัวละครสายเวทมนตร์และผู้สอน |

> [!NOTE]
> **การรองรับฟีเจอร์ตั้งชื่อผู้เล่นในอนาคต (Custom Player Name Support):**
> ปัจจุบันใช้ชื่อ **"เวล"** เป็นชื่อสมมติชั่วคราว (Placeholder Name) ประจำตัวละครหลัก ในอนาคตเมื่อมีระบบเปิดให้ผู้เล่นตั้งชื่อตนเอง ระบบไดอะล็อกจะดึงชื่อที่ผู้เล่นตั้งมาแทนที่ชื่อ "เวล" ทั้งหมด โดยยังคงใช้ **สีฟ้าอ่อน `#7AC7FF`** และขนาด **30 px** เป็นมาตรฐานประจำตัวละครหลักของผู้เล่นเสมอ

* **เส้นขอบ (Outline):** ใช้สีดำเข้ม (`#120D17` / `#000000`) หนา **3 px** เท่ากันทุกตัวละคร ช่วยให้ตัวอักษรคมชัด โดดเด่น และไม่กลืนกับพื้นหลังกรอบข้อความสีม่วงเข้ม

---

## 2. สรุปรายการฟอนต์ทั้งหมดในโปรเจกต์ (`res://assets/fonts/`)

| ชื่อไฟล์ | สไตล์ / ประเภท | รองรับภาษาไทย | นำไปใช้งานในส่วนไหน | หมายเหตุ |
|---|---|:---:|---|---|
| **`TA-8-bit.ttf`** | Pixel Art 8-bit | ✅ ใช่ | คัตซีนทุกฉาก (`central_tower`, `intro`, `outside`, `ending`) | **ฟอนต์หลักของบทสนทนาในเกม** คงความเป็นเกมพิกเซล 100% |
| **`ChakraPetch-Bold.ttf`**<br>**`ChakraPetch-SemiBold.ttf`**<br>**`ChakraPetch-Regular.ttf`** | Neo-grotesque / Sci-Fi สไตล์เรขาคณิต | ✅ ใช่ | UI หน้าแรก (`StartView.tscn`), TopBar (`StartTopBar.tscn`), ห้องแต่งตัว (`DressingRoomView.tscn`) | เหมาะกับปุ่มกด, หัวข้อ UI, ป้ายเมนู ที่ต้องการความชัดเจนอ่านเร็ว |
| **`PressStart2P-Regular.ttf`** | Arcade 8-bit Classic | ❌ อังกฤษเท่านั้น | `outside_cutscene.tscn` (ข้อความประกอบฉาก) | ฟอนต์ Arcade ยุค 80s แท้ นิยมใช้กับคะแนนหรือระบบเกมภาษาอังกฤษ |
| **`Silkscreen-Bold.ttf`**<br>**`Silkscreen-Regular.ttf`** | Pixel UI กะทัดรัด | ❌ อังกฤษเท่านั้น | `StartView.tscn`, `DressingRoomView.tscn` | ฟอนต์พิกเซลจิ๋วสำหรับป้ายสเตตัสและปุ่มตัวอักษรภาษาอังกฤษ |
| **`VT323-Regular.ttf`** | Monospace Terminal CRT | ❌ อังกฤษเท่านั้น | หน้าจอเมนู (`StartView.tscn`, `DressingRoomView.tscn`) | สไตล์จอคอมพิวเตอร์เทอร์มินัลยุคเก่า เหมาะกับโค้ดและคำสั่ง CLI |
| **`Charm-Bold.ttf`**<br>**`Charm-Regular.ttf`** | อักษรประดิษฐ์สไตล์มนต์ขลัง / แฟนตาซี | ✅ ใช่ | จัดเก็บไว้ในคลังฟอนต์ | ทรงตัวเขียนแฟนตาซี เหมาะกับหน้าคัมภีร์เวทมนตร์หรือจารึกโบราณ |
| **`2005.ttf`** | พิกเซลไทยทรงแคบ | ✅ ใช่ | จัดเก็บไว้ในคลังฟอนต์ (เคยนำมาทดสอบ) | อัตราส่วนความกว้างต่อความสูงแคบมาก (Glyph width ~5.8px ที่ 24px) จึงไม่เหมาะกับบทสนทนาหลัก |
| **`9Pradit-Regular.ttf`** | พิกเซลไทย 9 ประดิษฐ์ | ✅ ใช่ | จัดเก็บไว้ในคลังฟอนต์ (ทางเลือกเพิ่มเติม) | ฟอนต์พิกเซลไทยที่มีหัวชัดเจนสำหรับงานดีไซน์ทางเลือก |

---

## 3. วิธีการกำหนดฟอนต์ใน Godot (.tscn / GDScript / C#)

### การทำตัวหนาผ่าน `FontVariation` ใน Scene (`.tscn`)
หากต้องการให้ฟอนต์พิกเซลตัวเดิมดูเด่นเป็นตัวหนาสำหรับชื่อตัวละคร โดยไม่ต้องนำเข้าไฟล์ฟอนต์ใหม่ สามารถใช้ `FontVariation`:
```ini
[sub_resource type="FontVariation" id="FontVariation_speaker_bold"]
base_font = ExtResource("14_font") # TA-8-bit.ttf
variation_embolden = 0.3
```

### การตั้งค่าสีและ Outline ใน `Label`:
```ini
[node name="DialogueLabel" type="Label" parent="..."]
theme_override_fonts/font = ExtResource("14_font")
theme_override_font_sizes/font_size = 26
theme_override_colors/font_color = Color(1, 1, 1, 1) # สีขาวบริสุทธิ์
theme_override_colors/font_outline_color = Color(0.07, 0.05, 0.09, 1) # ขอบสีเข้มตัดพื้นหลัง
theme_override_constants/outline_size = 2
theme_override_constants/line_spacing = 8
autowrap_mode = 3
```

---

## 4. บันทึกการเปลี่ยนแปลง (Revision History)

* **2026-10-19:**
  * กำหนดมาตรฐานการแยกสีชื่อตัวละครตามบทบาท (Sky Cyan `#7AC7FF` สำหรับตัวเอก/ชื่อผู้เล่น, Warm Gold `#F0D273` สำหรับ NPC มิวรา)
  * ปรับขนาด `SpeakerLabel` เป็น **30 px** เพื่อสร้างลำดับชั้นทางสายตา (Visual Hierarchy) ให้เด่นชัดเหนือข้อความบทสนทนา (26 px) โดยคงขนาดเท่ากันทุกตัวละครเพื่อความเสถียรของ UI
* **2026-10-18:**
  * ยืนยันการใช้งานฟอนต์ [**`TA-8-bit.ttf`**](file:///c:/Users/67030311/Documents/Game-Git-Diwaa/src/GitDiwaa.Godot/assets/fonts/TA-8-bit.ttf) เป็นฟอนต์มาตรฐานของบทสนทนาในฉาก [`central_tower_cutscene.tscn`](file:///c:/Users/67030311/Documents/Game-Git-Diwaa/src/GitDiwaa.Godot/Scenes/cutscene/central_tower_cutscene.tscn)
  * ปรับขนาด `DialogueLabel` เป็น **26 px** และสีเป็น **สีขาวจั๊ว (`#FFFFFF`)** พร้อมขอบ 2 px และระยะห่างบรรทัด 8 px
  * ปรับขนาด `SpeakerLabel` เป็น **28 px** ใช้ `FontVariation (variation_embolden = 0.3)` สีทอง `#F0D273` ขอบ 3 px
  * สร้างเอกสาร [`docs/fonts.md`](file:///c:/Users/67030311/Documents/Game-Git-Diwaa/docs/fonts.md) เพื่อรวบรวมข้อมูลฟอนต์ทั้งหมดในโปรเจกต์

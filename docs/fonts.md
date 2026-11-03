# คู่มือการใช้งานฟอนต์และมาตรฐาน Typography (Fonts & Typography Guide)

เอกสารนี้รวบรวมมาตรฐานการใช้งานฟอนต์, ขนาด, สีตัวอักษร, และการตั้งค่า Typography ทั้งหมดในเกม **GIT DI WAA** (`res://assets/fonts/`) เพื่อให้เป็นมาตรฐานเดียวกันทั้งโปรเจกต์

---

## 1. ชื่อเกม (Game Title: "GIT DI WAA")

| ตำแหน่งการแสดงผล | ไฟล์ Scene | ฟอนต์ | ขนาด | สีตัวอักษร (Color) | การตกแต่ง / รายละเอียด |
|---|---|---|:---:|---|---|
| **แถบด้านบน (Top Bar)** | `start_top_bar.tscn`<br>`dressing_room_view.tscn` | `Bungee-Regular.ttf` | **32 px** | สีขาว `#FFFFFF` | เงาตัวอักษร `#2E3852` (Offset: 2, 2) |
| **ไตเติลคัตซีนเปิด/จบ** | `outside_cutscene.tscn`<br>`ending_cutscene.tscn` | `Bungee-Regular.ttf` | **72 px** | สีม่วงเวทมนตร์ `#B88CFA` | มีขอบ Outline นีออนเรืองแสง |

* **ข้อกำหนดการสะกด:** ใช้ตัวพิมพ์ใหญ่และเว้นวรรค **`GIT DI WAA`** (ไม่มีเครื่องหมายขีดกลาง)

---

## 2. ระบบบทสนทนาและคัตซีน (Dialogue & Cutscene System)

ใช้ในฉาก:
* `level_dialogue_view.tscn` (บทสนทนาในด่าน)
* `inside_tower_cutscene.tscn` (คัตซีนในหอคอย)
* `central_tower_cutscene.tscn` (คัตซีนหอคอยเวทกลาง)
* `ending_cutscene.tscn` (คัตซีนฉากจบ)

### 2.1 ข้อมูลจำเพาะในกล่องข้อความ (Dialogue Box Specifications)

| องค์ประกอบ | โหนด (Node) | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | Spacing / Line Spacing | หมายเหตุ |
|---|---|---|:---:|---|:---:|:---:|---|
| **ชื่อผู้พูด** | `SpeakerLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_speaker_bold`) | **26 px** | *แยกตามตัวละคร (ดูข้อ 2.2)* | ไม่มี (นำออก) | `spacing_top = 6`<br>`spacing_bottom = 2` | ป้องกันสระลอย/ตกขอบ และจัดกึ่งกลางสวยงาม |
| **เนื้อหาบทสนทนา** | `DialogueLabel` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_dialogue_reg`) | **23 px** | ขาวนวล `#E0E3EB`<br>`Color(0.88, 0.89, 0.92, 1.0)` | ไม่มี (นำออก) | `spacing_top = 8`<br>`spacing_bottom = 4`<br>`line_spacing = 10` | `clip_contents = false` อ่านง่าย สบายตา สระไม่ซ้อน |
| **ปุ่มตัวเลือกตอบ** | `ChoiceButton` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_choice_reg`) | **22 px** | ขาว / สว่างขาวตอน Hover | ไม่มี | `spacing_top = 4`<br>`spacing_bottom = 2` | ปุ่มเลือกตอบบทสนทนา (ใช้ตัวปกติให้อ่านง่าย สบายตา) |
| **ปุ่มข้ามคัตซีน** | `SkipCutsceneButton` | `ChakraPetch-Bold.ttf` | **16 px** | ขาวนวลโปร่งแสง | - | - | อยู่มุมขวาบนของคัตซีน |

---

### 2.2 โทนสีชื่อตัวละครผู้พูด (Speaker Color Palette)

ระบบกำหนดสีตามบทบาทของตัวละคร เพื่อให้ผู้เล่นแยกแยะผู้พูดได้ทันที:

| บทบาทตัวละคร | ตัวละครตัวอย่าง | โทนสี | Hex Code | Godot Color Value | ความหมาย / เอกลักษณ์ |
|---|---|:---:|:---:|:---:|---|
| **ตัวเอก / ผู้เล่น** | **เวล (Vel)** | ฟ้าอ่อนสดใส (Sky Cyan) | `#73BFF2` | `Color(0.45, 0.75, 0.95, 1.0)` | สอดคล้องกับธีมชุดฮู้ดสีฟ้าของตัวเอก |
| **ผู้ดูแล / ผู้สอน / NPC** | **มิวรา (Mewla)**<br>**ผู้พิทักษ์ (Guardian)**<br>**ปรมาจารย์ (Master)** | ทองอบอุ่น (Warm Gold) | `#EBCB70` | `Color(0.92, 0.80, 0.44, 1.0)` | สีทองอบอุ่น ประจำฝ่ายเวทมนตร์และผู้ชี้นำ |

---

## 3. หน้าจอหลักและห้องแต่งตัว (Start Screen & Dressing Room)

ไฟล์ Scene: `start_view.tscn`, `dressing_room_view.tscn`

| ส่วนประกอบ | โหนดตัวอย่าง | ฟอนต์ | ขนาด | สีตัวอักษร | สไตล์ / การใช้งาน |
|---|---|---|:---:|---|---|
| **ปุ่มเมนูหลัก 3 ปุ่ม** | `StartGameBtn`<br>`ResumeWorkBtn`<br>`QuitBtn` | `Bungee-Regular.ttf` | **18 px** | สีขาว `#FFFFFF` | ปุ่มกดตัวหนาสไตล์เรโทร ชัดเจน น่ากด |
| **หัวข้อหน้าต่าง / กรอบ** | `TitleText`<br>`WindowControls` | `TA-8-bit.ttf` | **16 px** | น้ำตาลอ่อน `#B89E80` | สไตล์หัวหน้าต่างคอมพิวเตอร์วินเทจ |
| **คำแนะนำปุ่มกด** | `NavHint` | `TA-8-bit.ttf` | **15 px** | น้ำตาลเข้ม `#594026` | คำแนะนำการกดคีย์บอร์ด `[↑ ↓] SELECT` |
| **หัวแท็บเทอร์มินัล & นาฬิกา** | `TerminalTag`<br>`ClockLabel` | `TA-8-bit.ttf` | **18 px** | เขียวเทอร์มินัล `#429173`<br>ทอง `#B08C57` | แถบแสดงสถานะด้านบนของหน้าต่างคำสั่ง |
| **ข้อความประวัติเทอร์มินัล** | `OutputLog` | `VT323-Regular.ttf` | **26 px** | เขียวนีออน CRT `#4FFA76` | ข้อความประวัติการรันคำสั่ง Git |
| **ช่องพิมพ์คำสั่งเทอร์มินัล** | `CommandInput`<br>`PromptChevron` | `VT323-Regular.ttf` | **26 px** | เขียวนีออน CRT `#4FFA76` | สไตล์หน้าจอคอมพิวเตอร์เรโทรยุค 80s |
| **แถบสถานะด้านล่าง** | `StatusText`<br>`BuildText` | `TA-8-bit.ttf` | **16 px** | น้ำตาลเทา `#8C6B4F` | แสดงเวอร์ชัน Build และการเชื่อมต่อ |

---

## 4. คลังฟอนต์ทั้งหมดในโปรเจกต์ (`res://assets/fonts/`)

| ชื่อไฟล์ฟอนต์ | ชนิดฟอนต์ | ภาษาไทย | จุดประสงค์การใช้งานหลัก |
|---|---|:---:|---|
| **`Bungee-Regular.ttf`** | Display Bold Rounded | ❌ อังกฤษ | **ชื่อเกม `GIT DI WAA`** และปุ่มเมนูหลักใน Start Screen |
| **`ChakraPetch-Bold.ttf`** | Sci-Fi / Modern Geometric (หนา) | ✅ ใช่ | **ชื่อผู้พูดในบทสนทนา (`SpeakerLabel`)** |
| **`ChakraPetch-Regular.ttf`** | Sci-Fi / Modern Geometric (ปกติ) | ✅ ใช่ | **เนื้อหาบทสนทนาในเกม (`DialogueLabel`)**, ปุ่มตัวเลือกตอบคำถาม (`ChoiceButton`) |
| **`TA-8-bit.ttf`** | Pixel Art 8-bit | ✅ ใช่ | หัวข้อหน้าต่าง, แถบสถานะ, ปุ่มกดนำทาง และส่วนประกอบพิกเซลเรโทร |
| **`VT323-Regular.ttf`** | Monospace Terminal CRT | ❌ อังกฤษ | กล่องข้อความและ Command Input ของระบบ Terminal |
| **`Mitr-Regular.ttf`**<br>**`Mitr-Medium.ttf`** | Sans-serif ทรงมนร่วมสมัย | ✅ ใช่ | ฟอนต์สำรองสำหรับระบบ UI ภาษาไทยในอนาคต |
| **`Silkscreen-Bold.ttf`**<br>**`Silkscreen-Regular.ttf`** | Micro Pixel UI | ❌ อังกฤษ | ป้ายสเตตัสพิกเซลจิ๋วภาษาอังกฤษ |
| **`PressStart2P-Regular.ttf`** | Arcade 8-bit Classic | ❌ อังกฤษ | ตัวเลขอาร์เคด / ข้อความย้อนยุค |

---

## 5. ตัวอย่างการตั้งค่า FontVariation ในโค้ด Godot (.tscn)

เพื่อป้องกันปัญหาสระลอยหรือหางตัวอักษรภาษาไทยโดนตัดขอบใน Godot Engine ให้ใช้ `FontVariation` ดังนี้:

```ini
[sub_resource type="FontVariation" id="FontVariation_speaker_bold"]
base_font = ExtResource("ChakraPetch-Bold")
spacing_top = 6
spacing_bottom = 2

[sub_resource type="FontVariation" id="FontVariation_dialogue_reg"]
base_font = ExtResource("ChakraPetch-Regular")
spacing_top = 8
spacing_bottom = 4
```

และการตั้งค่าบนโหนด `DialogueLabel`:
```ini
[node name="DialogueLabel" type="RichTextLabel" parent="..."]
clip_contents = false
theme_override_fonts/normal_font = SubResource("FontVariation_dialogue_reg")
theme_override_font_sizes/normal_font_size = 23
theme_override_colors/default_color = Color(0.88, 0.89, 0.92, 1)
theme_override_constants/line_separation = 10
autowrap_mode = 3
```

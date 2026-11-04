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
* `intro_cutscene.tscn` (คัตซีนเปิดเรื่องหอคอยเวท)
* `ending_cutscene.tscn` (คัตซีนฉากจบ)
* `outside_cutscene.tscn` (ฉากหน้าหอคอยก่อนเริ่มด่าน 1)
* `level_clear_modal.tscn` (หน้าต่างสรุปผลผ่านด่าน)
* `gameplay_placeholder_view.tscn` (หน้าจำลองเล่นเกมผ่านขั้น)
* `level_select_view.gd` (หน้าต่างเลือกด่าน 1 ถึง 15)

### 2.1 ข้อมูลจำเพาะในกล่องข้อความ (Dialogue Box Specifications)

| องค์ประกอบ | โหนด (Node) | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | Spacing / Line Spacing | หมายเหตุ |
|---|---|---|:---:|---|:---:|:---:|---|
| **ชื่อผู้พูด** | `SpeakerLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_speaker_bold`) | **26 px** | *แยกตามตัวละคร (ดูข้อ 2.2)* | ไม่มี (นำออก) | `spacing_top = 6`<br>`spacing_bottom = 2` | ป้องกันสระลอย/ตกขอบ และจัดกึ่งกลางสวยงาม |
| **เนื้อหาบทสนทนา** | `DialogueLabel` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_dialogue_reg`) | **23 px** | ขาวนวล `#E0E3EB`<br>`Color(0.88, 0.89, 0.92, 1.0)` | ไม่มี (นำออก) | `spacing_top = 8`<br>`spacing_bottom = 4`<br>`line_spacing = 10` | `clip_contents = false` อ่านง่าย สบายตา สระไม่ซ้อน |
| **ปุ่มตัวเลือกตอบ** | `ChoiceButton` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_choice_reg`) | **22 px** | ขาว / สว่างขาวตอน Hover | ไม่มี | `spacing_top = 4`<br>`spacing_bottom = 2` | ปุ่มเลือกตอบบทสนทนา (ใช้ตัวปกติให้อ่านง่าย สบายตา) |
| **ปุ่มข้ามคัตซีน** | `SkipCutsceneButton` | `ChakraPetch-Bold.ttf` | **16 px** | ขาวนวลโปร่งแสง | - | - | อยู่มุมขวาบนของคัตซีน |
| **ข้อความสรุปฉากจบ** | `SummaryLine1..3`<br>`bad_ending_line1..2` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **26 px** | ขาวบริสุทธิ์ `#FFFFFF`<br>`Color(1, 1, 1, 1)` | ไม่มี | `spacing_top = 4`<br>`spacing_bottom = 2` | จัดกึ่งกลางจอ พิมพ์ทีละตัวโดยตำแหน่งคงที่ ไม่สั่นไม่เลื่อน |
| **คลิกหน้าจอเพื่อไปต่อ / กลับสู่หน้าแรก** | `ContinuePrompt`<br>`bad_ending_btn` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **22 px** | ขาวนวล `#FAF9F6`<br>`Color(0.98, 0.98, 0.96, 0.95)` | ไม่มี | `spacing_top = 4`<br>`spacing_bottom = 2` | ข้อความกระพริบลอยด้านล่างจอ (Pulse Animation) |

---

### 2.2 โทนสีชื่อตัวละครผู้พูด (Speaker Color Palette)

ระบบกำหนดสีตามบทบาทของตัวละคร เพื่อให้ผู้เล่นแยกแยะผู้พูดได้ทันที:

| บทบาทตัวละคร | ตัวละครตัวอย่าง | โทนสี | Hex Code | Godot Color Value | ความหมาย / เอกลักษณ์ |
|---|---|:---:|:---:|:---:|---|
| **ตัวเอก / ผู้เล่น** | **เวล (Vel)** | ฟ้าอ่อนสดใส (Sky Cyan) | `#73BFF2` | `Color(0.45, 0.75, 0.95, 1.0)` | สอดคล้องกับธีมชุดฮู้ดสีฟ้าของตัวเอก |
| **ผู้ดูแล / ผู้สอน / NPC** | **มิวรา (Mewla)**<br>**ผู้พิทักษ์ (Guardian)**<br>**ปรมาจารย์ (Master)** | ทองอบอุ่น (Warm Gold) | `#EBCB70` | `Color(0.92, 0.80, 0.44, 1.0)` | สีทองอบอุ่น ประจำฝ่ายเวทมนตร์และผู้ชี้นำ |

---

### 2.3 ฉากจบและเครดิต (`ending_cutscene.tscn`)

| ส่วนประกอบ | โหนด (Node) | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | หมายเหตุ |
|---|---|---|:---:|---|:---:|---|
| **หัวข้อภาพย้อนอดีต** | `ComicTitle` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_speaker_bold`) | **24 px** | ทองสว่าง `#FFE680` | ไม่มี | `[ ภาพย้อนความทรงจำ ]` |
| **คำบรรยายภาพย้อนอดีต** | `ComicCaption` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_dialogue_reg`) | **22 px** | ขาวนวล `#FAF9F6` | ไม่มี | คำบรรยายเหตุการณ์ความโก๊ะของปรมาจารย์ |
| **คลิกเพื่อไปต่อ (คอมิก)** | `ComicContinuePrompt` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **22 px** | ขาวนวล `#FAF9F6` | ไม่มี | ลอยกระพริบด้านล่างจอ ตำแหน่งเดียวกับหน้าสรุปฉากจบ |
| **ข้อความสรุปฉากจบ** | `SummaryLine1..3` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **26 px** | ขาวบริสุทธิ์ `#FFFFFF` | ไม่มี | พิมพ์ทีละบรรทัด จัดกึ่งกลางจออย่างสมดุล |
| **คลิกเพื่อไปต่อ (หน้าจบ)** | `ContinuePrompt` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **22 px** | ขาวนวล `#FAF9F6` | ไม่มี | ลอยกระพริบด้านล่างจอ ก่อนเข้าสู่หน้าเครดิต |
| **หัวข้อเครดิต** | `ThankYouLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_speaker_bold`) | **32 px** | ขาวนวล `#FAF9F6` | ไม่มี | `Thank You for Playing` |
| **คำขอบคุณเครดิต** | `GratitudeLabel` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **24 px** | ขาวนวล `#FAF9F6` | ไม่มี | `ขอบคุณที่ร่วมเดินทางไปกับเรา` |
| **ชื่อตัวละครในเครดิต** | `NameLabel` (ทุกตัวละคร) | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_speaker_bold`) | **20 px** | ขาวนวล `#FAF9F6` | ไม่มี | ขนาดกะทัดรัด สบายตา อยู่เหนือสไปรต์ตัวละคร |
| **ทีมผู้พัฒนา** | `DevelopedByLabel` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **20 px** | ขาวโปร่งแสง (Alpha 0.9) | ไม่มี | `Developed by Git Di Waa Team` |
| **ปุ่มกลับสู่เมนูหลัก** | `ReturnMenuBtn` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_speaker_bold`) | **20 px** | ขาวนวล `#F5F5F5` | เส้นขอบ 2px คมชัด | ปุ่มกดกลับสู่เมนูหลักมุมขวาล่างของหน้าเครดิต |

---

### 2.4 ฉากเปิดเรื่องหอคอยเวท (`intro_cutscene.tscn`)

| ส่วนประกอบ | โหนด (Node) | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | หมายเหตุ |
|---|---|---|:---:|---|:---:|---|
| **ข้อความทำนายคัมภีร์** | `RuneRichLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_rune_bold`) | **30 px** | หมึกเวทมนตร์เข้ม `#24142E`<br>`Color(0.14, 0.08, 0.18, 1.0)` | ไม่มี (คมชัดแบบอักษรโบราณบนกระดาษ) | ตัดกับผิวกระดาษ คมชัดสะกดสายตา พร้อมเอฟเฟกต์คลื่น `[wave]` พริ้วไหว |
| **ออร่าเรืองแสงคัมภีร์** | `RuneAuraLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_rune_bold`) | **30 px** | ทองอบอุ่นโปร่งแสง | แสงเรืองทอง 6px, เงา 8px | เลเยอร์เรืองแสงกระพริบเบื้องหลังข้อความหลัก |
| **คลิกเพื่อไปต่อ** | `ContinuePrompt` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_summary_reg`) | **22 px** | ขาวนวล `#FAF9F6` | ไม่มี | ลอยกระพริบใต้แผ่นกระดาษบนฉากหลังมืด (ตำแหน่งเดียวกับฉากจบ) |

---

### 2.5 ฉากหน้าหอคอยก่อนเริ่มด่าน 1 (`outside_cutscene.tscn`)

| ส่วนประกอบ | โหนด (Node) | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | หมายเหตุ |
|---|---|---|:---:|---|:---:|---|
| **ชื่อบทคัตซีน** | `SubtitleLabel` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_sub_reg`) | **28 px** | ขาวประกายม่วงอ่อน `#F2EEFF` | ม่วงเข้ม 2px, เงา 2px | "― ตำนานแห่งหอคอยต้นกำเนิด ―" ตัวบางโปร่งสบายตา (Regular) ใต้ชื่อเกมหลัก |
| **คำแนะนำปุ่มกด** | `StartPrompt` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_prompt_reg`) | **22 px** | ขาวนวล `#FAF9F6` | ดำม่วง 3px | "คลิกหน้าจอเพื่อไปต่อ" กระพริบลอยด้านล่างจอ (Y = 970..1010) |

---

### 2.6 หมวดหน้าต่างสรุปผลและเกมเพลย์ (Gameplay & Modals)

#### 2.6.1 หน้าต่างสรุปผลผ่านด่าน (`level_clear_modal.tscn`)

| ส่วนประกอบ | โหนด (Node) | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | หมายเหตุ |
|---|---|---|:---:|---|:---:|---|
| **หัวข้อหน้าต่าง** | `TitleLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **20 px** | ขาวนวล `#F5F5F5` | ไม่มี | `Success` บน TitleBar |
| **หัวข้อด่าน** | `LevelTitle` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **30 px** | ดำสนิท `#1F1F1F` | ไม่มี | "ด่านที่ 1 : git version" เด่นชัดกึ่งกลางหน้าต่าง |
| **หัวข้อแถวสถิติ** | `Label` (Row 1..4) | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_modal_reg`) | **20 px** | เทาเข้ม `#333333` | ไม่มี | "คะแนนรอบนี้", "สถิติสูงสุดเดิม", "คะแนนสะสม", "รางวัลที่ได้รับ" |
| **ค่าคะแนนสถิติ** | `Value` (Row 1..4) | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **20 px** | ตามประเภทสถิติ | ไม่มี | ตัวเลขคะแนนหนาชัดเจน เช่น `100`, `70`, `+30`, `15 COINS` |
| **หัวข้อคีย์เวิร์ด** | `Header` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **20 px** | น้ำตาลทองเข้ม `#754705` | ไม่มี | `[คีย์เวิร์ดประจำด่านที่ 1]` |
| **เนื้อหาคีย์เวิร์ด** | `Body` | `ChakraPetch-Regular.ttf`<br>(SubResource: `FontVariation_modal_reg`) | **20 px** | น้ำตาลเข้ม `#402905` | ไม่มี | "การตรวจสอบพลัง หมายถึง git --version" อ่านง่าย สบายตา |
| **ปุ่มเล่นอีกครั้ง** | `BtnReplay` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **18 px** | ดำเทา `#2E2E2E` | ไม่มี | ไอคอนลูกศรหมุน `modal_replay.png` อยู่เหนือข้อความ "เล่นอีกครั้ง" (ขนาด 210×92px) |
| **ปุ่มกลับหน้าเลือกด่าน** | `BtnLevelSelect` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **18 px** | ดำเทา `#2E2E2E` | ไม่มี | ไอคอนรายการ `modal_level_select.png` อยู่เหนือข้อความ "กลับไปหน้าเลือกด่าน" (ขนาด 210×92px) |
| **ปุ่มด่านต่อไป** | `BtnNextLevel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **18 px** | น้ำตาลเข้ม `#1A0D05` | ไม่มี | ไอคอนข้ามด่าน `modal_next_level.png` อยู่เหนือข้อความ "ด่านต่อไป" โทนส้มทอง (ขนาด 210×92px) |

#### 2.6.2 หน้าจำลองเล่นเกม (`gameplay_placeholder_view.tscn`)

| ส่วนประกอบ | โหนด (Node) | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | หมายเหตุ |
|---|---|---|:---:|---|:---:|---|
| **หัวข้อภารกิจ** | `MissionTitleLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **28 px** | ทองสว่าง `#F0D273` | ดำ 3px | "ผ่านการสอนขั้น 1" / "ผ่านการสอนขั้น 2" |
| **ปุ่มเสร็จสิ้น** | `BtnFinish` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_modal_bold`) | **22 px** | ขาวนวล `#F2F2F2` | ไม่มี | "เสร็จสิ้น" กึ่งกลางปุ่มกว้าง 220px |

#### 2.6.3 หน้าต่างเลือกรวมด่าน (`level_select_view.tscn` / `level_select_view.gd`)

| ส่วนประกอบ | โหนด / โค้ด | ฟอนต์ / FontVariation | ขนาด | สีตัวอักษร | Outline | หมายเหตุ |
|---|---|---|:---:|---|:---:|---|
| **หัวข้อแถบหน้าต่าง** | `TitleLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_title_bold`) | **20 px** | ขาวนวล `#F5F5F5` | ไม่มี | `Level` บน TitleBar (เข้าคู่กับหน้าต่าง Modal) |
| **หัวข้อหลัก** | `SelectLevelLabel` | `ChakraPetch-Bold.ttf`<br>(SubResource: `FontVariation_title_bold`) | **32 px** | ดำเข้ม `#1F1F1F` | ไม่มี | `Select Level` กึ่งกลางเด่นชัด คมกริบสไตล์โมเดิร์น |
| **ชื่อการ์ดแต่ละด่าน** | `lbl_title` | `ChakraPetch-Bold.ttf`<br>(`FontVariation` spacing_top=4, bottom=2) | **22 px** | เขียวเข้ม `#0A380D` (ผ่านแล้ว)<br>เทาเข้ม `#383840` (ยังไม่ผ่าน) | ไม่มี | "ด่านที่ 1" ถึง "ด่านที่ 15" เด่นชัด สระไม่ตกขอบ |
| **ชื่อคำสั่งประจำด่าน** | `lbl_cmd` | `ChakraPetch-Regular.ttf`<br>(`FontVariation` spacing_top=4, bottom=2) | **16 px** | เขียว `#0F4214` (ผ่านแล้ว)<br>เทา `#52525C` (ยังไม่ผ่าน) | ไม่มี | เช่น `git version` จัดกึ่งกลางใต้หัวข้อด่าน |
| **ดาวผ่านด่าน** | `lbl_stars` | System Fallback Font | **18 px** | ทอง `#FACF19` | ไม่มี | `★ ★ ★` แสดงเฉพาะด่านที่ผ่านแล้ว |

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

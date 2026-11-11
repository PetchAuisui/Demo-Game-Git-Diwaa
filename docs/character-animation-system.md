# ระบบลำดับท่าทางตัวละคร (Character Animation & Gesture System)

เอกสารนี้อธิบายสถาปัตยกรรมการควบคุมท่าทางและแอนิเมชันของตัวละครในคัตซีน (เช่น เวล และ ผู้พิทักษ์) เพื่อให้การเคลื่อนไหวเป็นธรรมชาติ ไม่กระตุก และไม่รีสตาร์ทเฟรมใหม่ทุกครั้งที่ผู้เล่นคลิกเปลี่ยนบทสนทนา

---

## 1. ลำดับท่าทางวนลูป (Sequence Loop Patterns)

ตัวละครหลักในฉากจะใช้ระบบ **Animation Chaining via `animation_finished`** โดยร้อยเรียงคลิปแอนิเมชันขนาด 6 เฟรมต่อกันเป็นลูปตามที่กำหนดไว้:

### 1.1 ผู้พิทักษ์ (Guardian)
* **ขณะกำลังพูด (Speaking State):**
  ```text
  talk ➔ talk_blink ➔ talk ➔ talk ➔ talk_blink ➔ (วนกลับไป talk)
  ```
  - `talk`: ขยับปากพูดปกติ (`guardian-talk-Sheet.png`)
  - `talk_blink`: ขยับปากพูดพร้อมกระพริบตา (`guardian-talk-blink-Sheet.png`)

* **ขณะไม่ได้พูด / กำลังฟัง (Listening / Idle State):**
  ```text
  breathe ➔ breathe_blink ➔ breathe ➔ breathe ➔ breathe_blink ➔ (วนกลับไป breathe)
  ```
  - `breathe`: ท่ายืนหายใจลำตัวขยับเบาๆ (`guardian-breathe-Sheet.png`)
  - `breathe_blink`: หายใจพร้อมกระพริบตา (`guardian-breathe-bink-Sheet.png`)

### 1.2 เวล (Vel)
* **ท่าทางปกติ (Default Stance):**
  ```text
  breathe ➔ breathe_blink ➔ breathe ➔ breathe ➔ breathe_blink ➔ (วนกลับไป breathe)
  ```
  - `breathe`: ท่ายืนหายใจ (`vel_breathe-Sheet.png`)
  - `breathe_blink`: หายใจพร้อมกระพริบตา (`vel_breathe_blink-Sheet.png`)

> [!IMPORTANT]
> **การตั้งค่า Frame Duration และ Speed (ห้ามแก้ไขตัวเลขเด็ดขาด):**
> อนิเมชันทุกคลิปของตัวละครทั้งผู้พิทักษ์และเวลถูกกำหนดค่าความเร็วไว้ที่ **5.0 FPS** พร้อมทั้งจังหวะการค้างของแต่ละเฟรม (Frame Duration) ไว้อย่างเจาะจง:
> - เฟรม 0: `duration = 2.0` (x 2.0)
> - เฟรม 1: `duration = 1.0` (x 1.0)
> - เฟรม 2: `duration = 2.0` (x 2.0)
> - เฟรม 3: `duration = 1.0` (x 1.0)
> - เฟรม 4: `duration = 2.0` (x 2.0)
> - เฟรม 5: `duration = 1.0` (x 1.0)
> ตัวเลขเหล่านี้เป็นสเปกที่ผู้ใช้กำหนดไว้โดยตรงเพื่อจังหวะการเคลื่อนไหวที่ถูกต้อง ห้ามแก้ไขตัวเลขเหล่านี้เด็ดขาด

---

## 2. วิธีป้องกันไม่ให้ท่าทางรีสตาร์ทใหม่เมื่อคลิกบทสนทนา

### ปัญหาที่เกิดขึ้นในระบบทั่วไป:
เมื่อผู้เล่นคลิกเมาส์หรือกด Space เพื่อข้ามไปประโยคถัดไป ฟังก์ชัน `_show_current_dialogue()` จะถูกเรียก ถ้าเราสั่ง `character.play(...)` ซ้ำทุกครั้ง ตัวละครจะถูกบังคับให้เริ่มเล่นที่ **เฟรม 0 ใหม่ทันที** ส่งผลให้แอนิเมชันกระตุกและติดขัด

### วิธีการแก้ไข (State-Guarded Transition):
ระบบจะใช้การตรวจสอบสถานะของผู้พูดก่อนสั่งเล่นท่าทาง:

```gdscript
func _update_character_postures(speaker: String, custom_vel_anim: String = "") -> void:
    var should_guardian_speak = (speaker == "ผู้พิทักษ์")
    
    # ถ้าสถานะเดิมของผู้พิทักษ์ตรงกับประโยคปัจจุบันอยู่แล้ว (เช่น ผู้พิทักษ์พูดต่อเนื่องหลายประโยค)
    # จะ "ไม่ทำอะไรเลย" เพื่อให้ลำดับ talk -> talk_blink ดำเนินต่อไปอย่างราบรื่น
    if is_guardian_speaking != should_guardian_speak:
        is_guardian_speaking = should_guardian_speak
        guardian_seq_step = 0
        var seq = GUARDIAN_TALK_SEQ if is_guardian_speaking else GUARDIAN_IDLE_SEQ
        guardian.play(seq[0])

    # สำหรับเวล ถ้าไม่ได้กำหนดท่าทางพิเศษเจาะจง เวลจะอยู่ในลูปหายใจต่อเนื่องเสมอ
    # จะไม่มีการรีสตาร์ทเฟรม 0 เมื่อผู้เล่นคลิกเปลี่ยนบทสนทนา
```

---

## 3. การกำหนดไอคอนอารมณ์และท่าทางพิเศษ (Emote Icons & Custom Gestures)

> [!IMPORTANT]
> **ข้อตกลงในการพัฒนา:** ก่อนจะใส่ท่าทางพิเศษ (เช่น ตกใจ, โกรธ, ถอนหายใจ) หรือไอคอนแสดงอารมณ์ลงในบทสนทนาข้อใด ให้ปรึกษาและแจ้งให้ผู้ใช้ทราบก่อนเสมอ โดยค่าเริ่มต้นตัวละครจะเล่นลูป `breathe` และ `talk` เท่านั้น

### 3.1 ไอคอนอารมณ์และแอนิเมชันตกใจ (Emotion Emotes & Shock Jump Standards):
* **เครื่องหมายสงสัย `?` (`emote: "question"`):**
  - จัดวางบน Node2D ลอยอยู่เหนือศีรษะของเวลพอดี (`position: Vector2(0, -36)`)
  - ใช้ Font พิกเซล `TA-8-bit.ttf` (ขนาด 20px) ข้างในสีขาวสว่างชัดเจน (`#FFFFFF`) ครอบด้วยขอบสีดำคมเข้ม (`#000000`, outline_size = 4)
  - เด้งขึ้นมาด้วย Tween สไตล์ TRANS_BACK (0.22s) และลอยเด้งดึ๋งเบาๆ ขึ้นลงต่อเนื่อง (Idle Bobbing วนลูป ระหว่าง y = -39 ถึง -33) ค้างไว้ตลอดช่วงที่เวลพูดประโยคคำถามนี้
  - เมื่อผู้เล่นคลิกเปลี่ยนบทสนทนาไปยังประโยคถัดไป ไอคอนจะถูกซ่อนทันทีโดยอัตโนมัติ
* **เครื่องหมายตกใจ `!` (`emote: "exclamation"` — มาตรฐานในฉาก `inside_tower_cutscene` / `level_dialogue_view`):**
  - **ใช้ Font Text Label (ไม่ใช้ไฟล์รูปภาพ):** เขียนด้วยฟอนต์พิกเซล `TA-8-bit.ttf` **ขนาด 28px** ขอบดำหนา 5px ข้างในสีแดงนวล (`#EB5C5C` / `Color(0.92, 0.36, 0.36, 1.0)`) *(ส่วนฉากเฉพาะอย่าง `central_tower_cutscene` และ `ending_cutscene` ยังใช้รูป `exclamation_mark.png` บน `Sprite2D` และคีย์ `"exclamation"` ตามโครงสร้างเดิมของฉากนั้น)*
  - **แอนิเมชันกระโดดตกใจ (Shock Leap Jump Pattern):** 
    - เลียนแบบท่าปรมาจารย์พุ่งขึ้นจากหลุมในฉาก `ending-cutscene`
    - เวลเปลี่ยนเป็นหน้า `shock` พร้อมกระโดดลอยตัวขึ้นสู่จุดสูงสุด (`y: 680 -> 610` ใน 0.42s) และตัวอักษร `!` จะเด้ง Pop Bounce ขยายตัวและพุ่งลอยขึ้นตามเวลสู่ `y = -52`
    - จากนั้นทิ้งตัวตกลงสู่พื้น (`y: 610 -> 680` ใน 0.36s) พร้อมเงาใต้เท้า `DropShadow` หด/จางขณะลอยตัวและขยายกลับสู่ขนาดปกติเมื่อแลนดิ้ง
    - **เมื่อแลนดิ้งแตะพื้นปุ๊บ (No Lingering Shock):** ตัวอักษร `!` จะยุบตัวหายวับทันที (0.15s) และเวลจะสลับกลับคืนสู่ท่ายืนหายใจปกติ (`breathe`) ทันทีโดยไม่ตกใจค้าง
    - เว้นช่วงพักหายใจ 0.65s ให้เวลตั้งสติก่อนเปิดกล่องข้อความ

### 3.2 ตัวอย่างการกำหนดในสคริปต์ (`DIALOGUES`):
```gdscript
{
    "speaker": "เวล",
    "text": "GitHub Flow?",
    "emote": "question"           # แสดงเครื่องหมาย ? เหนือศีรษะแบบเด้งดึ๋ง
}
```

หากประโยคถัดไปไม่มี `emote` ไอคอนจะถูกซ่อนทันทีโดยอัตโนมัติ

---

## 4. ตารางคลังท่าทางที่มีในโปรเจกต์ (Available Sprite Assets)

### ผู้พิทักษ์ (`assets/cutscene/characters/guardian/`):
| ท่าทาง (Animation Name) | ไฟล์ Asset | จำนวนเฟรม | คำอธิบาย |
|---|---|:---:|---|
| `breathe` | `guardian-breathe-Sheet.png` | 6 | หายใจขยับลำตัว |
| `breathe_blink` | `guardian-breathe-bink-Sheet.png` | 6 | หายใจและกระพริบตา |
| `talk` | `guardian-talk-Sheet.png` | 6 | พูดขยับปาก |
| `talk_blink` | `guardian-talk-blink-Sheet.png` | 6 | พูดพร้อมกระพริบตา |
| `idle` | `guardian-idle.png` | 1 | ท่ายืนนิ่งเฟรมเดี่ยว |
| `walk` | `guardian-walk.png` / `guardian-walk-side-Sheet.png` | 6 | ท่าเดิน |

### เวล (`assets/cutscene/characters/vel/`):
| ท่าทาง (Animation Name) | ไฟล์ Asset | จำนวนเฟรม | คำอธิบาย |
|---|---|:---:|---|
| `breathe` | `vel_breathe-Sheet.png` | 6 | หายใจขยับลำตัว |
| `breathe_blink` | `vel_breathe_blink-Sheet.png` | 6 | หายใจและกระพริบตา |
| `walk` | `vel_walk_right-Sheet.png` | 6 | เดินไปทางขวา |
| `shock` | `vel_shockpng.png` | 1 | ท่าตกใจ ตาโต อ้าปาก |
| `sigh` | `vel_sigh_bink-Sheet.png` | 6 | ถอนหายใจ |
| `angry` | `vel_angry.png` | 1 | ท่าโกรธ |
| `cry` | `vel_cry.png` | 1 | ท่าร้องไห้/เสียใจ |
| `love` | `vel_love.png` | 1 | ท่าดีใจ/มีความสุข |

---

## 5. มาตรฐานตำแหน่งการยืนในฉากสนทนาทั่วไป (Conversation Scene Positioning Standard)

สำหรับฉากสนทนาระหว่างตัวละครในมุมมอง 1920×1080 (เช่น `level_dialogue_view.tscn` และ `inside_tower_cutscene.tscn` ที่ตั้งค่าจุดยืนตัวละคร `y = 680`–`700`):
* **การสมมาตร (X-Axis):** วางตัวละครห่างจากจุดกึ่งกลาง (x = 960) ฝั่งละ 260px (เวล: `x = 700`, ผู้สนทนาฝั่งขวา: `x = 1220`)
* **การยึดติดพื้น (Y-Axis & Grounding):** Sprite ตัวละครขนาด 48×83 (สเกล 4x) กำหนดระดับจุดศูนย์กลางที่ `y = 700` (หรือ `y = 680` ใน `level_dialogue_view` / `inside_tower_cutscene`) เพื่อให้ปลายเท้าอยู่เหนือกล่องข้อความ พร้อมใส่โหนดเงา `DropShadow` (`res://assets/cutscene/props/khampri/drop_shadow.png`) ใต้เท้า
* **ระยะปลอดกล่องข้อความ (Dialogue Clearance):** กล่องข้อความด้านล่างควรอยู่ใต้ปลายเท้าของตัวละคร (มาตรฐานเอกสารอ้างอิงที่ `y = 880` หรือ `y = 864` เมื่อตัวละครยืนที่ `y = 680`) เพื่อให้แสดงผลตัวละครครบถ้วน 100% เหนือกล่องข้อความ
* *(หมายเหตุ: มาตรฐานนี้ใช้กับฉากสนทนาทั่วไปและด่านใน `level_dialogue_view` โดยไม่นำไปแก้ไขฉากเฉพาะเดิมอย่าง `intro_cutscene`, `central_tower_cutscene` [ดูค่าเฉพาะที่ `central-tower-cutscene.md`](central-tower-cutscene.md) หรือ `ending_cutscene`)*

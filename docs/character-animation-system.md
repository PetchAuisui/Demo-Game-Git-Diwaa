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

### 3.1 ไอคอนอารมณ์ (Emotion Emote Icons):
* **เครื่องหมายสงสัย `?` (`emote: "question"`):**
  - ใช้ Font พิกเซล `TA-8-bit.ttf` (ขนาด 20px) ข้างในสีขาวสว่างชัดเจน (`#FFFFFF`) ครอบด้วยขอบสีดำคมเข้ม (`#000000`, outline_size = 4)
  - เด้งขึ้นมาด้วย Tween สไตล์ TRANS_BACK (0.3s) ค้างไว้ให้อ่านข้อความทันอย่างพอดีคำ (~1.6s) แล้วค่อยๆ ลอยขึ้นและจางหายไปอย่างนุ่มนวล (0.4s) โดยจะถูกซ่อนทันทีเมื่อผู้เล่นคลิกเปลี่ยนบทสนทนา
* **เครื่องหมายตกใจ `!` (`emote: "exclamation"`):**
  - ใช้ Sprite พิกเซล `exclamation_mark.png` เด้งขึ้นมาด้วยจังหวะเดียวกัน

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

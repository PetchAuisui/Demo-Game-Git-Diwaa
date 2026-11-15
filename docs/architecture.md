# สถาปัตยกรรมเชิงแนวคิดระบบ Git (System Conceptual Architecture)

เอกสารฉบับนี้อธิบายแนวคิดการออกแบบสถาปัตยกรรม (Conceptual Architecture) ของระบบจำลองการทำงาน Git ในเกม Git-Diwaa โดยเน้นหลักการออกแบบ ความปลอดภัย และการไหลของข้อมูลระหว่างระบบ

---

## 1. ที่มาและปรัชญาของแนวคิด (Design Philosophy)

### ปัญหาของการเรียนรู้ Git ทั่วไป
* **การจำลองด้วย Hardcode / Mockup:** ผู้เรียนไม่ได้สัมผัสข้อความ Error, Warning หรือพฤติกรรม Corner Case ที่เกิดขึ้นจริงบน Git
* **ความเสี่ยงหากใช้ Git ของระบบโดยตรง:** อาจเผลอลบไฟล์ระบบ, กระทบ `.git` ของโปรเจกต์จริง หรือเปิดช่องโหว่ความปลอดภัย (เช่น Command Injection)

### แนวคิดการแก้ไขปัญหาของ Git-Diwaa
ออกแบบระบบสถาปัตยกรรมแบบ **"Real Git in a Controlled Sandbox"** โดยให้มีตัวกลางทำหน้าที่ควบคุม ตรวจสอบ และตัดขาดสภาพแวดล้อมออกจากระบบปฏิบัติการภายนอก

---

## 2. โครงสร้างสถาปัตยกรรมเชิงแนวคิด (Conceptual Architecture)

ระบบแบ่งออกเป็น 4 ขอบเขตแนวคิด (Conceptual Boundaries) ดังแผนภาพ:

```mermaid
flowchart TD
    subgraph Boundary_Presentation["1. Presentation Boundary (ส่วนปฏิสัมพันธ์ผู้เล่น)"]
        UI_Input["User Actions & CLI Commands\n(การพิมพ์คำสั่ง / ปฏิสัมพันธ์กับไฟล์)"]
        UI_Display["State Visualization\n(การแสดงผล Terminal, กราฟ Commit และสถานะไฟล์)"]
    end

    subgraph Boundary_Core["2. Control & Security Boundary (ตัวกลางควบคุม)"]
        Policy["Command Policy & Sanitization\n(ตรวจสอบ Whitelist, Flag และป้องกัน Injection)"]
        SessionMgr["Session Management\n(จัดการรอบการเล่นและ Lifecycle ของ Sandbox)"]
        Inspector["State Inspector\n(สกัดสถานะ Git และสร้าง Typed Snapshot)"]
        Runner["Process Runner\n(เรียกใช้งาน Git CLI จริงโดยไม่ผ่าน Shell)"]
    end

    subgraph Boundary_Sandbox["3. Sandbox Storage Boundary (พื้นที่ปิดเสมือนจริง)"]
        Workspace["Player Working Tree\n(พื้นที่จัดเก็บไฟล์จำลองสำหรับผู้เล่น)"]
        BareRemote["Simulated Bare Remote\n(จำลอง Remote Repository โดยไม่ต้องต่อเน็ต)"]
        SafeEnv["Sandboxed Environment\n(ตัดขาด Git Config และปิด Hooks ทั้งหมด)"]
    end

    UI_Input -->|"1. Command Line"| Policy
    Policy -->|"2. Validated Arguments"| Runner
    SessionMgr -->|"เตรียมพื้นที่"| Sandbox_Boundary
    Runner -->|"3. Execute CLI"| Workspace
    Runner -.->|"4. Push / Fetch / Clone"| BareRemote
    Workspace -->|"5. Raw Git State"| Inspector
    Inspector -->|"6. State Snapshot"| UI_Display
```

---

## 3. แนวคิดการไหลของข้อมูล (Conceptual Data Flow)

การประมวลผลคำสั่งในระบบจะเดินทางผ่านวงจรชีวิตที่เป็นลำดับขั้นเพื่อรับรองความปลอดภัย:

```mermaid
sequenceDiagram
    autonumber
    actor Player as ผู้เล่น (Player / UI)
    participant Policy as Security & Policy Layer
    participant Engine as Real Git Engine
    participant Sandbox as Isolated Sandbox
    participant Inspector as State Inspector

    Player->>Policy: ส่งข้อความคำสั่ง (Input String)
    Note over Policy: ตัดแบ่ง Token & ตรวจสอบความปลอดภัย
    
    alt คำสั่งไม่ปลอดภัย หรือไม่อยู่ในขอบเขตบทเรียน
        Policy-->>Player: ปฏิเสธคำสั่ง (Reject with Safety Warning)
    else คำสั่งผ่านการตรวจสอบ
        Policy->>Engine: ส่ง Argument List ที่ปลอดภัย
        Engine->>Sandbox: รันคำสั่งบน Git CLI จริงใน Workspace
        Sandbox-->>Engine: คืนค่า stdout, stderr, exit code
        
        Engine->>Inspector: สั่งตรวจสอบสถานะล่าสุด (Inspect Trigger)
        Inspector->>Sandbox: ดึงข้อมูล branch, graph, status ปัจจุบัน
        Sandbox-->>Inspector: Raw Metadata
        Inspector-->>Player: ส่ง Snapshot สำหรับอัปเดตหน้าจอและการแสดงผล
    end
```

---

## 4. แนวคิดโมเดลความปลอดภัยของ Sandbox (Sandbox Security Concept)

```mermaid
flowchart LR
    subgraph Host_System["ระบบปฏิบัติการหลัก (Host OS)"]
        Host_FS["ไฟล์ส่วนตัวของผู้ใช้ (~ / Documents / Projects)"]
        Host_Config["การตั้งค่า Git ประจำเครื่อง (~/.gitconfig)"]
        
        subgraph Safe_Zone["พื้นที่ปลอดภัย (Sandbox Isolation)"]
            Session_FS["Isolated Workspace (/tmp/session_id/workspace)"]
            Isolated_Config["Sandboxed Config (core.hooksPath = /dev/null)"]
            Bare_Repo["Local Bare Remote (/tmp/session_id/remote.git)"]
        end
    end

    Git_Engine["Real Git Engine"] -->|"ทำงานได้เฉพาะในพื้นที่นี้"| Safe_Zone
    Git_Engine x--x|"ห้ามเข้าถึงเด็ดขาด (Blocked)"| Host_FS
    Git_Engine x--x|"ตัดขาดจากการตั้งค่าจริง"| Host_Config
```

### เสาหลักความปลอดภัย (Core Security Pillars):
1. **Non-Shell Invocation:** สั่งการ process ตรงไปยัง executable `git` โดยไม่ใช้ command shell (`sh`, `bash`, `cmd`) ทำให้ไม่สามารถฝังคำสั่งพ่วง (Command Chaining เช่น `;`, `&&`, `|`) ได้
2. **Directory Jail:** ตรวจสอบ Argument ทุกตัว ห้ามใช้ parameter ที่อ้างอิงเส้นทางออกนอก workspace (เช่น `../` หรือ absolute path)
3. **Zero Configuration Leak:** บังคับให้ Git มองเห็นเฉพาะ config ชั่วคราวที่สร้างขึ้นใหม่ และปิดระบบ Git Hook ทั้งหมดเพื่อป้องกันการรัน Script ที่ไม่พึงประสงค์
4. **Networkless Remote Simulation:** จำลอง Remote ด้วย Local Bare Repository ภายในเครื่อง ทำให้ไม่ต้องเปิดพอร์ตหรือเชื่อมต่ออินเทอร์เน็ต

---

## 5. แนวคิดการแปลงสถานะ (State Snapshot Concept)

การแสดงผลในเกมจะไม่พึ่งพาการอ่าน stdout ของคำสั่ง Git โดยตรง เพราะข้อความ CLI ออกแบบมาให้อ่านด้วยตามนุษย์ ไม่เหมาะกับการนำไปประมวลผลต่อ

ระบบจึงใช้แนวคิด **State Extraction**:
* หลังจากการรันคำสั่งสำเร็จ ระบบจะสั่งคำสั่งตรวจสอบแบบเจาะจง (เช่น `git status --porcelain`, `git log --format=...`)
* นำข้อมูลดิบมาประกอบเป็น **Snapshot Data Structure**:
  * โครงสร้างกิ่ง (Branches) และจุดที่ HEAD ชี้อยู่
  * สถานะไฟล์ (Untracked, Modified, Staged)
  * โหนดของ Commit Tree สำหรับนำไปสร้างภาพกราฟิก

แนวคิดนี้ทำให้ส่วนติดต่อผู้ใช้ (UI) สามารถเปลี่ยนแปลงหรือพัฒนาใหม่ได้อิสระ โดยไม่ต้องแก้ไขตรรกะของระบบ Git ด้านหลัง

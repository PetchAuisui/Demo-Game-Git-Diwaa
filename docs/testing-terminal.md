# ทดสอบ Real Git ผ่าน Terminal

## เริ่มโปรแกรม

```sh
dotnet run --project src/GitDiwaa.Cli/GitDiwaa.Cli.csproj
```

โปรแกรมสร้าง attempt ใหม่ทุกครั้ง พร้อมโครงสร้างดังนี้:

```text
<workspace>/<mission>/<attempt>/
├── player-repo/       repository ที่ผู้เล่นใช้งาน
├── remotes/origin.git local bare remote
├── config/gitconfig   global config เฉพาะ attempt
└── disabled-hooks/    hooks path ว่าง
```

path ที่แสดงหลังเปิดโปรแกรมคือ repository ของผู้เล่น ไม่ใช่ repository source code ของเกม

## รอบทดลองพื้นฐาน

พิมพ์ทีละบรรทัดในโปรแกรม:

```text
git --version
git config --global user.name "Player One"
git config --global user.email player@git-diwaa.local
git init
write README.md Hello Git-Diwaa
git status
git add README.md
git commit -m "initial commit"
git log --graph --all --oneline --decorate
snapshot
```

`snapshot` แสดง JSON ที่ประกอบด้วย current branch, file status, branches และ commit nodes ซึ่ง Godot สามารถนำไปสร้าง panel/graph ได้โดยไม่ parse output ของ `git log` เอง

## รอบทดลอง Branch และ Merge

```text
git switch -c feature/demo
write feature.txt Feature work
git add feature.txt
git commit -m "feature work"
git switch main
git merge --no-ff feature/demo
graph
snapshot
```

## รอบทดลอง Local Remote

ใช้ `remote-url` เพื่ออ่าน URL ของ local bare remote ใน attempt ปัจจุบัน แล้วแทนค่าในคำสั่ง:

```text
remote-url
git remote add origin https://git-diwaa.local/origin.git
git push -u origin main
git fetch origin
git pull
```

URL รูปแบบ `https://git-diwaa.local/...` เป็น alias ภายในเกม ไม่เรียกเครือข่ายจริง และ output จะไม่เปิดเผย path ของ bare repository ภายใน

## คำสั่ง Git ที่เปิดใช้

- ตรวจ/ตั้งค่า: `--version`, `config --global user.name`, `config --global user.email`, `init`
- ติดตามงาน: `status`, `add`, `commit`, `diff`, `restore`, `reset`
- ประวัติ/branch: `log`, `branch`, `switch`, `merge`
- remote: `clone`, `remote`, `fetch`, `pull`, `pull --rebase`, `push`

แต่ละคำสั่งรับเฉพาะ options ที่ใช้ในบทเรียน ไม่ได้เปิดความสามารถ Git ทุกแบบ

## คำสั่งช่วยของ Terminal

- `write <path> <text>` เขียนไฟล์ใน working tree
- `cat <path>` อ่านไฟล์
- `delete <path>` ลบไฟล์
- `files` แสดงไฟล์โดยไม่รวม `.git`
- `snapshot` แสดง typed repository state เป็น JSON
- `graph` เรียก log graph แบบย่อ
- `where` แสดง player repository
- `remote-url` แสดง local remote alias
- `clear`, `help`, `exit`

## ข้อจำกัดด้านความปลอดภัย

- command ต้องขึ้นต้นด้วย `git` และผ่าน allowlist
- ไม่เรียกผ่าน shell
- ห้ามเปลี่ยน working directory, git directory, executable หรือ config/hook path
- file API ห้ามออกนอก working tree, แตะ `.git` หรือวิ่งผ่าน symbolic link
- remote ภายนอกและ credential prompt ถูกปิด
- `reset --hard` และ force push ใช้ได้เพื่อการเรียน แต่กระทบเฉพาะ sandbox ของ attempt


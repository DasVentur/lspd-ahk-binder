#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir

; =====================================================================
; Всі бінди редагуються в Binds.txt (файл поруч зі скриптом).
; Цей файл (BinderReplacer.ahk) чіпати не треба - тут тільки логіка.
; Якщо не спрацьовує відправка клавіш в грі - зміни SendMode вище
; на "Event" (рядок 3): SendMode "Event"
; =====================================================================

BindsFile := A_ScriptDir "\Binds.txt"

if !FileExist(BindsFile) {
    try {
        FileAppend(DefaultBindsTemplate(), BindsFile, "UTF-8")
    } catch as e {
        MsgBox("Не вдалося створити Binds.txt: " e.Message)
        ExitApp()
    }
    MsgBox("Файл Binds.txt не знайдено - створив новий з прикладами поруч зі скриптом.`n`nВідкрий його, онови бінди під себе і збережи файл. Потім або перезапусти програму, або обери в треї 'Перезавантажити бінди'.")
}

binds := ParseBinds(BindsFile)
lastUsed := Map()
imageGuis := Map()
suspendLabel := "⏹️ Призупинити роботу"

if (binds.Length = 0) {
    MsgBox("У Binds.txt не знайдено жодного валідного бінда. Перевір формат.")
    ExitApp()
}

; --- Кастомне трей-меню замість стандартного англійського ---
A_TrayMenu.Delete()
A_TrayMenu.Add(suspendLabel, ToggleSuspend)
A_TrayMenu.Add()
A_TrayMenu.Add("🔃 Перезавантажити бінди", ReloadBinds)
A_TrayMenu.Add("❌ Закрити біндер", (*) => ExitApp())
A_TrayMenu.Add()
A_TrayMenu.Add("by @dasventur (Discord)", (*) => "")
A_TrayMenu.Disable("by @dasventur (Discord)")

ToggleSuspend(*) {
    global suspendLabel
    Suspend(-1)
    newLabel := A_IsSuspended ? "▶️ Відновити роботу" : "⏹️ Призупинити роботу"
    A_TrayMenu.Rename(suspendLabel, newLabel)
    suspendLabel := newLabel
}

for b in binds {
    if (b.type = "action")
        Hotkey(b.key, RegisterActionHandler(b))
    else if (b.type = "image")
        Hotkey(b.key, RegisterImageHandler(b))
}

RegisterActionHandler(b) {
    return (*) => RunActionBind(b)
}

RegisterImageHandler(b) {
    return (*) => ToggleImageBind(b)
}

; --- Esc закриває всі відкриті картинки одразу ---
Esc:: {
    global imageGuis
    for k, g in imageGuis {
        try g.Destroy()
    }
    imageGuis.Clear()
}

ReloadBinds(*) {
    global imageGuis
    for k, g in imageGuis {
        try g.Destroy()
    }
    imageGuis.Clear()

    Loop Files, A_ScriptDir "\cache_*.png" {
        try FileDelete(A_LoopFileFullPath)
    }

    Reload()
}

; =====================================================================
;                    ШАБЛОН Binds.txt ЗА ЗАМОВЧУВАННЯМ
; =====================================================================
DefaultBindsTemplate() {
    return "
    (
; ============================================================
;  КОНФІГ БІНДІВ
; ============================================================
; Назви клавіш бери ЗВІДСИ (офіційний список AutoHotkey),
; щоб не помилитись з написанням:
; https://www.autohotkey.com/docs/v2/KeyList.htm
;
; Приклади валідних назв: F1, F2, Enter, Tab, Escape, T, U, Y,
; LButton, RButton, Numpad1, Insert, Home, End, і т.д.
;
; ------------------------------------------------------------
;  БІНД-ДІЯ (послідовність кроків, скільки завгодно і в будь-якому порядку)
; ------------------------------------------------------------
; [клавіша активації]
; (кд в мс)              <- необов'язково, за замовч. 1000
; KEY назва_клавіші       <- скрипт САМ натискає цю клавішу
; TEXT "текст"            <- скрипт вставляє текст (Ctrl+V)
; WAIT мілісекунди        <- пауза між кроками
;
; Простий приклад (клавіша -> текст):
;
; [F1]
; (2000)
; KEY T
; TEXT "/me дістає посвідчення LSPD"
;
; Складний приклад (клавіша, текст, клавіша, пауза, клавіша, текст, клавіша):
;
; [F7]
; (3000)
; KEY Enter
; TEXT "/me арештовує підозрюваного"
; KEY Enter
; WAIT 500
; KEY U
; TEXT "Оформлюю протокол, зачекайте"
; KEY Enter
;
; ------------------------------------------------------------
;  БІНД-КАРТИНКА
; ------------------------------------------------------------
; [клавіша активації]
; IMG "пряме посилання на картинку (пряме .png/.jpg/.gif/.webp)"
; (x,y)            <- необов'язково, за замовч. 0,0 (верхній лівий кут екрана)
; (x,y,opacity)    <- opacity 0-255 (255 = непрозоро, менше - прозоріше). Необов'язково.
;
; Повторне натискання тієї ж клавіші ховає картинку.
; Esc закриває всі відкриті картинки одразу.
;
; ⚠️  ВАЖЛИВО ПРО ФОН КАРТИНКИ:
;     Скрипт робить ЧОРНИЙ (#000000) колір фону прозорим (наскрізним).
;     Тобто щоб фон картинки зник і не заважав — він має бути ЧОРНИМ.
;     Якщо фон білий, сірий або інший — він буде видимий поверх гри.
;     Щоб зробити фон чорним: відкрий картинку в будь-якому редакторі
;     (наприклад Paint.NET, Photoshop, GIMP) і залий фон чорним кольором (#000000).
;     Альтернативно: якщо картинка має прозорий фон (PNG з альфа-каналом),
;     збережи її на чорному фоні або переконайся що порожні пікселі = чорні.
;
; Приклад бінду з картинкою (Esc ховає):
;
; [F5]
; IMG "https://example.com/image.png"
; (0,0)
;
; Приклад з позицією та напівпрозорістю:
;
; [F8]
; IMG "https://example.com/image.png"
; (100,50,180)
;
; ============================================================


[F1]
(2000)
KEY T
TEXT "/me дістає посвідчення LSPD"
KEY Enter

[F6]
(200)
KEY Enter
TEXT "/do На грудях висить бейдж: [LSPD | CPD | Hunter Hate | 119756]."
KEY Enter

[F7]
(3000)
KEY Enter
TEXT "/me арештовує підозрюваного"
KEY Enter
WAIT 500
KEY U
TEXT "Оформлюю протокол, зачекайте"
KEY Enter

[F5]
IMG "https://example.com/lspd_badge.png"
(0,0)

[F8]
IMG "https://example.com/half_transparent_badge.png"
(50,50,180)

[F9]
IMG "https://example.com/warrant.png"
    )"
}

; =====================================================================
;                          ПАРСЕР Binds.txt
; =====================================================================
ParseBinds(path) {
    text := FileRead(path, "UTF-8")
    rawLines := StrSplit(text, "`n", "`r")

    ; прибираємо коментарі й пусті рядки, зберігаючи порядок
    lines := []
    for line in rawLines {
        t := Trim(line)
        if (t = "" || SubStr(t, 1, 1) = ";")
            continue
        lines.Push(t)
    }

    binds := []
    i := 1
    n := lines.Length

    while (i <= n) {
        line := lines[i]
        if !RegExMatch(line, "^\[(.+)\]$", &m) {
            i++
            continue
        }
        key := m[1]
        i++
        if (i > n)
            break

        ; --- бінд-картинка ---
        if RegExMatch(lines[i], '^IMG\s+"(.+)"$', &mImg) {
            url := mImg[1]
            i++
            x := 0, y := 0, opacity := 255
            if (i <= n) && RegExMatch(lines[i], "^\(\s*(-?\d*)\s*,\s*(-?\d*)\s*(?:,\s*(\d*)\s*)?\)$", &mPos) {
                if (Trim(mPos[1]) != "")
                    x := Integer(mPos[1])
                if (Trim(mPos[2]) != "")
                    y := Integer(mPos[2])
                if (mPos.Count >= 3 && Trim(mPos[3]) != "")
                    opacity := Integer(mPos[3])
                i++
            }
            binds.Push({ type: "image", key: key, url: url, x: x, y: y, opacity: opacity })
            continue
        }

        ; --- бінд-дія (послідовність кроків) ---
        cooldown := 1000
        if (i <= n) && RegExMatch(lines[i], "^\(\s*(\d+)\s*\)$", &mCd) {
            cooldown := Integer(mCd[1])
            i++
        }

        steps := []
        while (i <= n) && !RegExMatch(lines[i], "^\[(.+)\]$") {
            stepLine := lines[i]
            if RegExMatch(stepLine, "i)^KEY\s+(.+)$", &mKey)
                steps.Push({ action: "key", value: Trim(mKey[1]) })
            else if RegExMatch(stepLine, 'i)^TEXT\s+"(.*)"$', &mTxt)
                steps.Push({ action: "text", value: mTxt[1] })
            else if RegExMatch(stepLine, "i)^WAIT\s+(\d+)$", &mWait)
                steps.Push({ action: "wait", value: Integer(mWait[1]) })
            i++
        }
        binds.Push({ type: "action", key: key, cooldown: cooldown, steps: steps })
    }
    return binds
}

; =====================================================================
;                       ВИКОНАННЯ БІНД-ДІЙ
; =====================================================================
RunActionBind(b) {
    global lastUsed
    now := A_TickCount
    key := b.key

    if lastUsed.Has(key) {
        elapsed := now - lastUsed[key]
        if (elapsed < b.cooldown) {
            remain := Round((b.cooldown - elapsed) / 1000, 1)
            ToolTip("КД: ще " remain " сек.")
            SetTimer(() => ToolTip(), -800)
            return
        }
    }
    lastUsed[key] := now

    oldClip := ClipboardAll()
    needRestore := false

    for step in b.steps {
        if (step.action = "key") {
            Send("{" step.value "}")
            Sleep(30)
        } else if (step.action = "text") {
            A_Clipboard := step.value
            if ClipWait(1) {
                Send("^v")
                needRestore := true
                Sleep(150)
            }
        } else if (step.action = "wait") {
            Sleep(step.value)
        }
    }

    if needRestore
        A_Clipboard := oldClip
}

; =====================================================================
;                  ВИЗНАЧЕННЯ ТИПУ ФАЙЛУ ЗА СИГНАТУРОЮ
; =====================================================================
DetectFileType(path) {
    try {
        f := FileOpen(path, "r")
        if !f
            return "unknown"
        buf := Buffer(12, 0)
        f.RawRead(buf, 12)
        f.Close()
    } catch {
        return "unknown"
    }

    b0 := NumGet(buf, 0, "UChar")
    b1 := NumGet(buf, 1, "UChar")
    b2 := NumGet(buf, 2, "UChar")
    b3 := NumGet(buf, 3, "UChar")

    if (b0 = 0x89 && b1 = 0x50 && b2 = 0x4E && b3 = 0x47)
        return "png"
    if (b0 = 0xFF && b1 = 0xD8)
        return "jpeg"
    if (b0 = 0x47 && b1 = 0x49 && b2 = 0x46)
        return "gif"
    if (b0 = 0x52 && b1 = 0x49 && b2 = 0x46 && b3 = 0x46)
        return "webp"
    if (b0 = 0x3C)
        return "html"
    return "unknown"
}

; =====================================================================
;                       ВИКОНАННЯ БІНД-КАРТИНОК
; =====================================================================
ToggleImageBind(b) {
    global imageGuis
    key := b.key

    if imageGuis.Has(key) {
        try imageGuis[key].Destroy()
        imageGuis.Delete(key)
        return
    }

    safeName := RegExReplace(key, "[^A-Za-z0-9]", "_")
    localPath := A_ScriptDir "\cache_" safeName ".png"

    ; якщо кеш вже є, але биткий (лишився зі старих спроб) - видаляємо і качаємо заново
    if FileExist(localPath) && !IsValidImage(localPath) {
        try FileDelete(localPath)
    }

    if !FileExist(localPath) {
        if !DownloadAndValidate(b.url, localPath, key)
            return
    }

    try {
        myGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        myGui.MarginX := 0
        myGui.MarginY := 0
        myGui.BackColor := "FF00C8"
        myGui.Add("Picture", "x0 y0", localPath)
        myGui.Show("x" b.x " y" b.y " AutoSize NA")

        transStr := "FF00C8"
        if (b.opacity < 255)
            transStr .= " " b.opacity
        WinSetTransColor(transStr, myGui)

        imageGuis[key] := myGui
    } catch as e {
        ToolTip("Не вдалось показати картинку: " e.Message)
        SetTimer(() => ToolTip(), -3500)
        try FileDelete(localPath)
    }
}

IsValidImage(path) {
    t := DetectFileType(path)
    return (t = "png" || t = "jpeg" || t = "gif" || t = "webp")
}

DownloadAndValidate(url, localPath, key) {
    ToolTip("Завантажую картинку...")
    try {
        Download(url, localPath)
    } catch as e {
        ToolTip("Помилка завантаження: " e.Message)
        SetTimer(() => ToolTip(), -2500)
        return false
    }
    ToolTip()

    if !FileExist(localPath) || FileGetSize(localPath) = 0 {
        ToolTip("Файл картинки порожній - перевір посилання в Binds.txt")
        SetTimer(() => ToolTip(), -3000)
        try FileDelete(localPath)
        return false
    }

    if !IsValidImage(localPath) {
        detected := DetectFileType(localPath)
        preview := ""
        try {
            f := FileOpen(localPath, "r")
            preview := f.Read(300)
            f.Close()
        }
        try FileDelete(localPath)
        MsgBox(
            "Посилання для [" key "] не віддає картинку напряму.`n"
            "Сервер повернув: " (detected = "html" ? "HTML-сторінку (можливо захист від гарячого лінкування)" : "невідомі дані") ".`n`n"
            "Початок відповіді:`n" preview,
            "Проблема з картинкою",
            "Icon!"
        )
        return false
    }
    return true
}

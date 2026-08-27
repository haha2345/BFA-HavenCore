local _, HL = ...
HL.ui = HL.ui or {}

local COLORS = {
    panel = { 0.015, 0.025, 0.04, 0.97 },
    inset = { 0.025, 0.045, 0.07, 0.96 },
    gold = { 0.45, 0.24, 0.03, 1 },
    goldHover = { 0.65, 0.38, 0.05, 1 },
    on = { 0.06, 0.42, 0.13, 1 },
    off = { 0.28, 0.08, 0.08, 1 },
    dim = { 0.10, 0.12, 0.16, 1 },
}

local function Skin(frame, color)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(unpack(color or COLORS.inset))
    frame:SetBackdropBorderColor(0.72, 0.43, 0.08, 1)
end

local function Tooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        if self._hoverColor then self:SetBackdropColor(unpack(self._hoverColor)) end
        if title then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(title)
            if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        if self._restColor then self:SetBackdropColor(unpack(self._restColor)) end
        GameTooltip:Hide()
    end)
end

local function Btn(parent, text, w, h, click, tip)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h or 22)
    Skin(b, COLORS.gold)
    b._restColor = COLORS.gold
    b._hoverColor = COLORS.goldHover
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("CENTER")
    b.label:SetText(text)
    b:SetScript("OnClick", click)
    Tooltip(b, text, tip)
    function b:SetOn(on)
        self._restColor = on and COLORS.on or COLORS.gold
        self:SetBackdropColor(unpack(self._restColor))
    end
    return b
end

local function Label(parent, text, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetText(text)
    return fs
end

local ui = {}

local function SavePoint(frame, key)
    local p, _, rp, x, y = frame:GetPoint()
    HL.db[key] = { p, rp, x, y }
end

local function RestorePoint(frame, key, def)
    local pos = HL.db[key]
    frame:ClearAllPoints()
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        frame:SetPoint(def[1], UIParent, def[2], def[3], def[4])
    end
end

local function MakeDraggable(frame, key)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePoint(self, key)
    end)
end

local FILTERS = {
    { key = "test", label = "测试" },
    { key = "watch", label = "监视" },
    { key = "damage", label = "伤害" },
    { key = "aura", label = "光环" },
    { key = "all", label = "与我" },
}

local function RefreshFilters()
    if not ui.filterBtns then return end
    for _, b in ipairs(ui.filterBtns) do
        b:SetOn(HL.db.filter == b._key)
    end
end

local function RebuildLog()
    if not ui.log then return end
    ui.log:Clear()
    for i = 1, #HL.logs do
        local rec = HL.logs[i]
        if HL:ShouldShow(rec) then
            ui.log:AddMessage(rec.rich or rec.plain or "")
        end
    end
end

local function RefreshWatch()
    if not ui.watchText then return end
    local lines = {}
    for _, id in ipairs(HL.db.watch) do
        lines[#lines + 1] = string.format("★ |cffffd100%d|r  %s", id, HL:LabelOf(id))
    end
    if #lines == 0 then
        ui.watchText:SetText("|cff888888没有监视。|r")
    else
        ui.watchText:SetText(table.concat(lines, "\n"))
    end
end

local function RefreshChain()
    if ui.chainText then
        ui.chainText:SetText(HL:ChainText())
    end
    if ui.hint and HL.CurrentPack then
        local pack = HL:CurrentPack()
        if pack and pack.hint then
            ui.hint:SetText(pack.hint)
        end
    end
    if ui.topTargets and HL.TopTargetsText then
        ui.topTargets:SetText(HL:TopTargetsText(5))
    end
    if ui.packBtns then
        for _, b in ipairs(ui.packBtns) do
            b:SetOn(HL.db.pack == b._key)
        end
    end
end

local function FormatAuraLine(a)
    local remain
    if a.duration and a.duration > 0 and a.expiration then
        remain = string.format("%.0fs", math.max(0, a.expiration - GetTime()))
    else
        remain = "永久"
    end
    local col = a.watched and "ffffd100" or "ffcccccc"
    local src = ""
    if a.source then
        local n = UnitName(a.source)
        if n then src = "  " .. n end
    end
    return string.format("|c%s%d|r x%d %s %s%s", col, a.spellId, a.count > 0 and a.count or 1, a.name, remain, src)
end

local function RefreshAuras()
    if not ui.playerAuras then return end
    local function dump(unit, fs, empty)
        if unit ~= "player" and not UnitExists(unit) then
            fs:SetText(empty)
            return
        end
        local list = HL:CollectAuras(unit)
        if #list == 0 then
            fs:SetText("|cff888888(无)|r")
            return
        end
        local lines = {}
        for i = 1, math.min(#list, 12) do
            lines[#lines + 1] = FormatAuraLine(list[i])
        end
        if #list > 12 then lines[#lines + 1] = "|cff888888…共" .. #list .. "个|r" end
        fs:SetText(table.concat(lines, "\n"))
    end
    dump("player", ui.playerAuras, "|cff888888(无)|r")
    if UnitExists("target") then
        local hp, maxhp = UnitHealth("target"), UnitHealthMax("target")
        local pct = (maxhp and maxhp > 0) and (100 * hp / maxhp) or 0
        ui.targetHead:SetText(string.format("目标  %s  %.0f%%", UnitName("target") or "?", pct))
    else
        ui.targetHead:SetText("目标  （未选）")
    end
    dump("target", ui.targetAuras, "|cff888888选中木桩后这里会列出 ID 和层数|r")
end

local function RefreshCorr()
    if not ui.corrText or not HL.CorruptionMatrixLines then return end
    ui.corrText:SetText(table.concat(HL:CorruptionMatrixLines(), "\n"))
end

local function RefreshSnap()
    if not ui.snapText then return end
    local parts = {}
    for id, s in pairs(HL.stats) do
        if s.statDelta then
            parts[#parts + 1] = tostring(id) .. HL:FormatSnapshotDelta(s.statDelta, s.statBefore, s.statAfter)
        end
    end
    if #parts == 0 then
        local snap = HL.lastSnapshot
        if snap then
            ui.snapText:SetText(string.format("|cff888888急速%.1f 精通%.1f 暴击%.1f|r",
                snap.haste or 0, snap.mastery or 0, snap.crit or 0))
        else
            ui.snapText:SetText("|cff888888点「记快照」对比属性|r")
        end
    else
        ui.snapText:SetText(table.concat(parts, "\n"))
    end
end

local function RefreshHistory()
    if not ui.histBtns then return end
    local hist = HL.db.history
    for i = 1, #ui.histBtns do
        local cmd = hist[#hist - i + 1]
        local b = ui.histBtns[i]
        if cmd then
            b:Show()
            local shown = cmd
            if #shown > 22 then shown = shown:sub(1, 20) .. ".." end
            b.label:SetText(shown)
            b._cmd = cmd
        else
            b:Hide()
        end
    end
end

local function AddTicker(rec)
    if not ui.ticker or not HL.db.showTicker then return end
    if rec.ev == "SYSTEM" then return end
    if rec.ev ~= "LAB" and (not rec.spellId or not HL:IsWatched(rec.spellId)) then return end
    ui.ticker:AddMessage(rec.rich or rec.plain)
end

local function ShowCopy(text)
    if not ui.copy then return end
    ui.copyBox:SetText(text or "")
    ui.copy:Show()
    ui.copyBox:SetFocus()
    ui.copyBox:HighlightText()
    ui.copyBox:SetCursorPosition(0)
end

local function RefreshOverview()
    if not ui.ovRows then return end
    local ov = HL.db.overview or {}
    for _, row in ipairs(ui.ovRows) do
        local st = ov[row.key] or {}
        if row.l0 then row.l0:SetChecked(st.l0 and true or false) end
        if row.l1 then row.l1:SetChecked(st.l1 and true or false) end
        if row.l2 then row.l2:SetChecked(st.l2 and true or false) end
        if row.time then row.time:SetText(st.t or "") end
    end
end

local function BuildCommandBar()
    local bar = CreateFrame("Frame", "HavenLabCommandBar", UIParent)
    bar:SetSize(760, 58)
    bar:SetFrameStrata("HIGH")
    Skin(bar, COLORS.panel)
    RestorePoint(bar, "cmdPos", { "BOTTOM", "BOTTOM", 0, 24 })
    MakeDraggable(bar, "cmdPos")
    bar:SetShown(HL.db.showCmdBar ~= false)
    ui.cmdBar = bar

    local tag = Label(bar, "命令", "GameFontNormalSmall")
    tag:SetPoint("TOPLEFT", 10, -8)

    local box = CreateFrame("EditBox", "HavenLabCommandEdit", bar, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", 48, -4)
    box:SetSize(560, 24)
    box:SetAutoFocus(false)
    box:SetMaxLetters(200)
    box:SetAltArrowKeyMode(false)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnEnterPressed", function(self)
        local t = self:GetText()
        HL:Send(t)
        self:SetText("")
    end)
    box:SetScript("OnKeyDown", function(self, key)
        if key == "UP" then
            self:SetText(HL:HistoryPrev())
            self:SetCursorPosition(9999)
        elseif key == "DOWN" then
            self:SetText(HL:HistoryNext())
            self:SetCursorPosition(9999)
        elseif IsControlKeyDown() and key == "A" then
            self:HighlightText()
        end
    end)
    ui.cmdBox = box

    local send = Btn(bar, "发送", 52, 22, function()
        local t = box:GetText()
        HL:Send(t)
        box:SetText("")
        box:SetFocus()
    end, "回车同样发送。以 . 开头走 SAY（GM 命令），以 / 开头当斜杠。")
    send:SetPoint("LEFT", box, "RIGHT", 8, 0)

    local copy = Btn(bar, "全选", 44, 22, function()
        box:SetFocus()
        box:HighlightText()
    end, "全选后 Ctrl+C 复制。")
    copy:SetPoint("LEFT", send, "RIGHT", 6, 0)

    local hide = Btn(bar, "×", 22, 22, function()
        HL.db.showCmdBar = false
        bar:Hide()
    end, "隐藏命令栏。在调试台点「命令栏」再打开。")
    hide:SetPoint("TOPRIGHT", -6, -4)
    hide._restColor = COLORS.off
    hide:SetBackdropColor(unpack(COLORS.off))

    ui.histBtns = {}
    for i = 1, 6 do
        local hb = Btn(bar, "", 118, 18, function(self)
            if not self._cmd then return end
            if IsShiftKeyDown() then
                HL:Send(self._cmd)
            else
                box:SetText(self._cmd)
                box:SetFocus()
                box:SetCursorPosition(strlen(self._cmd))
            end
        end, "点击填入，Shift+点击直接发送。")
        hb:SetPoint("BOTTOMLEFT", 8 + (i - 1) * 124, 6)
        hb._restColor = COLORS.dim
        hb:SetBackdropColor(unpack(COLORS.dim))
        hb._hoverColor = COLORS.goldHover
        ui.histBtns[i] = hb
        hb:Hide()
    end
end

local function BuildTicker()
    local t = CreateFrame("Frame", "HavenLabTicker", UIParent)
    t:SetSize(420, 130)
    t:SetFrameStrata("HIGH")
    Skin(t, COLORS.panel)
    RestorePoint(t, "tickerPos", { "CENTER", "CENTER", 280, 160 })
    MakeDraggable(t, "tickerPos")
    t:SetShown(HL.db.showTicker ~= false)
    ui.tickerFrame = t

    local head = Label(t, "监视事件（拖得动）", "GameFontNormalSmall")
    head:SetPoint("TOPLEFT", 10, -8)

    local smf = CreateFrame("ScrollingMessageFrame", nil, t)
    smf:SetPoint("TOPLEFT", 8, -22)
    smf:SetPoint("BOTTOMRIGHT", -8, 8)
    smf:SetFontObject(ChatFontNormal)
    smf:SetJustifyH("LEFT")
    smf:SetFading(false)
    smf:SetMaxLines(40)
    smf:SetInsertMode("BOTTOM")
    smf:SetHyperlinksEnabled(true)
    smf:EnableMouse(true)
    smf:EnableMouseWheel(true)
    smf:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    smf:SetScript("OnHyperlinkEnter", function(_, link)
        GameTooltip:SetOwner(t, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    smf:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    smf:SetScript("OnMouseUp", function()
        if ui.frame then ui.frame:SetShown(true) end
    end)
    ui.ticker = smf
end

local function BuildCopy()
    local f = CreateFrame("Frame", "HavenLabCopy", UIParent)
    f:SetSize(720, 460)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    Skin(f, COLORS.panel)
    f:EnableMouse(true)
    f:Hide()
    ui.copy = f

    local title = Label(f, "全选后 Ctrl+C 复制，把报告贴回来就能对链路")
    title:SetPoint("TOPLEFT", 16, -12)

    local close = Btn(f, "关闭", 60, 22, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", -12, -10)

    local sel = Btn(f, "全选", 60, 22, function()
        ui.copyBox:SetFocus()
        ui.copyBox:HighlightText()
    end)
    sel:SetPoint("RIGHT", close, "LEFT", -8, 0)

    local scroll = CreateFrame("ScrollFrame", "HavenLabCopyScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -40)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)

    local box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    box:SetWidth(650)
    box:SetMaxLetters(100000)
    box:SetTextInsets(4, 4, 4, 4)
    box:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(box)
    ui.copyBox = box
end

local function BuildOverview()
    local f = CreateFrame("Frame", "HavenLabOverview", UIParent)
    f:SetSize(560, 360)
    f:SetPoint("CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    Skin(f, COLORS.panel)
    f:EnableMouse(true)
    f:Hide()
    ui.overview = f

    local title = Label(f, "效果总览（手动勾选，存本地）")
    title:SetPoint("TOPLEFT", 16, -12)

    local close = Btn(f, "关闭", 60, 22, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", -12, -10)

    local exp = Btn(f, "导出", 60, 22, function()
        ShowCopy(HL:OverviewExport())
    end, "生成可贴进 00-目标.md 进度表的纯文本。")
    exp:SetPoint("RIGHT", close, "LEFT", -8, 0)

    local head = Label(f, "效果          第0层  第1层  第2层  最后测试", "GameFontNormalSmall")
    head:SetPoint("TOPLEFT", 20, -42)

    ui.ovRows = {}
    local packs = HL:VisiblePacks()
    for i, pack in ipairs(packs) do
        if pack then
            local row = { key = pack.key }
            local name = Label(f, pack.title, "GameFontHighlight")
            name:SetPoint("TOPLEFT", 20, -60 - (i - 1) * 36)
            local function mk(x, field)
                local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
                cb:SetPoint("TOPLEFT", x, -54 - (i - 1) * 36)
                cb:SetSize(26, 26)
                cb:SetScript("OnClick", function(self)
                    HL.db.overview[pack.key] = HL.db.overview[pack.key] or {}
                    HL.db.overview[pack.key][field] = self:GetChecked() and true or false
                    HL.db.overview[pack.key].t = date("%Y-%m-%d %H:%M")
                    RefreshOverview()
                end)
                return cb
            end
            row.l0 = mk(140, "l0")
            row.l1 = mk(190, "l1")
            row.l2 = mk(240, "l2")
            row.time = Label(f, "", "GameFontDisableSmall")
            row.time:SetPoint("TOPLEFT", 290, -64 - (i - 1) * 36)
            ui.ovRows[#ui.ovRows + 1] = row
        end
    end
end

local function BuildMain()
    local f = CreateFrame("Frame", "HavenLabFrame", UIParent)
    f:SetSize(1000, 620)
    f:SetFrameStrata("HIGH")
    Skin(f, COLORS.panel)
    RestorePoint(f, "pos", { "CENTER", "CENTER", 0, 40 })
    MakeDraggable(f, "pos")
    f:Hide()
    ui.frame = f

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("TOPLEFT", 14, -12)
    icon:SetTexture("Interface\\Icons\\Spell_Arcane_StarFire")
    local title = Label(f, "HavenLab  技能调试台", "GameFontNormalLarge")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    local sub = Label(f, "选效果 → 打木桩 → 生成报告", "GameFontDisableSmall")
    sub:SetPoint("LEFT", title, "RIGHT", 12, 0)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local report = Btn(f, "复制报告", 78, 22, function()
        ShowCopy(HL:GetReport())
    end, "生成一份带链路、光环、战斗记录的纯文本，Ctrl+C 贴给开发用。")
    report:SetPoint("TOPRIGHT", -40, -12)

    local ovBtn = Btn(f, "总览", 48, 22, function()
        ui.overview:SetShown(not ui.overview:IsShown())
        if ui.overview:IsShown() then RefreshOverview() end
    end, "各效果第 0/1/2 层勾选存档，修下一条之前把已过的再勾一遍。")
    ovBtn:SetPoint("RIGHT", report, "LEFT", -6, 0)

    local tickerBtn = Btn(f, "漂浮窗", 60, 22, function()
        HL.db.showTicker = not HL.db.showTicker
        ui.tickerFrame:SetShown(HL.db.showTicker)
    end, "屏幕上的监视事件小窗，打木桩时不用开大面板。")
    tickerBtn:SetPoint("RIGHT", ovBtn, "LEFT", -6, 0)

    local cmdBtn = Btn(f, "命令栏", 60, 22, function()
        HL.db.showCmdBar = not (HL.db.showCmdBar == false)
        ui.cmdBar:SetShown(HL.db.showCmdBar ~= false)
        if HL.db.showCmdBar ~= false then ui.cmdBox:SetFocus() end
    end, "底部命令栏。默认聊天要用 Alt+方向键移光标，这里不用。")
    cmdBtn:SetPoint("RIGHT", tickerBtn, "LEFT", -6, 0)

    local left = CreateFrame("Frame", nil, f)
    left:SetPoint("TOPLEFT", 12, -44)
    left:SetSize(268, 564)
    Skin(left, COLORS.inset)

    local how = Label(left, "选一个效果开始")
    how:SetPoint("TOPLEFT", 12, -10)

    ui.packBtns = {}
    local packDefs = {
        { key = "stars", label = "无尽之星", tip = "挂 317257。用猛击等技能打木桩。落星写成 STAR_VISUAL。" },
        { key = "twilight", label = "暮光毁灭", tip = "挂 317147。面对木桩打。斩击写成 TWILIGHT_VISUAL。" },
        { key = "echo", label = "虚空回响", tip = "挂 317014。用带 GCD 的技能打。坍缩写成 ECHO_COLLAPSE。" },
        { key = "tentacle", label = "扭曲附肢", tip = "挂 316815。平砍或技能都会出触须。写成 TENTACLE_SPAWN。" },
        { key = "ritual", label = "虚空仪式", tip = "挂 316814。用技能打。开仪式写成 RITUAL_PROC，爬坡写成 RITUAL_TICK。" },
    }
    for i, def in ipairs(packDefs) do
        local b = Btn(left, def.label, 80, 26, function()
            HL:StartPackTest(def.key)
            RefreshFilters()
            RefreshChain()
        end, def.tip)
        b._key = def.key
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        b:SetPoint("TOPLEFT", 10 + col * 84, -32 - row * 28)
        ui.packBtns[i] = b
    end

    ui.hint = Label(left, "用技能打木桩。出星看记录里的 STAR_VISUAL，\n不用盯着天。buff 栏没有 317257 是正常的。", "GameFontDisableSmall")
    ui.hint:SetPoint("TOPLEFT", 12, -100)
    ui.hint:SetWidth(244)
    ui.hint:SetJustifyH("LEFT")

    ui.chainText = Label(left, "", "GameFontHighlightSmall")
    ui.chainText:SetPoint("TOPLEFT", 12, -124)
    ui.chainText:SetWidth(244)
    ui.chainText:SetJustifyH("LEFT")
    ui.chainText:SetSpacing(2)

    ui.topTargets = Label(left, "", "GameFontHighlightSmall")
    ui.topTargets:SetPoint("BOTTOMLEFT", 12, 150)
    ui.topTargets:SetWidth(244)
    ui.topTargets:SetJustifyH("LEFT")

    local reportBtn = Btn(left, "生成报告", 246, 28, function()
        ShowCopy(HL:GetReport())
    end, "把白话结论和战斗记录做成可复制文本。先别点卸星。全选后 Ctrl+C。")
    reportBtn:SetPoint("BOTTOMLEFT", 10, 118)
    reportBtn:SetOn(true)

    local prep = Label(left, "准备", "GameFontNormalSmall")
    prep:SetPoint("BOTTOMLEFT", 12, 94)
    local dummy = Btn(left, "一排桩", 76, 22, function() HL:Send(".labaoe") end, "面前一排 5 个 + 右侧 1 个 + 背后 1 个临时木桩。测暮光：面向那一排打。")
    dummy:SetPoint("BOTTOMLEFT", 10, 68)
    local gm = Btn(left, "GM准备", 76, 22, function()
        HL:SendMany({ ".gm on", ".cheat god on", ".cheat cooldown on" })
    end)
    gm:SetPoint("LEFT", dummy, "RIGHT", 6, 0)
    local gear = Btn(left, "发测试装", 76, 22, function()
        HL:GiveTestGear()
    end, "给当前角色一套 8.3 尼奥罗萨级板甲。无腐蚀 bonus。")
    gear:SetPoint("LEFT", gm, "RIGHT", 6, 0)

    local ctrl = Label(left, "对照（测完再用，会搅乱结论）", "GameFontNormalSmall")
    ctrl:SetPoint("BOTTOMLEFT", 12, 46)
    local vis = Btn(left, "看落星", 80, 22, function()
        HL:Send(".cast 317262 triggered")
        HL:Print("用眼睛看天上有没有星。这条经常不进战斗记录。")
    end, "对照动画。点完看天上，不要看战斗记录有没有施法。")
    vis:SetPoint("BOTTOMLEFT", 10, 20)
    local dmg = Btn(left, "手打伤害", 80, 22, function()
        HL:Send(".cast 317265 triggered")
    end, "选中木桩。对照：这条应该叠层并打出奥术伤害。")
    dmg:SetPoint("LEFT", vis, "RIGHT", 6, 0)
    local unaura = Btn(left, "卸星", 80, 22, function()
        HL:Send(".lab clear")
    end, "一条命令卸掉星/暮光/回响测试光环。报告复制完再卸。")
    unaura:SetPoint("LEFT", dmg, "RIGHT", 6, 0)

    ui.watchText = Label(left, "", "GameFontHighlightSmall")
    ui.watchText:SetPoint("TOPLEFT", 12, -8)
    ui.watchText:Hide()

    local mid = CreateFrame("Frame", nil, f)
    mid:SetPoint("TOPLEFT", 286, -44)
    mid:SetPoint("BOTTOMRIGHT", -262, 12)
    Skin(mid, COLORS.inset)

    local logTitle = Label(mid, "战斗记录  （点金色 ID 看技能提示）")
    logTitle:SetPoint("TOPLEFT", 12, -10)

    ui.filterBtns = {}
    for i, def in ipairs(FILTERS) do
        local b = Btn(mid, def.label, 48, 20, function()
            HL.db.filter = def.key
            RefreshFilters()
            RebuildLog()
        end)
        b._key = def.key
        b:SetPoint("TOPLEFT", 12 + (i - 1) * 54, -30)
        ui.filterBtns[i] = b
    end

    local pause = Btn(mid, "暂停", 48, 20, function(self)
        ui.paused = not ui.paused
        self.label:SetText(ui.paused and "继续" or "暂停")
        self:SetOn(ui.paused)
    end)
    pause:SetPoint("TOPRIGHT", -96, -30)

    local clear = Btn(mid, "清空", 48, 20, function() HL:ClearLog() end)
    clear:SetPoint("TOPRIGHT", -44, -30)

    local bottom = Btn(mid, "底", 32, 20, function()
        if ui.log then ui.log:ScrollToBottom() end
    end)
    bottom:SetPoint("TOPRIGHT", -8, -30)

    local smf = CreateFrame("ScrollingMessageFrame", "HavenLabLog", mid)
    smf:SetPoint("TOPLEFT", 10, -56)
    smf:SetPoint("BOTTOMRIGHT", -10, 10)
    smf:SetFontObject(ChatFontNormal)
    smf:SetJustifyH("LEFT")
    smf:SetFading(false)
    smf:SetMaxLines(400)
    smf:SetInsertMode("BOTTOM")
    smf:SetHyperlinksEnabled(true)
    smf:EnableMouse(true)
    smf:EnableMouseWheel(true)
    smf:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    smf:SetScript("OnHyperlinkEnter", function(_, link)
        GameTooltip:SetOwner(mid, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    smf:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    ui.log = smf
    ui.paused = false

    local right = CreateFrame("Frame", nil, f)
    right:SetPoint("TOPRIGHT", -12, -44)
    right:SetSize(244, 564)
    Skin(right, COLORS.inset)

    local ch = Label(right, "腐蚀 / 阈值")
    ch:SetPoint("TOPLEFT", 12, -10)
    ui.corrText = Label(right, "", "GameFontHighlightSmall")
    ui.corrText:SetPoint("TOPLEFT", 12, -26)
    ui.corrText:SetWidth(220)
    ui.corrText:SetJustifyH("LEFT")
    ui.corrText:SetSpacing(1)

    local snapBtn = Btn(right, "记快照", 70, 20, function()
        local before = HL.lastSnapshot
        local after = HL:StatSnapshot()
        if before then
            local delta = HL:DiffSnapshots(before, after)
            HL:PushLog({
                t = time(), ev = "SYSTEM", mine = true,
                text = "SNAP" .. (HL:FormatSnapshotDelta(delta, before, after) ~= ""
                    and HL:FormatSnapshotDelta(delta, before, after) or " 无变化"),
            })
        else
            HL:Print("已记第一张快照，再点一次看出增量。")
        end
        RefreshSnap()
    end, "两次快照对比急速/精通/暴击/全能/吸血。测权宜之计等被动用。")
    snapBtn:SetPoint("TOPLEFT", 12, -130)

    local speedBtn = Btn(right, "移速", 54, 20, function(self)
        local on = not HL.db.showSpeed
        HL:SetSpeedWatch(on)
        self:SetOn(on)
    end, "每 0.2 秒看移速，变化超过 3% 记一条 SPEED。测蔓生触须用。默认关。")
    speedBtn:SetPoint("LEFT", snapBtn, "RIGHT", 6, 0)
    speedBtn:SetOn(HL.db.showSpeed and true or false)
    ui.speedBtn = speedBtn

    ui.snapText = Label(right, "", "GameFontDisableSmall")
    ui.snapText:SetPoint("TOPLEFT", 12, -154)
    ui.snapText:SetWidth(220)
    ui.snapText:SetJustifyH("LEFT")

    local ph = Label(right, "自己光环（含隐藏）")
    ph:SetPoint("TOPLEFT", 12, -188)
    ui.playerAuras = Label(right, "", "GameFontHighlightSmall")
    ui.playerAuras:SetPoint("TOPLEFT", 12, -206)
    ui.playerAuras:SetWidth(220)
    ui.playerAuras:SetJustifyH("LEFT")
    ui.playerAuras:SetSpacing(1)

    ui.targetHead = Label(right, "目标")
    ui.targetHead:SetPoint("TOPLEFT", 12, -380)
    ui.targetAuras = Label(right, "", "GameFontHighlightSmall")
    ui.targetAuras:SetPoint("TOPLEFT", 12, -398)
    ui.targetAuras:SetWidth(220)
    ui.targetAuras:SetJustifyH("LEFT")
    ui.targetAuras:SetSpacing(1)

    smf:AddMessage("|cff7ec8e3选左边效果 → 打木桩 →「生成报告」。金色 LAB 行是服务端动画/坍缩消息。|r")
    smf:AddMessage("|cffaaaaaa红色是技能伤，灰色「普攻」是普通平砍。点金色法术 ID 看提示。|r")
end

local function BuildMinimap()
    local m = CreateFrame("Button", "HavenLabMinimapButton", Minimap)
    m:SetSize(32, 32)
    m:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -4, 8)
    m:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local tex = m:CreateTexture(nil, "BACKGROUND")
    tex:SetSize(20, 20)
    tex:SetPoint("CENTER")
    tex:SetTexture("Interface\\Icons\\Spell_Arcane_StarFire")
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = m:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\MINIMAP\\MiniMap-TrackingBorder")
    m:SetHighlightTexture("Interface\\MINIMAP\\UI-Minimap-ZoomButton-Highlight")
    m:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            HL:FocusCommand()
        else
            HL:Toggle()
        end
    end)
    m:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("HavenLab 技能调试台")
        GameTooltip:AddLine("左键打开面板，右键聚焦命令栏。", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    m:SetScript("OnLeave", GameTooltip_Hide)
    m:SetShown(HL.db.showMinimap ~= false)
    ui.minimap = m
end

HL.ui.build = function()
    if ui.frame then return end
    BuildCommandBar()
    BuildTicker()
    BuildCopy()
    BuildOverview()
    BuildMain()
    BuildMinimap()
    RefreshFilters()
    RefreshWatch()
    RefreshChain()
    RefreshAuras()
    RefreshHistory()
    RefreshCorr()
    RefreshSnap()
    RefreshOverview()
    HL:Print("已加载 " .. HL.version .. "。/lab 打开。选效果打木桩，再生成报告。")
end

HL.ui.toggle = function()
    if not ui.frame then return end
    ui.frame:SetShown(not ui.frame:IsShown())
    if ui.frame:IsShown() then
        RefreshAuras()
        RefreshChain()
        RefreshWatch()
        RefreshCorr()
        RefreshSnap()
    end
end

HL.ui.focus = function()
    if not ui.cmdBar then return end
    HL.db.showCmdBar = true
    ui.cmdBar:Show()
    ui.cmdBox:SetFocus()
end

HL.ui.log = function(rec)
    if ui.paused then return end
    if ui.log then ui.log:AddMessage(rec.rich or rec.plain or "") end
end

HL.ui.ticker = function(rec)
    AddTicker(rec)
end

HL.ui.rebuild = function()
    RebuildLog()
    RefreshChain()
    RefreshCorr()
    RefreshSnap()
    if ui.ticker then ui.ticker:Clear() end
end

HL.ui.watch = function()
    RefreshWatch()
    RebuildLog()
end

HL.ui.pack = function()
    RefreshWatch()
    RefreshChain()
end

HL.ui.chain = RefreshChain
HL.ui.auras = RefreshAuras
HL.ui.history = RefreshHistory
HL.ui.filters = RefreshFilters
HL.ui.corr = RefreshCorr
HL.ui.statsnap = RefreshSnap
HL.ui.overview = RefreshOverview
HL.ui.copy = function()
    ShowCopy(HL:GetReport())
end

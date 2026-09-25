-- Danny's Cheats | Blox Strike | Full Build
-- ESP + WH + Aim + Effects + Skin Changer
if _G.DC_Cleanup then pcall(_G.DC_Cleanup) end
_G.DC_Cleanup = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

for _, g in ipairs(LP:WaitForChild("PlayerGui"):GetChildren()) do
    if g.Name:sub(1,3) == "DC_" then g:Destroy() end
end

local State = { Running = true, Connections = {} }
local Aim = { Ready = false, Target = nil }
local ESPs = {}
local Effects = { Ready = false, Records = {} }
local WH = {}

local Cfg = {
    ESPEnabled = true, TeamCheck = false, ShowEnemies = true, ESPMaxDist = 2000,
    VisibilityCheck = false, VisibleColor = false, Boxes = true, Names = true,
    HealthBar = true, HealthText = true, Distance = true, HeldWeapon = true, BombCarrier = true,
    CSW_Enabled = false, CSW_TeamCheck = false, CSW_MaxDist = 2000,
    CSW_BoxColor = Color3.fromRGB(0, 255, 0),
    CSW_HPFullColor = Color3.fromRGB(80, 220, 80),
    CSW_HPLowColor = Color3.fromRGB(255, 60, 60),
    CSW_ShowBox = true, CSW_ShowHP = true,
    CSW_ShowName = true, CSW_ShowDistance = true,
    CSW_Thickness = 1,
    EnemyColor = Color3.fromRGB(255,95,105), TeammateColor = Color3.fromRGB(87,181,255),
    InSightColor = Color3.fromRGB(115,238,159), TextColor = Color3.fromRGB(242,244,250),
    OutlineColor = Color3.fromRGB(10,12,18),
    HealthLowColor = Color3.fromRGB(255,78,86), HealthHighColor = Color3.fromRGB(102,230,142),
    SilentEnabled = false, SilentTeamCheck = true, SilentVisibleOnly = true,
    SilentTargetPart = "Head", SilentPriority = "Crosshair", SilentMaxDistance = 1200,
    SilentHitChance = 100, SilentFOV = 150, SilentShowTarget = true,
    SilentPrediction = true, SilentBulletSpeed = 1000,
    EffectsNoFlash = false, EffectsNoSmoke = false,
    SkinChangerEnabled = false, SkinChangerSkins = {},
    KnifeChangerEnabled = false, KnifeChangerModel = "Skeleton Knife",
    GloveChangerEnabled = false, GloveChangerModel = "Sports Gloves", GloveChangerGloves = {},
    GuiColor = Color3.fromRGB(100,130,255),
}

local PALETTE = {
    Color3.fromRGB(255,95,105), Color3.fromRGB(87,181,255), Color3.fromRGB(115,238,159),
    Color3.fromRGB(255,195,80), Color3.fromRGB(160,100,255), Color3.fromRGB(255,80,220),
    Color3.fromRGB(242,244,250), Color3.fromRGB(80,80,90),
}

local function connect(sig, cb)
    local c = sig:Connect(cb)
    table.insert(State.Connections, c)
    return c
end

local function teamOf(p)
    local n = p:GetAttribute("Team")
    if n == "Counter-Terrorists" or n == "Terrorists" then return n end
    return nil
end

local function matchChar(p)
    local c = p.Character
    local chars = workspace:FindFirstChild("Characters")
    if not teamOf(p) or not c or not chars or not c:IsDescendantOf(chars) then return nil end
    if c:GetAttribute("CharacterType") ~= "PlayerCustomCharacter" then return nil end
    if p:GetAttribute("IsSpectating") == true or p:GetAttribute("Dead") == true then return nil end
    if c:GetAttribute("Dead") == true then return nil end
    local h, m = c:GetAttribute("Health"), c:GetAttribute("MaxHealth")
    if type(h) ~= "number" or h ~= h or h == math.huge or h <= 0 then return nil end
    if type(m) ~= "number" or m ~= m or m <= 0 then m = 100 end
    return c, h, m
end

local function teamAllowed(p)
    local mt, tt = teamOf(LP), teamOf(p)
    if not tt then return false, false end
    if mt == tt then return not Cfg.TeamCheck, true end
    return Cfg.ShowEnemies, false
end

local function cswTeamAllowed(p)
    local mt, tt = teamOf(LP), teamOf(p)
    if not tt then return false end
    if mt == tt then return not Cfg.CSW_TeamCheck end
    return true
end

-- ========== OLD ESP ==========
local function getAnchor(model)
    if not model then return nil end
    for _, n in ipairs({"HumanoidRootPart","UpperTorso","Torso","Chest","Head","Root","Body"}) do
        local p = model:FindFirstChild(n, true)
        if p and p:IsA("BasePart") then return p end
    end
    return nil
end

local function destroyESP(player)
    local e = ESPs[player]
    if not e then return end
    if e.HL then e.HL:Destroy() end
    if e.BB then e.BB:Destroy() end
    ESPs[player] = nil
end

local function equipmentOf(p)
    local raw = p:GetAttribute("CurrentEquipped")
    if raw ~= p._EqRaw then
        p._EqRaw = raw
        local ok, d = pcall(HS.JSONDecode, HS, raw)
        if ok and type(d) == "table" then
            p._WeaponName = type(d.Name) == "string" and d.Name ~= "" and d.Name or nil
        end
    end
    local slot = p:GetAttribute("Slot5")
    if slot ~= p._BombRaw then
        p._BombRaw = slot
        local ok, d = pcall(HS.JSONDecode, HS, slot)
        p._HasBomb = ok and type(d) == "table" and d.Weapon == "C4"
    end
    return p._WeaponName, p._HasBomb or p._WeaponName == "C4"
end

local function createESP(player)
    if player == LP then return end
    local char = matchChar(player)
    if not char then return end
    local head = char:FindFirstChild("Head", true)
    local anchor = getAnchor(char)
    if not anchor then return end
    local mate = select(2, teamAllowed(player))
    local col = mate and Cfg.TeammateColor or Cfg.EnemyColor

    local e = { Char = char, Anchor = anchor, Player = player }

    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Adornee = char
        h.FillColor = col
        h.FillTransparency = 0.92
        h.OutlineColor = col
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = false
        h.Parent = char
        return h
    end)
    if ok and hl then e.HL = hl end

    if head then
        local bb = Instance.new("BillboardGui")
        bb.Adornee = head
        bb.Size = UDim2.new(0, 240, 0, 80)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = false
        bb.Parent = char

        local function makeLabel(y, size)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, size or 14)
            l.Position = UDim2.new(0, 0, 0, y)
            l.BackgroundTransparency = 1
            l.Text = ""
            l.TextColor3 = Cfg.TextColor
            l.TextStrokeTransparency = 0
            l.TextStrokeColor3 = Cfg.OutlineColor
            l.TextSize = 11
            l.Font = Enum.Font.GothamBold
            l.Visible = false
            l.Parent = bb
            return l
        end

        local name = makeLabel(0, 20)
        name.TextSize = 14

        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(0.7, 0, 0, 6)
        hpBg.Position = UDim2.new(0.5, 0, 0, 24)
        hpBg.AnchorPoint = Vector2.new(0.5, 0)
        hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        hpBg.BorderSizePixel = 0
        hpBg.Visible = false
        hpBg.Parent = bb

        local hpBgC = Instance.new("UICorner")
        hpBgC.CornerRadius = UDim.new(1, 0)
        hpBgC.Parent = hpBg

        local hpBgS = Instance.new("UIStroke")
        hpBgS.Color = Cfg.OutlineColor
        hpBgS.Thickness = 1.5
        hpBgS.Transparency = 0.2
        hpBgS.Parent = hpBg

        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Cfg.HealthHighColor
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg

        local hpFillC = Instance.new("UICorner")
        hpFillC.CornerRadius = UDim.new(1, 0)
        hpFillC.Parent = hpFill

        local hpText = makeLabel(32)
        local dist = makeLabel(46)
        local weapon = makeLabel(60, 12)

        e.BB = bb
        e.Name = name
        e.HP = hpBg
        e.HPFill = hpFill
        e.HPText = hpText
        e.Dist = dist
        e.Weapon = weapon
    end

    ESPs[player] = e
end

local function updateESP()
    for p, e in pairs(ESPs) do
        local c = matchChar(p)
        if not c or c ~= e.Char or not select(1, teamAllowed(p)) then
            destroyESP(p)
        end
    end

    if not Cfg.ESPEnabled then
        for _, e in pairs(ESPs) do
            if e.HL then e.HL.Enabled = false end
            if e.BB then e.BB.Enabled = false end
        end
        return
    end

    for p, e in pairs(ESPs) do
        local c = matchChar(p)
        if c then
            local a = e.Anchor
            local mate = select(2, teamAllowed(p))
            local color = mate and Cfg.TeammateColor or Cfg.EnemyColor
            if a and a.Parent then
                local dist = (Cam.CFrame.Position - a.Position).Magnitude
                local vis = dist <= Cfg.ESPMaxDist

                if vis and Cfg.VisibilityCheck then
                    local rp = RaycastParams.new()
                    rp.FilterType = Enum.RaycastFilterType.Exclude
                    rp.FilterDescendantsInstances = {LP.Character, c}
                    vis = not workspace:Raycast(Cam.CFrame.Position, a.Position - Cam.CFrame.Position, rp)
                end

                if e.HL then
                    e.HL.Enabled = vis and Cfg.Boxes
                    e.HL.FillColor = color
                    e.HL.OutlineColor = color
                end
                if e.BB then e.BB.Enabled = vis end
                if e.Name then
                    local dn = p.DisplayName ~= "" and p.DisplayName or p.Name
                    e.Name.Text = dn
                    e.Name.TextColor3 = color
                    e.Name.Visible = vis and Cfg.Names and #dn > 0
                end
                if e.Dist then
                    e.Dist.Text = string.format("%.0f m", dist)
                    e.Dist.Visible = vis and Cfg.Distance
                end
                if e.HP then
                    local h, m = c:GetAttribute("Health"), c:GetAttribute("MaxHealth") or 100
                    local show = false
                    if type(h) == "number" and h > 0 then
                        local pct = math.clamp(h/m, 0, 1)
                        if e.HPFill then
                            e.HPFill.Size = UDim2.new(pct, 0, 1, 0)
                            e.HPFill.BackgroundColor3 = Cfg.HealthLowColor:Lerp(Cfg.HealthHighColor, pct)
                        end
                        if e.HPText then e.HPText.Text = string.format("%d / %d", math.floor(h), math.floor(m)) end
                        show = true
                    elseif e.HPText then
                        e.HPText.Text = ""
                    end
                    e.HP.Visible = vis and Cfg.HealthBar and show
                    if e.HPText then e.HPText.Visible = vis and Cfg.HealthText and show end
                end
                if e.Weapon then
                    local wn, hb = equipmentOf(p)
                    if hb then
                        e.Weapon.Text = "C4"
                        e.Weapon.TextColor3 = Color3.fromRGB(255,195,80)
                        e.Weapon.Visible = vis and Cfg.BombCarrier
                    elseif wn and #wn > 0 then
                        e.Weapon.Text = wn
                        e.Weapon.TextColor3 = Color3.fromRGB(217,226,242)
                        e.Weapon.Visible = vis and Cfg.HeldWeapon
                    else
                        e.Weapon.Text = ""
                        e.Weapon.Visible = false
                    end
                end
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not ESPs[p] then
            if select(1, teamAllowed(p)) and matchChar(p) then
                createESP(p)
            end
        end
    end
end

-- ========== CS:GO WH ==========
local function cswHideAll(e)
    if not e then return end
    if e.BoxLines then for _, l in ipairs(e.BoxLines) do pcall(function() l.Visible = false end) end end
    pcall(function() e.HPBg.Visible = false end)
    pcall(function() e.HPFill.Visible = false end)
    pcall(function() e.NameText.Visible = false end)
    pcall(function() e.DistText.Visible = false end)
end

local function cswDestroy(e)
    if not e then return end
    if e.BoxLines then for _, l in ipairs(e.BoxLines) do pcall(function() l:Remove() end) end end
    pcall(function() e.HPBg:Remove() end)
    pcall(function() e.HPFill:Remove() end)
    pcall(function() e.NameText:Remove() end)
    pcall(function() e.DistText:Remove() end)
end

local function cswRemove(player)
    local e = WH[player]
    if not e then return end
    cswHideAll(e)
    task.defer(function() cswDestroy(e) end)
    WH[player] = nil
end

local function cswCreate(player)
    if player == LP then return end
    if not matchChar(player) then return end
    if not Drawing or type(Drawing.new) ~= "function" then return end
    local e = { BoxLines = {} }

    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Visible = false
        l.Color = Cfg.CSW_BoxColor
        l.Thickness = Cfg.CSW_Thickness
        l.Transparency = 1
        table.insert(e.BoxLines, l)
    end

    local hpBg = Drawing.new("Square")
    hpBg.Visible = false
    hpBg.Filled = true
    hpBg.Color = Color3.fromRGB(0, 0, 0)
    hpBg.Transparency = 1
    e.HPBg = hpBg

    local hpFill = Drawing.new("Square")
    hpFill.Visible = false
    hpFill.Filled = true
    hpFill.Color = Cfg.CSW_HPFullColor
    hpFill.Transparency = 1
    e.HPFill = hpFill

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Color = Cfg.TextColor
    nameText.Size = 14
    nameText.Font = 2
    e.NameText = nameText

    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.new(0, 0, 0)
    distText.Color = Cfg.TextColor
    distText.Size = 12
    distText.Font = 2
    e.DistText = distText

    WH[player] = e
end

local function cswWorldToScreen(pos)
    local sp, onScreen = Cam:WorldToViewportPoint(pos)
    if not onScreen or sp.Z <= 0 then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function cswUpdate(player, e)
    local char, hp, maxHp = matchChar(player)
    if not char then
        cswHideAll(e)
        return false
    end

    local hrp = char:FindFirstChild("HumanoidRootPart") 
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("Head")
    if not hrp then
        cswHideAll(e)
        return false
    end

    local extents
    pcall(function() extents = char:GetExtentsSize() end)
    if not extents then extents = Vector3.new(2, 6, 1) end

    local center = hrp.Position
    local headPos = center + Vector3.new(0, extents.Y / 2, 0)
    local feetPos = center - Vector3.new(0, extents.Y / 2, 0)

    local headScreen = cswWorldToScreen(headPos)
    local feetScreen = cswWorldToScreen(feetPos)
    if not headScreen or not feetScreen then
        cswHideAll(e)
        return true
    end

    local dist = (Cam.CFrame.Position - hrp.Position).Magnitude
    if dist > Cfg.CSW_MaxDist then
        cswHideAll(e)
        return true
    end

    if not e.SmoothHead then
        e.SmoothHead = headScreen
        e.SmoothFeet = feetScreen
    else
        e.SmoothHead = e.SmoothHead:Lerp(headScreen, 0.3)
        e.SmoothFeet = e.SmoothFeet:Lerp(feetScreen, 0.3)
    end

    local top = e.SmoothHead.Y
    local bottom = e.SmoothFeet.Y
    local height = bottom - top
    local width = height * 0.55
    local left = e.SmoothHead.X - width / 2
    local right = e.SmoothHead.X + width / 2

    if Cfg.CSW_ShowBox then
        local corners = {
            {Vector2.new(left, top), Vector2.new(right, top)},
            {Vector2.new(left, bottom), Vector2.new(right, bottom)},
            {Vector2.new(left, top), Vector2.new(left, bottom)},
            {Vector2.new(right, top), Vector2.new(right, bottom)},
        }
        for i, pair in ipairs(corners) do
            local line = e.BoxLines[i]
            line.From = pair[1]
            line.To = pair[2]
            line.Color = Cfg.CSW_BoxColor
            line.Thickness = Cfg.CSW_Thickness
            line.Visible = true
        end
    else
        for _, line in ipairs(e.BoxLines) do line.Visible = false end
    end

    if Cfg.CSW_ShowHP then
        local barX = right + 4
        local barW = 3
        local barH = height
        local hpPct = math.clamp(hp / maxHp, 0, 1)

        e.HPBg.Size = Vector2.new(barW, barH)
        e.HPBg.Position = Vector2.new(barX, top)
        e.HPBg.Color = Color3.new(0, 0, 0)
        e.HPBg.Visible = true

        e.HPFill.Size = Vector2.new(barW, barH * hpPct)
        e.HPFill.Position = Vector2.new(barX, bottom - barH * hpPct)
        e.HPFill.Color = Cfg.CSW_HPLowColor:Lerp(Cfg.CSW_HPFullColor, hpPct)
        e.HPFill.Visible = true
    else
        e.HPBg.Visible = false
        e.HPFill.Visible = false
    end

    if Cfg.CSW_ShowName then
        e.NameText.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
        e.NameText.Position = Vector2.new((left + right) / 2, top - 18)
        e.NameText.Visible = true
    else
        e.NameText.Visible = false
    end

    if Cfg.CSW_ShowDistance then
        e.DistText.Text = string.format("%.0f m", dist)
        e.DistText.Position = Vector2.new((left + right) / 2, bottom + 4)
        e.DistText.Visible = true
    else
        e.DistText.Visible = false
    end

    return true
end

-- ========== Effects ==========
function Effects.UpdateNoFlash()
    if not Cfg.EffectsNoFlash then return end
    for _, obj in ipairs(game:GetService("Lighting"):GetChildren()) do
        if obj:IsA("ColorCorrectionEffect") then
            if not Effects.Records[obj] then
                Effects.Records[obj] = {Kind="CC", Enabled=obj.Enabled, Brightness=obj.Brightness, Contrast=obj.Contrast}
            end
            obj.Enabled = false
            obj.Brightness = 0
            obj.Contrast = 0
        elseif obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
            if not Effects.Records[obj] then
                Effects.Records[obj] = {Kind=obj.ClassName, Enabled=obj.Enabled}
            end
            obj.Enabled = false
        end
    end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            local n = gui.Name:lower()
            if n:find("flash") or n:find("blind") or n:find("whiteout") or n:find("bang") or n:find("stun") or n:find("fade") then
                if gui:IsA("ScreenGui") then
                    if not Effects.Records[gui] then
                        Effects.Records[gui] = {Kind="Gui", Enabled=gui.Enabled}
                    end
                    gui.Enabled = false
                end
            end
        end
    end
end

function Effects.UpdateNoSmoke()
    if not Cfg.EffectsNoSmoke then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            local n = obj.Name:lower()
            local pn = obj.Parent and obj.Parent.Name:lower() or ""
            if n:find("smoke") or pn:find("smoke") or n:find("gas") or pn:find("gas") or n:find("fog") or pn:find("fog") then
                if not Effects.Records[obj] then
                    Effects.Records[obj] = {Kind="P", Enabled=obj.Enabled}
                end
                obj.Enabled = false
            end
        elseif obj:IsA("Smoke") or obj:IsA("Fire") then
            if not Effects.Records[obj] then
                Effects.Records[obj] = {Kind="S", Enabled=obj.Enabled}
            end
            obj.Enabled = false
        elseif obj:IsA("BasePart") then
            local n = obj.Name:lower()
            local pn = obj.Parent and obj.Parent.Name:lower() or ""
            if n:find("smoke") or pn:find("smoke") then
                if not Effects.Records[obj] then
                    Effects.Records[obj] = {Kind="T", Transparency=obj.Transparency}
                end
                obj.Transparency = 1
            end
        end
    end
end

Effects.Ready = true

-- ========== Silent Aim ==========
local function aimAllowed()
    return State.Running and Aim.Ready and Cfg.SilentEnabled
        and not UIS:GetFocusedTextBox() and matchChar(LP) ~= nil
end

local AimParts = {"Head", "UpperTorso", "LowerTorso"}
local AimRandom = Random.new()

local function predictPos(part, origin)
    local pos = part.Position
    if not Cfg.SilentPrediction then return pos end
    local v = part.AssemblyLinearVelocity
    if not v or v.Magnitude < 1 then return pos end
    local d = (pos - origin).Magnitude
    local t = math.min(d / math.max(Cfg.SilentBulletSpeed, 1), 0.3)
    return pos + v * t
end

local function selectTarget(cam, origin, maxRange, randomize)
    if not aimAllowed() then return nil end
    local center = cam.ViewportSize * 0.5
    local limit = math.min(Cfg.SilentMaxDistance, maxRange or math.huge)
    local cands = {}
    local myTeam = teamOf(LP)
    local rp = Cfg.SilentTargetPart == "Random"

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c, h = matchChar(p)
            if c and (not Cfg.SilentTeamCheck or teamOf(p) ~= myTeam) then
                local names = (Cfg.SilentTargetPart == "Closest" or rp) and AimParts
                    or {Cfg.SilentTargetPart == "Chest" and "UpperTorso" or "Head"}
                for _, n in ipairs(names) do
                    local part = c:FindFirstChild(n)
                    if part and part:IsA("BasePart") and part.Parent then
                        local pred = predictPos(part, origin)
                        local point, onScreen = cam:WorldToViewportPoint(part.Position)
                        local radius = (Vector2.new(point.X, point.Y) - center).Magnitude
                        local dist = (part.Position - origin).Magnitude
                        if onScreen and point.Z > 0 and radius <= Cfg.SilentFOV and dist > 0.05 and dist <= limit then
                            local score = Cfg.SilentPriority == "Distance" and dist or Cfg.SilentPriority == "Health" and h or radius
                            table.insert(cands, {Player=p, Character=c, Part=part, Position=pred, Radius=radius, Score=score})
                        end
                    end
                end
            end
        end
    end

    table.sort(cands, function(a, b)
        if a.Score ~= b.Score then return a.Score < b.Score end
        if a.Radius ~= b.Radius then return a.Radius < b.Radius end
        return a.Player.UserId < b.Player.UserId
    end)

    local ignore = Cfg.SilentVisibleOnly and Aim.GetRayIgnore() or nil
    local selPlayer, avail = nil, {}
    for _, cand in ipairs(cands) do
        if selPlayer and cand.Player ~= selPlayer then continue end
        if not cand.Character.Parent or not cand.Part.Parent then continue end
        local visible = true
        if Cfg.SilentVisibleOnly then
            local off = cand.Position - origin
            local hit = Aim.Raycast.cast(origin, off.Unit * (off.Magnitude + 0.05), nil, ignore)
            visible = not hit.instance or hit.instance:IsDescendantOf(cand.Character)
        end
        if visible then
            if not rp then return cand end
            selPlayer = cand.Player
            table.insert(avail, cand)
        end
    end
    if #avail > 0 then
        if randomize then return avail[AimRandom:NextInteger(1, #avail)] end
        for _, c in ipairs(avail) do
            if Aim.Target and c.Part == Aim.Target.Part then return c end
        end
        return avail[1]
    end
    return nil
end

local function redirectShot(bullet, shot, target)
    if not target.Part.Parent or not target.Character.Parent then return nil end
    local pos = predictPos(target.Part, shot.Origin)
    local off = pos - shot.Origin
    if off.Magnitude < 0.05 then return nil end
    local dir = off.Unit
    local props = bullet.Properties
    local pen = props.Penetration or 0
    local ignore = Aim.GetRayIgnore()
    local res = {Origin=shot.Origin, Direction=dir, Distance=props.Range or 500, Hits={}}
    local first = Aim.Raycast.cast(shot.Origin, dir * res.Distance, nil, ignore)
    if first.instance then
        res.Distance = (first.position - shot.Origin).Magnitude
        local hits = Aim.Raycast.castThrough(first.position - dir * 0.001, dir * (pen + 0.001), pen, ignore)
        for i, hit in ipairs(hits) do
            if i > 200 then break end
            if hit.instance and hit.material then
                if (hit.position - shot.Origin).Magnitude > (props.Range or 500) + 0.01 then break end
                table.insert(res.Hits, {Position=hit.position, Instance=hit.instance, Material=hit.material.Name, Normal=hit.normal or Vector3.zero, Exit=i % 2 == 0})
            end
        end
    end
    Aim.Target = target
    return res
end

local function installSilent()
    local ok, err = pcall(function()
        local storage = game:GetService("ReplicatedStorage")
        local bullet = require(storage.Components.Weapon.Classes.Bullet)
        local raycast = require(storage.Shared.Raycast)
        local getIgnore = require(storage.Components.Common.GetRayIgnore)
        Aim.Module, Aim.Original, Aim.Raycast, Aim.GetRayIgnore = bullet, bullet._performRaycast, raycast, getIgnore
        Aim.Wrapper = function(self, spread, ...)
            local isLocal = State.Running and self.IsActive and not self.IsDestroyed and self.Weapon and self.Weapon.Player == LP
            local shot = Aim.Original(self, spread, ...)
            if not isLocal or type(shot) ~= "table" then return shot end
            if not aimAllowed() then return shot end
            if AimRandom:NextInteger(1, 100) > Cfg.SilentHitChance then return shot end
            local ok2, redirected = pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return nil end
                local target = selectTarget(cam, shot.Origin, self.Properties.Range or 500, true)
                if not target then return nil end
                local sp = cam:WorldToViewportPoint(target.Part.Position)
                local center = cam.ViewportSize * 0.5
                if (Vector2.new(sp.X, sp.Y) - center).Magnitude > Cfg.SilentFOV then return nil end
                return redirectShot(self, shot, target)
            end)
            if ok2 then return redirected or shot end
            return shot
        end
        bullet._performRaycast = Aim.Wrapper
        Aim.Ready = bullet._performRaycast == Aim.Wrapper
    end)
    if not ok then Aim.LastError = tostring(err) end
end

-- ========== SKIN CHANGER ==========
local SD = { SkinsRoot = nil, SkinSelections = {}, GloveSelections = {}, GloveFolders = {} }

pcall(function()
    SD.SkinsRoot = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Skins")
end)

if SD.SkinsRoot then
    pcall(function()
        for _, wf in ipairs(SD.SkinsRoot:GetChildren()) do
            local skins = {}
            for _, sf in ipairs(wf:GetChildren()) do
                skins[#skins + 1] = sf.Name
            end
            table.sort(skins)
            SD.SkinSelections[wf.Name] = skins
        end
        for _, folder in ipairs(SD.SkinsRoot:GetChildren()) do
            if (folder.Name:match("Glove") or folder.Name:match("Gloves") or folder.Name == "Hand Wraps")
               and not (folder.Name:match("T Glove") or folder.Name:match("CT Glove")) then
                SD.GloveFolders[#SD.GloveFolders + 1] = folder
            end
        end
    end)
end

for _, gf in ipairs(SD.GloveFolders) do
    local skins = {"Default"}
    for _, skin in ipairs(gf:GetChildren()) do
        skins[#skins + 1] = skin.Name
    end
    SD.GloveSelections[gf.Name] = skins
end

for w, s in pairs(SD.SkinSelections) do
    Cfg.SkinChangerSkins[w] = s[1] or "Default"
end
for _, gf in ipairs(SD.GloveFolders) do
    Cfg.GloveChangerGloves[gf.Name] = "Default"
end

local function Checkknife(w)
    if not w then return false end
    return w == "CT Knife" or w == "T Knife" or w == "Knife"
end

local function SafeRequire(module)
    if not module then return nil end
    local ok, result = pcall(function() return require(module) end)
    if ok and result and type(result) == "table" then return result end
    return nil
end

local function InitSkinHooks()
    if not hookfunction then return end
    pcall(function()
        local SM = RS:FindFirstChild("Database")
            and RS.Database:FindFirstChild("Components")
            and RS.Database.Components:FindFirstChild("Libraries")
            and RS.Database.Components.Libraries:FindFirstChild("Skins")

        local VM = RS:FindFirstChild("Classes")
            and RS.Classes:FindFirstChild("WeaponComponent")
            and RS.Classes.WeaponComponent:FindFirstChild("Classes")
            and RS.Classes.WeaponComponent.Classes:FindFirstChild("Viewmodel")

        if not SM or not VM then return end

        local Sk = SafeRequire(SM)
        local Vm = SafeRequire(VM)
        if not Sk or not Vm then return end

        local oGCM = Sk.GetCameraModel
        if oGCM then
            Sk.GetCameraModel = function(w, sk, ...)
                if Cfg.KnifeChangerEnabled and w and Checkknife(w) then
                    local nk = Cfg.KnifeChangerModel
                    local ns = Cfg.SkinChangerSkins[nk] or "Vanilla"
                    local ok, r = pcall(oGCM, nk, ns, ...)
                    if ok and r then return r end
                end
                local ok, r = pcall(oGCM, w, sk, ...)
                if ok then return r end
                return nil
            end
        end

        local oGChM = Sk.GetCharacterModel
        if oGChM then
            Sk.GetCharacterModel = function(w, sk, ...)
                if Cfg.KnifeChangerEnabled and w and Checkknife(w) then
                    local nk = Cfg.KnifeChangerModel
                    local ns = Cfg.SkinChangerSkins[nk] or "Vanilla"
                    local ok, r = pcall(oGChM, nk, ns, ...)
                    if ok and r then return r end
                end
                local ok, r = pcall(oGChM, w, sk, ...)
                if ok then return r end
                return nil
            end
        end

        local oVN = Vm.new
        if oVN then
            Vm.new = function(vc, w, sk, ...)
                if Cfg.KnifeChangerEnabled and w and Checkknife(w) then
                    local nk = Cfg.KnifeChangerModel
                    local ns = Cfg.SkinChangerSkins[nk] or "Vanilla"
                    local ok, r = pcall(oVN, vc, nk, ns, ...)
                    if ok and r then return r end
                end
                local ok, r = pcall(oVN, vc, w, sk, ...)
                if ok then return r end
                return nil
            end
        end

        if Sk.GetGloves then
            local oGG = Sk.GetGloves
            Sk.GetGloves = function(g, sk)
                if Cfg.GloveChangerEnabled and Cfg.GloveChangerModel then
                    local gm = Cfg.GloveChangerModel
                    local ts = Cfg.GloveChangerGloves[gm] or "Default"
                    local ok, r = pcall(oGG, gm, ts)
                    if ok and r then return r end
                end
                local ok, r = pcall(oGG, g, sk)
                if ok then return r end
                return nil
            end
        end
    end)
end

InitSkinHooks()

local function GetWeaponModel()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    for _, ch in pairs(cam:GetChildren()) do
        if ch:IsA("Model") and ch.Name ~= "Arms" and ch.Name ~= "Viewmodel" then
            return ch
        end
    end
    return nil
end

local function ApplySkin()
    if not SD.SkinsRoot then return end
    local wm = GetWeaponModel()
    if not wm then return end

    local own = wm.Name
    local ewn = own
    local ca = false

    if Checkknife(own) then
        if Cfg.KnifeChangerEnabled then
            ewn = Cfg.KnifeChangerModel
            ca = true
        end
    else
        if Cfg.SkinChangerEnabled then
            ca = true
        end
    end

    if not ca then return end

    local sel = Cfg.SkinChangerSkins[ewn]
    if not sel or sel == "Default" then return end

    local wsf = SD.SkinsRoot:FindFirstChild(ewn)
    if not wsf then return end
    local sf = wsf:FindFirstChild(sel)
    if not sf then return end
    local cf = sf:FindFirstChild("Camera")
    if not cf then return end
    local fn = cf:FindFirstChild("Factory New")
    if not fn then return end

    for _, sa in pairs(fn:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            local pt = wm:FindFirstChild(sa.Name, true)
            if pt and (pt:IsA("BasePart") or pt:IsA("MeshPart")) then
                for _, old in pairs(pt:GetChildren()) do
                    if old:IsA("SurfaceAppearance") then old:Destroy() end
                end
                sa:Clone().Parent = pt
            end
        end
    end
end

local function ApplyGloves()
    if not Cfg.GloveChangerEnabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    local am
    for _, ch in ipairs(cam:GetChildren()) do
        if ch:IsA("Model") and (ch.Name:match("Arms") or ch:FindFirstChild("Right Arm")) then
            am = ch
            break
        end
    end
    if not am then return end

    local la = am:FindFirstChild("Left Arm")
    local ra = am:FindFirstChild("Right Arm")
    if not la or not ra then return end
    local lg = la:FindFirstChild("Glove")
    local rg = ra:FindFirstChild("Glove")
    if not lg or not rg then return end

    for _, old in pairs(lg:GetChildren()) do
        if old:IsA("SurfaceAppearance") then old:Destroy() end
    end
    for _, old in pairs(rg:GetChildren()) do
        if old:IsA("SurfaceAppearance") then old:Destroy() end
    end

    local sm = Cfg.GloveChangerModel
    if not sm then return end
    local sel = Cfg.GloveChangerGloves[sm]
    if not sel or sel == "Default" then return end

    local gsf = SD.SkinsRoot:FindFirstChild(sm)
    if not gsf then return end
    local sv = gsf:FindFirstChild(sel)
    if not sv then return end
    local cf = sv:FindFirstChild("Camera")
    if not cf then return end
    local fn = cf:FindFirstChild("Factory New")
    if not fn then return end

    for _, sa in pairs(fn:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            sa:Clone().Parent = lg
            sa:Clone().Parent = rg
        end
    end
end

-- ========== Циклы ==========
task.spawn(function()
    while task.wait(0.05) do
        if not Cfg.SilentEnabled or not Aim.Ready then
            Aim.Target = nil
        else
            local cam = workspace.CurrentCamera
            if cam and aimAllowed() then
                Aim.Target = selectTarget(cam, cam.CFrame.Position, Cfg.SilentMaxDistance, false)
            else
                Aim.Target = nil
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        pcall(updateESP)
    end
end)

task.spawn(function()
    while task.wait(0.03) do
        if not Cfg.CSW_Enabled then
            for _, e in pairs(WH) do cswHideAll(e) end
        else
            local toRemove = {}
            for p, e in pairs(WH) do
                if not Players:FindFirstChild(p.Name) then
                    table.insert(toRemove, p)
                else
                    local valid = cswUpdate(p, e)
                    if not valid then
                        table.insert(toRemove, p)
                    end
                end
            end
            for _, p in ipairs(toRemove) do
                cswRemove(p)
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and not WH[p] then
                    if cswTeamAllowed(p) and matchChar(p) then
                        cswCreate(p)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if Cfg.EffectsNoFlash then pcall(Effects.UpdateNoFlash) end
        if Cfg.EffectsNoSmoke then pcall(Effects.UpdateNoSmoke) end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Cfg.SkinChangerEnabled or Cfg.KnifeChangerEnabled then
                ApplySkin()
            end
            if Cfg.GloveChangerEnabled then
                ApplyGloves()
            end
        end)
    end
end)

connect(Players.PlayerRemoving, function(p) destroyESP(p) cswRemove(p) end)

-- ========== FOV Circle ==========
local aimGui = Instance.new("ScreenGui")
aimGui.Name = "DC_FOV"
aimGui.ResetOnSpawn = false
aimGui.IgnoreGuiInset = true
aimGui.DisplayOrder = 98
aimGui.Parent = LP:WaitForChild("PlayerGui")

local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, Cfg.SilentFOV * 2, 0, Cfg.SilentFOV * 2)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = aimGui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Cfg.GuiColor
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local targetRing = Instance.new("Frame")
targetRing.Size = UDim2.new(0, 26, 0, 26)
targetRing.AnchorPoint = Vector2.new(0.5, 0.5)
targetRing.BackgroundTransparency = 1
targetRing.Visible = false
targetRing.Parent = aimGui

local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Cfg.InSightColor
ringStroke.Thickness = 3
ringStroke.Parent = targetRing

local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = targetRing

connect(RunService.RenderStepped, function()
    fovCircle.Visible = Cfg.SilentEnabled
    fovCircle.Size = UDim2.new(0, Cfg.SilentFOV * 2, 0, Cfg.SilentFOV * 2)
    fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    fovStroke.Color = Cfg.GuiColor
    local lt = Aim.Target
    if lt and lt.Part and lt.Part.Parent and lt.Character and lt.Character.Parent and Cfg.SilentShowTarget then
        local sp, onScreen = Cam:WorldToViewportPoint(lt.Part.Position)
        if onScreen and sp.Z > 0 then
            targetRing.Position = UDim2.new(0, sp.X, 0, sp.Y)
            targetRing.Visible = true
        else
            targetRing.Visible = false
        end
    else
        targetRing.Visible = false
    end
end)

-- ========== GUI ==========
local themeRefs = {}
local function reg(o, r) table.insert(themeRefs, {obj=o, role=r}) end

local function applyTheme()
    local ac = Cfg.GuiColor
    for _, it in ipairs(themeRefs) do
        local o = it.obj
        if o and o.Parent then
            if it.role == "accent" then o.BackgroundColor3 = ac
            elseif it.role == "textAccent" then o.TextColor3 = ac
            elseif it.role == "bgInput" then o.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
            elseif it.role == "bgMain" then o.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            elseif it.role == "bgSide" then o.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
            elseif it.role == "bgCard" then o.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
            elseif it.role == "stroke" then o.Color = Color3.fromRGB(45, 45, 55)
            elseif it.role == "scroll" then o.ScrollBarImageColor3 = ac
            elseif it.role == "toggleBg" then
                local k = o:GetAttribute("Key")
                if k and Cfg[k] then o.BackgroundColor3 = ac else o.BackgroundColor3 = Color3.fromRGB(34, 34, 42) end
            end
        end
    end
end

local function buildGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "DC_GUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100
    gui.Parent = LP:WaitForChild("PlayerGui")

    local reopenBtn = Instance.new("TextButton")
    reopenBtn.Size = UDim2.new(0, 34, 0, 34)
    reopenBtn.Position = UDim2.new(0, 14, 0, 70)
    reopenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    reopenBtn.BorderSizePixel = 0
    reopenBtn.Text = "+"
    reopenBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    reopenBtn.Font = Enum.Font.GothamBold
    reopenBtn.TextSize = 18
    reopenBtn.Visible = false
    reopenBtn.AutoButtonColor = false
    reopenBtn.Parent = gui

    local rbc = Instance.new("UICorner")
    rbc.CornerRadius = UDim.new(1, 0)
    rbc.Parent = reopenBtn

    local rbs = Instance.new("UIStroke")
    rbs.Color = Color3.fromRGB(50, 50, 62)
    rbs.Thickness = 1
    rbs.Transparency = 0.2
    rbs.Parent = reopenBtn

    local dragging, dStart, sStart = false, nil, nil
    reopenBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dStart = i.Position
            sStart = reopenBtn.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dStart
            reopenBtn.Position = UDim2.new(sStart.X.Scale, sStart.X.Offset + d.X, sStart.Y.Scale, sStart.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local W, H = 520, 380
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, W, 0, H)
    main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.ClipsDescendants = true
    main.Parent = gui
    reg(main, "bgMain")

    local mainC = Instance.new("UICorner")
    mainC.CornerRadius = UDim.new(0, 10)
    mainC.Parent = main

    local mainS = Instance.new("UIStroke")
    mainS.Color = Color3.fromRGB(45, 45, 55)
    mainS.Thickness = 1
    mainS.Transparency = 0.2
    mainS.Parent = main
    reg(mainS, "stroke")

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = main
    reg(header, "bgSide")

    local hC = Instance.new("UICorner")
    hC.CornerRadius = UDim.new(0, 10)
    hC.Parent = header

    local hFix = Instance.new("Frame")
    hFix.Size = UDim2.new(1, 0, 0, 12)
    hFix.Position = UDim2.new(0, 0, 1, -12)
    hFix.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    hFix.BorderSizePixel = 0
    hFix.ZIndex = 2
    hFix.Parent = header
    reg(hFix, "bgSide")

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 3, 0, 18)
    stripe.Position = UDim2.new(0, 12, 0.5, -9)
    stripe.BackgroundColor3 = Cfg.GuiColor
    stripe.BorderSizePixel = 0
    stripe.ZIndex = 3
    stripe.Parent = header
    reg(stripe, "accent")

    local stripeC = Instance.new("UICorner")
    stripeC.CornerRadius = UDim.new(1, 0)
    stripeC.Parent = stripe

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0, 200, 1, 0)
    titleLbl.Position = UDim2.new(0, 24, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Danny's Cheats"
    titleLbl.TextColor3 = Color3.fromRGB(240, 240, 250)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 3
    titleLbl.Parent = header

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -34, 0.5, -13)
    minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    minBtn.BorderSizePixel = 0
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 15
    minBtn.AutoButtonColor = false
    minBtn.ZIndex = 3
    minBtn.Parent = header
    reg(minBtn, "bgInput")

    local mC = Instance.new("UICorner")
    mC.CornerRadius = UDim.new(0, 6)
    mC.Parent = minBtn

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, -48)
    sidebar.Position = UDim2.new(0, 6, 0, 42)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 1
    sidebar.Parent = main
    reg(sidebar, "bgSide")

    local sbC = Instance.new("UICorner")
    sbC.CornerRadius = UDim.new(0, 8)
    sbC.Parent = sidebar

    local sbL = Instance.new("UIListLayout")
    sbL.Padding = UDim.new(0, 3)
    sbL.SortOrder = Enum.SortOrder.LayoutOrder
    sbL.Parent = sidebar

    local sbP = Instance.new("UIPadding")
    sbP.PaddingTop = UDim.new(0, 6)
    sbP.PaddingLeft = UDim.new(0, 5)
    sbP.PaddingRight = UDim.new(0, 5)
    sbP.Parent = sidebar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -136, 1, -48)
    content.Position = UDim2.new(0, 130, 0, 42)
    content.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    content.BorderSizePixel = 0
    content.ZIndex = 1
    content.Parent = main
    reg(content, "bgCard")

    local contC = Instance.new("UICorner")
    contC.CornerRadius = UDim.new(0, 8)
    contC.Parent = content

    local tabTitle = Instance.new("TextLabel")
    tabTitle.Size = UDim2.new(1, -20, 0, 26)
    tabTitle.Position = UDim2.new(0, 14, 0, 6)
    tabTitle.BackgroundTransparency = 1
    tabTitle.Text = "ESP"
    tabTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
    tabTitle.Font = Enum.Font.GothamBold
    tabTitle.TextSize = 13
    tabTitle.TextXAlignment = Enum.TextXAlignment.Left
    tabTitle.Parent = content

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -28, 0, 1)
    divider.Position = UDim2.new(0, 14, 0, 34)
    divider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    divider.BorderSizePixel = 0
    divider.Parent = content
    reg(divider, "stroke")

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -48)
    scroll.Position = UDim2.new(0, 10, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Cfg.GuiColor
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = content
    reg(scroll, "scroll")

    local scrollL = Instance.new("UIListLayout")
    scrollL.Padding = UDim.new(0, 4)
    scrollL.SortOrder = Enum.SortOrder.LayoutOrder
    scrollL.Parent = scroll

    local tabs, tabButtons = {}, {}
    local currentTab = nil

    local function switchTab(name)
        for n, f in pairs(tabs) do f.Visible = (n == name) end
        for n, b in pairs(tabButtons) do
            local active = (n == name)
            b.BackgroundColor3 = active and Color3.fromRGB(34, 34, 42) or Color3.fromRGB(20, 20, 24)
            local bar = b:FindFirstChild("ActiveBar")
            if bar then bar.Visible = active end
            local lbl = b:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.TextColor3 = active and Color3.fromRGB(240, 240, 250) or Color3.fromRGB(160, 160, 180) end
        end
        tabTitle.Text = name
    end

    local function makeTabBtn(name)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 28)
        b.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.Parent = sidebar

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b

        local bar = Instance.new("Frame")
        bar.Name = "ActiveBar"
        bar.Size = UDim2.new(0, 3, 0, 14)
        bar.Position = UDim2.new(0, 0, 0.5, -7)
        bar.BackgroundColor3 = Cfg.GuiColor
        bar.BorderSizePixel = 0
        bar.Visible = false
        bar.Parent = b
        reg(bar, "accent")

        local barC = Instance.new("UICorner")
        barC.CornerRadius = UDim.new(1, 0)
        barC.Parent = bar

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -14, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(160, 160, 180)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = b

        b.MouseButton1Click:Connect(function()
            currentTab = name
            switchTab(name)
        end)
        tabButtons[name] = b
        return b
    end

    local function makeTab(name)
        local f = Instance.new("Frame")
        f.Name = name
        f.Size = UDim2.new(1, 0, 0, 0)
        f.BackgroundTransparency = 1
        f.Visible = false
        f.AutomaticSize = Enum.AutomaticSize.Y
        f.Parent = scroll

        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = f

        tabs[name] = f
        makeTabBtn(name)
        return f
    end

    local function section(parent, txt)
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, 0, 0, 18)
        s.BackgroundTransparency = 1
        s.Text = string.upper(txt)
        s.TextColor3 = Cfg.GuiColor
        s.Font = Enum.Font.GothamBold
        s.TextSize = 9
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = parent
        reg(s, "textAccent")
    end

    local function toggle(parent, txt, key, cb)
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.Parent = parent
        reg(row, "bgInput")

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local tg = Instance.new("Frame")
        tg.Size = UDim2.new(0, 30, 0, 16)
        tg.Position = UDim2.new(1, -42, 0.5, -8)
        tg.BackgroundColor3 = Cfg[key] and Cfg.GuiColor or Color3.fromRGB(55, 55, 68)
        tg.BorderSizePixel = 0
        tg.Parent = row
        tg:SetAttribute("Key", key)
        reg(tg, "toggleBg")

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = Cfg[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = tg

        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob

        row.MouseButton1Click:Connect(function()
            Cfg[key] = not Cfg[key]
            Tween:Create(tg, TweenInfo.new(0.15), {
                BackgroundColor3 = Cfg[key] and Cfg.GuiColor or Color3.fromRGB(55, 55, 68)
            }):Play()
            Tween:Create(knob, TweenInfo.new(0.15), {
                Position = Cfg[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }):Play()
            if cb then cb() end
        end)
    end

    local function slider(parent, txt, key, mn, mx, step)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0
        row.Parent = parent
        reg(row, "bgInput")

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 55, 0, 16)
        val.Position = UDim2.new(1, -60, 0, 4)
        val.BackgroundTransparency = 1
        val.Text = tostring(Cfg[key])
        val.TextColor3 = Cfg.GuiColor
        val.Font = Enum.Font.GothamBold
        val.TextSize = 11
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = row
        reg(val, "textAccent")

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 5)
        bar.Position = UDim2.new(0, 12, 0, 28)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
        bar.BorderSizePixel = 0
        bar.Parent = row

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((Cfg[key] - mn) / (mx - mn), 0, 1, 0)
        fill.BackgroundColor3 = Cfg.GuiColor
        fill.BorderSizePixel = 0
        fill.Parent = bar

        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(1, 0)
        fc.Parent = fill
        reg(fill, "accent")

        local dr = false
        local function upd(i)
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = math.floor((mn + (mx - mn) * rel) / step) * step
            Cfg[key] = v
            val.Text = tostring(v)
            fill.Size = UDim2.new(rel, 0, 1, 0)
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dr = true
                upd(i)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                upd(i)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dr = false
            end
        end)
    end

    local function optionRow(parent, txt, key, opts)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0
        row.Parent = parent
        reg(row, "bgInput")

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -24, 0, 24)
        holder.Position = UDim2.new(0, 12, 0, 24)
        holder.BackgroundTransparency = 1
        holder.Parent = row

        local hl = Instance.new("UIListLayout")
        hl.FillDirection = Enum.FillDirection.Horizontal
        hl.Padding = UDim.new(0, 3)
        hl.Parent = holder

        local btns = {}
        local function refresh()
            for _, b in ipairs(btns) do
                if Cfg[key] == b.Val then
                    b.Btn.BackgroundColor3 = Cfg.GuiColor
                    b.Btn.TextColor3 = Color3.new(1,1,1)
                else
                    b.Btn.BackgroundColor3 = Color3.fromRGB(45,45,56)
                    b.Btn.TextColor3 = Color3.fromRGB(170,170,190)
                end
            end
        end

        for _, v in ipairs(opts) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 52, 1, 0)
            b.BackgroundColor3 = Color3.fromRGB(45,45,56)
            b.BorderSizePixel = 0
            b.Text = tostring(v)
            b.TextColor3 = Color3.fromRGB(170,170,190)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 9
            b.AutoButtonColor = false
            b.Parent = holder

            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 5)
            bc.Parent = b

            table.insert(btns, {Btn=b, Val=v})
            b.MouseButton1Click:Connect(function()
                Cfg[key] = v
                refresh()
            end)
        end
        refresh()
    end

    local function colorRow(parent, lblTxt, setter)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0
        row.Parent = parent
        reg(row, "bgInput")

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = lblTxt
        lbl.TextColor3 = Color3.fromRGB(225,225,235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local row2 = Instance.new("Frame")
        row2.Size = UDim2.new(1, -24, 0, 24)
        row2.Position = UDim2.new(0, 12, 0, 24)
        row2.BackgroundTransparency = 1
        row2.Parent = row

        local rl = Instance.new("UIListLayout")
        rl.FillDirection = Enum.FillDirection.Horizontal
        rl.Padding = UDim.new(0, 4)
        rl.Parent = row2

        for _, col in ipairs(PALETTE) do
            local s = Instance.new("TextButton")
            s.Size = UDim2.new(0, 24, 0, 24)
            s.BackgroundColor3 = col
            s.BorderSizePixel = 0
            s.Text = ""
            s.AutoButtonColor = false
            s.Parent = row2

            local sc = Instance.new("UICorner")
            sc.CornerRadius = UDim.new(0, 6)
            sc.Parent = s

            s.MouseButton1Click:Connect(function()
                setter(col)
            end)
        end
    end

    local function skinDropdown(parent, txt, values, getter, setter)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 60)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0
        row.Parent = parent
        reg(row, "bgInput")

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 18)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -24, 0, 26)
        holder.Position = UDim2.new(0, 12, 0, 26)
        holder.BackgroundTransparency = 1
        holder.Parent = row

        local hl = Instance.new("UIListLayout")
        hl.FillDirection = Enum.FillDirection.Horizontal
        hl.Padding = UDim.new(0, 4)
        hl.Parent = holder

        local btns = {}
        local function refresh()
            local cur = getter()
            for _, b in ipairs(btns) do
                if b.Val == cur then
                    b.Btn.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
                    b.Btn.TextColor3 = Color3.new(1,1,1)
                else
                    b.Btn.BackgroundColor3 = Color3.fromRGB(45,45,56)
                    b.Btn.TextColor3 = Color3.fromRGB(170,170,190)
                end
            end
        end

        local shown = 0
        for _, v in ipairs(values) do
            if shown >= 4 then break end
            shown = shown + 1
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 70, 1, 0)
            b.BackgroundColor3 = Color3.fromRGB(45,45,56)
            b.BorderSizePixel = 0
            b.Text = v
            b.TextColor3 = Color3.fromRGB(170,170,190)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 9
            b.AutoButtonColor = false
            b.Parent = holder

            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 5)
            bc.Parent = b

            table.insert(btns, {Btn=b, Val=v})
            b.MouseButton1Click:Connect(function()
                setter(v)
                refresh()
            end)
        end
        refresh()
    end

    -- ESP вкладка
    local espTab = makeTab("ESP")
    section(espTab, "ESP")
    toggle(espTab, "ESP", "ESPEnabled")
    toggle(espTab, "Обводка", "Boxes")
    toggle(espTab, "Враги", "ShowEnemies")
    toggle(espTab, "Скрыть союзников", "TeamCheck")
    toggle(espTab, "Проверка видимости", "VisibilityCheck")
    section(espTab, "Инфо")
    toggle(espTab, "Имя", "Names")
    toggle(espTab, "HP", "HealthBar")
    toggle(espTab, "HP цифры", "HealthText")
    toggle(espTab, "Дистанция", "Distance")
    toggle(espTab, "Оружие", "HeldWeapon")
    toggle(espTab, "C4", "BombCarrier")
    section(espTab, "Параметры")
    slider(espTab, "Дальность", "ESPMaxDist", 100, 5000, 100)
    section(espTab, "Цвета ESP")
    colorRow(espTab, "Враги", function(c) Cfg.EnemyColor = c end)
    colorRow(espTab, "Союзники", function(c) Cfg.TeammateColor = c end)

    section(espTab, "CS:GO WH")
    toggle(espTab, "Wallhack включён", "CSW_Enabled")
    toggle(espTab, "Куб", "CSW_ShowBox")
    toggle(espTab, "HP полоса", "CSW_ShowHP")
    toggle(espTab, "Имя WH", "CSW_ShowName")
    toggle(espTab, "Дистанция WH", "CSW_ShowDistance")
    toggle(espTab, "Скрыть союзников WH", "CSW_TeamCheck")
    slider(espTab, "Дальность WH", "CSW_MaxDist", 100, 5000, 100)
    colorRow(espTab, "Цвет WH", function(c) Cfg.CSW_BoxColor = c end)

    -- AIM вкладка
    local aimTab = makeTab("AIM")
    section(aimTab, "Silent Aim")
    toggle(aimTab, "Aim", "SilentEnabled")
    toggle(aimTab, "Враги", "SilentTeamCheck")
    toggle(aimTab, "Видимые", "SilentVisibleOnly")
    toggle(aimTab, "Prediction", "SilentPrediction")
    toggle(aimTab, "Показывать цель", "SilentShowTarget")
    section(aimTab, "Цель")
    optionRow(aimTab, "Часть тела", "SilentTargetPart", {"Head", "Chest", "Closest", "Random"})
    optionRow(aimTab, "Приоритет", "SilentPriority", {"Crosshair", "Distance", "Health"})
    section(aimTab, "Параметры")
    slider(aimTab, "FOV", "SilentFOV", 20, 500, 10)
    slider(aimTab, "Дистанция", "SilentMaxDistance", 100, 3000, 100)
    slider(aimTab, "Шанс", "SilentHitChance", 1, 100, 1)
    slider(aimTab, "Скорость пули", "SilentBulletSpeed", 200, 3000, 100)

    -- Effects вкладка
    local effectsTab = makeTab("EFFECTS")
    section(effectsTab, "Визуальные")
    toggle(effectsTab, "No Flash", "EffectsNoFlash")
    toggle(effectsTab, "No Smoke", "EffectsNoSmoke")

    -- Skins вкладка
    local skinsTab = makeTab("SKINS")
    section(skinsTab, "Skin Changer")
    toggle(skinsTab, "Включить скины", "SkinChangerEnabled")

    local weaponOrder = {"AK-47", "M4A4", "M4A1-S", "AWP", "AUG", "FAMAS", "Glock", "USP-S", "P250", "Desert Eagle"}
    for _, w in ipairs(weaponOrder) do
        local skins = SD.SkinSelections[w]
        if skins then
            skinDropdown(skinsTab, w, skins,
                function() return Cfg.SkinChangerSkins[w] or skins[1] end,
                function(v) Cfg.SkinChangerSkins[w] = v end)
        end
    end

    section(skinsTab, "Нож")
    toggle(skinsTab, "Включить нож", "KnifeChangerEnabled")
    local KM = {"Karambit", "Butterfly Knife", "Flip Knife", "Gut Knife", "M9 Bayonet", "Skeleton Knife", "Stiletto Knife"}
    optionRow(skinsTab, "Модель", "KnifeChangerModel", KM)
    for _, kn in ipairs(KM) do
        local ks = SD.SkinSelections[kn]
        if ks then
            skinDropdown(skinsTab, kn .. " скин", ks,
                function() return Cfg.SkinChangerSkins[kn] or "Vanilla" end,
                function(v) Cfg.SkinChangerSkins[kn] = v end)
        end
    end

    section(skinsTab, "Перчатки")
    toggle(skinsTab, "Включить перчатки", "GloveChangerEnabled")
    local GM = {}
    for k in pairs(SD.GloveSelections) do GM[#GM + 1] = k end
    table.sort(GM)
    if #GM > 0 then
        optionRow(skinsTab, "Модель", "GloveChangerModel", GM)
    end
    for _, gn in ipairs(GM) do
        local gs = SD.GloveSelections[gn]
        if gs then
            skinDropdown(skinsTab, gn .. " скин", gs,
                function() return Cfg.GloveChangerGloves[gn] or "Default" end,
                function(v) Cfg.GloveChangerGloves[gn] = v end)
        end
    end

    -- Visuals вкладка
    local visualTab = makeTab("VISUALS")
    section(visualTab, "Тема")
    colorRow(visualTab, "Цвет меню", function(c)
        Cfg.GuiColor = c
        task.spawn(applyTheme)
        stripe.BackgroundColor3 = c
        fovStroke.Color = c
    end)

    -- Misc
    local miscTab = makeTab("MISC")
    section(miscTab, "Инфо")
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, 0, 0, 70)
    infoLbl.BackgroundColor3 = Color3.fromRGB(30,30,38)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Danny's Cheats\nESP + WH + Aim + Effects + Skins\nLeft Alt — открыть/закрыть\n+ перетаскивается"
    infoLbl.TextColor3 = Color3.fromRGB(180,180,200)
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 10
    infoLbl.TextWrapped = true
    infoLbl.Parent = miscTab

    local infoC = Instance.new("UICorner")
    infoC.CornerRadius = UDim.new(0, 6)
    infoC.Parent = infoLbl
    reg(infoLbl, "bgInput")

    local isMin = false
    local function minimize()
        if isMin then return end
        isMin = true
        Tween:Create(main, TweenInfo.new(0.22), {Size = UDim2.new(0, W, 0, 0)}):Play()
        task.wait(0.22)
        main.Visible = false
        reopenBtn.Visible = true
        reopenBtn.Size = UDim2.new(0, 0, 0, 0)
        Tween:Create(reopenBtn, TweenInfo.new(0.3), {Size = UDim2.new(0, 34, 0, 34)}):Play()
    end
    local function maximize()
        if not isMin then return end
        isMin = false
        reopenBtn.Visible = false
        main.Visible = true
        main.Size = UDim2.new(0, W, 0, 0)
        Tween:Create(main, TweenInfo.new(0.28), {Size = UDim2.new(0, W, 0, H)}):Play()
    end

    minBtn.MouseButton1Click:Connect(minimize)
    reopenBtn.MouseButton1Click:Connect(maximize)

    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.LeftAlt then
            if main.Visible then minimize() else maximize() end
        end
    end)

    switchTab("ESP")
    applyTheme()

    _G.DC_Cleanup = function()
        for p, _ in pairs(ESPs) do destroyESP(p) end
        for p, _ in pairs(WH) do cswRemove(p) end
        pcall(function() gui:Destroy() end)
    end
end

installSilent()
buildGUI()

print("[Danny's Cheats] ESP: OK")
print("[Danny's Cheats] Aim: " .. (Aim.Ready and "OK" or "FAIL"))
print("[Danny's Cheats] Skins: " .. (SD.SkinsRoot and ("OK (" .. #SD.SkinsRoot:GetChildren() .. " категорий)") or "Skins не найдены"))
print("[Danny's Cheats] hookfunction: " .. (hookfunction and "OK" or "не поддерживается"))

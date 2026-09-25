-- Danny's Cheats | Blox Strike v2 (Final + Skin Changer + PasteHub)
-- ESP + CS:GO WH + Silent Aim + Effects + Skin Changer + Tracers/Hitmarker/Chams/Camera/World
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
        h.Adornee = char; h.FillColor = col; h.FillTransparency = 0.92
        h.OutlineColor = col; h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = false; h.Parent = char
        return h
    end)
    if ok and hl then e.HL = hl end

    if head then
        local bb = Instance.new("BillboardGui")
        bb.Adornee = head; bb.Size = UDim2.new(0, 240, 0, 80)
        bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.AlwaysOnTop = true
        bb.Enabled = false; bb.Parent = char

        local function makeLabel(y, size)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, size or 14); l.Position = UDim2.new(0, 0, 0, y)
            l.BackgroundTransparency = 1; l.Text = ""; l.TextColor3 = Cfg.TextColor
            l.TextStrokeTransparency = 0; l.TextStrokeColor3 = Cfg.OutlineColor
            l.TextSize = 11; l.Font = Enum.Font.GothamBold; l.Visible = false
            l.Parent = bb; return l
        end

        local name = makeLabel(0, 20); name.TextSize = 14

        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(0.7, 0, 0, 6); hpBg.Position = UDim2.new(0.5, 0, 0, 24)
        hpBg.AnchorPoint = Vector2.new(0.5, 0); hpBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
        hpBg.BorderSizePixel = 0; hpBg.Visible = false; hpBg.Parent = bb
        local hpBgC = Instance.new("UICorner"); hpBgC.CornerRadius = UDim.new(1,0); hpBgC.Parent = hpBg
        local hpBgS = Instance.new("UIStroke"); hpBgS.Color = Cfg.OutlineColor
        hpBgS.Thickness = 1.5; hpBgS.Transparency = 0.2; hpBgS.Parent = hpBg

        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = Cfg.HealthHighColor
        hpFill.BorderSizePixel = 0; hpFill.Parent = hpBg
        local hpFillC = Instance.new("UICorner"); hpFillC.CornerRadius = UDim.new(1,0); hpFillC.Parent = hpFill

        local hpText = makeLabel(32)
        local dist = makeLabel(46)
        local weapon = makeLabel(60, 12)

        e.BB = bb; e.Name = name; e.HP = hpBg; e.HPFill = hpFill
        e.HPText = hpText; e.Dist = dist; e.Weapon = weapon
    end
    ESPs[player] = e
end

local function updateESP()
    for p, e in pairs(ESPs) do
        local c = matchChar(p)
        if not c or c ~= e.Char or not select(1, teamAllowed(p)) then destroyESP(p) end
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
                if vis and Cfg.VisibleColor then
                    local rp = RaycastParams.new()
                    rp.FilterType = Enum.RaycastFilterType.Exclude
                    rp.FilterDescendantsInstances = {LP.Character}
                    local hit = workspace:Raycast(Cam.CFrame.Position, a.Position - Cam.CFrame.Position, rp)
                    if hit and hit.Instance:IsDescendantOf(c) then color = Cfg.InSightColor end
                end
                if e.HL then
                    e.HL.Enabled = vis and Cfg.Boxes
                    e.HL.FillColor = color; e.HL.OutlineColor = color
                end
                if e.BB then e.BB.Enabled = vis end
                if e.Name then
                    local dn = p.DisplayName ~= "" and p.DisplayName or p.Name
                    e.Name.Text = dn; e.Name.TextColor3 = color
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
                    elseif e.HPText then e.HPText.Text = "" end
                    e.HP.Visible = vis and Cfg.HealthBar and show
                    if e.HPText then e.HPText.Visible = vis and Cfg.HealthText and show end
                end
                if e.Weapon then
                    local wn, hb = equipmentOf(p)
                    if hb then
                        e.Weapon.Text = "C4"; e.Weapon.TextColor3 = Color3.fromRGB(255,195,80)
                        e.Weapon.Visible = vis and Cfg.BombCarrier
                    elseif wn and #wn > 0 then
                        e.Weapon.Text = wn; e.Weapon.TextColor3 = Color3.fromRGB(217,226,242)
                        e.Weapon.Visible = vis and Cfg.HeldWeapon
                    else e.Weapon.Text = ""; e.Weapon.Visible = false end
                end
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not ESPs[p] then
            if select(1, teamAllowed(p)) and matchChar(p) then createESP(p) end
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
    cswHideAll(e); task.defer(function() cswDestroy(e) end)
    WH[player] = nil
end

local function cswCreate(player)
    if player == LP then return end
    if not matchChar(player) then return end
    if not Drawing or type(Drawing.new) ~= "function" then return end
    local e = { BoxLines = {} }
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Visible = false; l.Color = Cfg.CSW_BoxColor
        l.Thickness = Cfg.CSW_Thickness; l.Transparency = 1
        table.insert(e.BoxLines, l)
    end
    local hpBg = Drawing.new("Square")
    hpBg.Visible = false; hpBg.Filled = true
    hpBg.Color = Color3.fromRGB(0,0,0); hpBg.Transparency = 1
    e.HPBg = hpBg
    local hpFill = Drawing.new("Square")
    hpFill.Visible = false; hpFill.Filled = true
    hpFill.Color = Cfg.CSW_HPFullColor; hpFill.Transparency = 1
    e.HPFill = hpFill
    local nameText = Drawing.new("Text")
    nameText.Visible = false; nameText.Center = true; nameText.Outline = true
    nameText.OutlineColor = Color3.new(0,0,0); nameText.Color = Cfg.TextColor
    nameText.Size = 14; nameText.Font = 2
    e.NameText = nameText
    local distText = Drawing.new("Text")
    distText.Visible = false; distText.Center = true; distText.Outline = true
    distText.OutlineColor = Color3.new(0,0,0); distText.Color = Cfg.TextColor
    distText.Size = 12; distText.Font = 2
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
    if not char then cswHideAll(e); return false end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    if not hrp then cswHideAll(e); return false end
    local extents
    pcall(function() extents = char:GetExtentsSize() end)
    if not extents then extents = Vector3.new(2, 6, 1) end
    local center = hrp.Position
    local headPos = center + Vector3.new(0, extents.Y/2, 0)
    local feetPos = center - Vector3.new(0, extents.Y/2, 0)
    local headScreen = cswWorldToScreen(headPos)
    local feetScreen = cswWorldToScreen(feetPos)
    if not headScreen or not feetScreen then cswHideAll(e); return true end
    local dist = (Cam.CFrame.Position - hrp.Position).Magnitude
    if dist > Cfg.CSW_MaxDist then cswHideAll(e); return true end
    if not e.SmoothHead then
        e.SmoothHead = headScreen; e.SmoothFeet = feetScreen
    else
        e.SmoothHead = e.SmoothHead:Lerp(headScreen, 0.3)
        e.SmoothFeet = e.SmoothFeet:Lerp(feetScreen, 0.3)
    end
    local top = e.SmoothHead.Y; local bottom = e.SmoothFeet.Y
    local height = bottom - top; local width = height * 0.55
    local left = e.SmoothHead.X - width/2; local right = e.SmoothHead.X + width/2
    if Cfg.CSW_ShowBox then
        local corners = {
            {Vector2.new(left, top), Vector2.new(right, top)},
            {Vector2.new(left, bottom), Vector2.new(right, bottom)},
            {Vector2.new(left, top), Vector2.new(left, bottom)},
            {Vector2.new(right, top), Vector2.new(right, bottom)},
        }
        for i, pair in ipairs(corners) do
            local line = e.BoxLines[i]
            line.From = pair[1]; line.To = pair[2]
            line.Color = Cfg.CSW_BoxColor; line.Thickness = Cfg.CSW_Thickness
            line.Visible = true
        end
    else for _, line in ipairs(e.BoxLines) do line.Visible = false end end
    if Cfg.CSW_ShowHP then
        local barX = right + 4; local barW = 3; local barH = height
        local hpPct = math.clamp(hp/maxHp, 0, 1)
        e.HPBg.Size = Vector2.new(barW, barH); e.HPBg.Position = Vector2.new(barX, top)
        e.HPBg.Color = Color3.new(0,0,0); e.HPBg.Visible = true
        e.HPFill.Size = Vector2.new(barW, barH*hpPct)
        e.HPFill.Position = Vector2.new(barX, bottom - barH*hpPct)
        e.HPFill.Color = Cfg.CSW_HPLowColor:Lerp(Cfg.CSW_HPFullColor, hpPct)
        e.HPFill.Visible = true
    else e.HPBg.Visible = false; e.HPFill.Visible = false end
    if Cfg.CSW_ShowName then
        e.NameText.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
        e.NameText.Position = Vector2.new((left+right)/2, top-18); e.NameText.Visible = true
    else e.NameText.Visible = false end
    if Cfg.CSW_ShowDistance then
        e.DistText.Text = string.format("%.0f m", dist)
        e.DistText.Position = Vector2.new((left+right)/2, bottom+4); e.DistText.Visible = true
    else e.DistText.Visible = false end
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
            obj.Enabled = false; obj.Brightness = 0; obj.Contrast = 0
        elseif obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
            if not Effects.Records[obj] then Effects.Records[obj] = {Kind=obj.ClassName, Enabled=obj.Enabled} end
            obj.Enabled = false
        end
    end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            local n = gui.Name:lower()
            if n:find("flash") or n:find("blind") or n:find("whiteout") or n:find("bang") or n:find("stun") or n:find("fade") then
                if gui:IsA("ScreenGui") then
                    if not Effects.Records[gui] then Effects.Records[gui] = {Kind="Gui", Enabled=gui.Enabled} end
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
                if not Effects.Records[obj] then Effects.Records[obj] = {Kind="P", Enabled=obj.Enabled} end
                obj.Enabled = false
            end
        elseif obj:IsA("Smoke") or obj:IsA("Fire") then
            if not Effects.Records[obj] then Effects.Records[obj] = {Kind="S", Enabled=obj.Enabled} end
            obj.Enabled = false
        elseif obj:IsA("BasePart") then
            local n = obj.Name:lower()
            local pn = obj.Parent and obj.Parent.Name:lower() or ""
            if n:find("smoke") or pn:find("smoke") then
                if not Effects.Records[obj] then Effects.Records[obj] = {Kind="T", Transparency=obj.Transparency} end
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
        for _, c in ipairs(avail) do if Aim.Target and c.Part == Aim.Target.Part then return c end end
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

installSilent()

-- ========== SKIN CHANGER (твой оригинал) ==========
local SD = { SkinsRoot = nil, SkinSelections = {}, GloveSelections = {}, GloveFolders = {} }
pcall(function()
    SD.SkinsRoot = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Skins")
end)

if SD.SkinsRoot then
    pcall(function()
        for _, wf in ipairs(SD.SkinsRoot:GetChildren()) do
            local skins = {}
            for _, sf in ipairs(wf:GetChildren()) do skins[#skins + 1] = sf.Name end
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
    for _, skin in ipairs(gf:GetChildren()) do skins[#skins + 1] = skin.Name end
    SD.GloveSelections[gf.Name] = skins
end

for w, s in pairs(SD.SkinSelections) do Cfg.SkinChangerSkins[w] = s[1] or "Default" end
for _, gf in ipairs(SD.GloveFolders) do Cfg.GloveChangerGloves[gf.Name] = "Default" end

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
                    local newKnife = Cfg.KnifeChangerModel
                    local newSkin = Cfg.SkinChangerSkins[newKnife] or "Vanilla"
                    local ok, result = pcall(oGCM, newKnife, newSkin, ...)
                    if ok and result then return result end
                end
                local ok, result = pcall(oGCM, w, sk, ...)
                if ok then return result end
                return nil
            end
        end
        local oGChM = Sk.GetCharacterModel
        if oGChM then
            Sk.GetCharacterModel = function(w, sk, ...)
                if Cfg.KnifeChangerEnabled and w and Checkknife(w) then
                    local newKnife = Cfg.KnifeChangerModel
                    local newSkin = Cfg.SkinChangerSkins[newKnife] or "Vanilla"
                    local ok, result = pcall(oGChM, newKnife, newSkin, ...)
                    if ok and result then return result end
                end
                local ok, result = pcall(oGChM, w, sk, ...)
                if ok then return result end
                return nil
            end
        end
        local oVN = Vm.new
        if oVN then
            Vm.new = function(vc, w, sk, ...)
                if Cfg.KnifeChangerEnabled and w and Checkknife(w) then
                    local newKnife = Cfg.KnifeChangerModel
                    local newSkin = Cfg.SkinChangerSkins[newKnife] or "Vanilla"
                    local ok, result = pcall(oVN, vc, newKnife, newSkin, ...)
                    if ok and result then return result end
                end
                local ok, result = pcall(oVN, vc, w, sk, ...)
                if ok then return result end
                return nil
            end
        end
        if Sk.GetGloves then
            local oGG = Sk.GetGloves
            Sk.GetGloves = function(g, sk)
                if Cfg.GloveChangerEnabled and Cfg.GloveChangerModel then
                    local gModel = Cfg.GloveChangerModel
                    local ts = Cfg.GloveChangerGloves[gModel] or "Default"
                    local ok, result = pcall(oGG, gModel, ts)
                    if ok and result then return result end
                end
                local ok, result = pcall(oGG, g, sk)
                if ok then return result end
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
        if ch:IsA("Model") and ch.Name ~= "Arms" and ch.Name ~= "Viewmodel" then return ch end
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
        if Cfg.KnifeChangerEnabled then ewn = Cfg.KnifeChangerModel ca = true end
    else
        if Cfg.SkinChangerEnabled then ca = true end
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
        if ch:IsA("Model") and (ch.Name:match("Arms") or ch:FindFirstChild("Right Arm")) then am = ch; break end
    end
    if not am then return end
    local la = am:FindFirstChild("Left Arm")
    local ra = am:FindFirstChild("Right Arm")
    if not la or not ra then return end
    local lg = la:FindFirstChild("Glove")
    local rg = ra:FindFirstChild("Glove")
    if not lg or not rg then return end
    for _, old in pairs(lg:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
    for _, old in pairs(rg:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
    local selectedModel = Cfg.GloveChangerModel
    if not selectedModel then return end
    local sel = Cfg.GloveChangerGloves[selectedModel]
    if not sel or sel == "Default" then return end
    local gloveSkinFolder = SD.SkinsRoot:FindFirstChild(selectedModel)
    if not gloveSkinFolder then return end
    local skinVariant = gloveSkinFolder:FindFirstChild(sel)
    if not skinVariant then return end
    local cameraFolder = skinVariant:FindFirstChild("Camera")
    if not cameraFolder then return end
    local factoryNew = cameraFolder:FindFirstChild("Factory New")
    if not factoryNew then return end
    for _, sa in pairs(factoryNew:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            sa:Clone().Parent = lg
            sa:Clone().Parent = rg
        end
    end
end

-- ========== ОРИГИНАЛЬНЫЕ ЦИКЛЫ ==========
task.spawn(function()
    while task.wait(0.05) do
        if not Cfg.SilentEnabled or not Aim.Ready then Aim.Target = nil
        else
            local cam = workspace.CurrentCamera
            if cam and aimAllowed() then Aim.Target = selectTarget(cam, cam.CFrame.Position, Cfg.SilentMaxDistance, false)
            else Aim.Target = nil end
        end
    end
end)
task.spawn(function() while task.wait(0.15) do pcall(updateESP) end end)
task.spawn(function()
    while task.wait(0.03) do
        if not Cfg.CSW_Enabled then for _, e in pairs(WH) do cswHideAll(e) end
        else
            local toRemove = {}
            for p, e in pairs(WH) do
                if not Players:FindFirstChild(p.Name) then table.insert(toRemove, p)
                else
                    local valid = cswUpdate(p, e)
                    if not valid then table.insert(toRemove, p) end
                end
            end
            for _, p in ipairs(toRemove) do cswRemove(p) end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and not WH[p] then
                    if cswTeamAllowed(p) and matchChar(p) then cswCreate(p) end
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
            if Cfg.SkinChangerEnabled or Cfg.KnifeChangerEnabled then ApplySkin() end
            if Cfg.GloveChangerEnabled then ApplyGloves() end
        end)
    end
end)
connect(Players.PlayerRemoving, function(p) destroyESP(p) cswRemove(p) end)

-- ========== FOV Circle ==========
local aimGui = Instance.new("ScreenGui")
aimGui.Name = "DC_FOV"; aimGui.ResetOnSpawn = false
aimGui.IgnoreGuiInset = true; aimGui.DisplayOrder = 98
aimGui.Parent = LP:WaitForChild("PlayerGui")

local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, Cfg.SilentFOV * 2, 0, Cfg.SilentFOV * 2)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5); fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1; fovCircle.Parent = aimGui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Cfg.GuiColor; fovStroke.Thickness = 1.5; fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner"); fovCorner.CornerRadius = UDim.new(1, 0); fovCorner.Parent = fovCircle

local targetRing = Instance.new("Frame")
targetRing.Size = UDim2.new(0, 26, 0, 26); targetRing.AnchorPoint = Vector2.new(0.5, 0.5)
targetRing.BackgroundTransparency = 1; targetRing.Visible = false; targetRing.Parent = aimGui

local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Cfg.InSightColor; ringStroke.Thickness = 3; ringStroke.Parent = targetRing

local ringCorner = Instance.new("UICorner"); ringCorner.CornerRadius = UDim.new(1, 0); ringCorner.Parent = targetRing

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
        else targetRing.Visible = false end
    else targetRing.Visible = false end
end)

-- ===== ЧАСТЬ 2 (логика) и ЧАСТЬ 3 (GUI) идут далее =====
-- =========================================================================
-- [ ЧАСТЬ 2 — ОБРАБОТЧИКИ PASTEHUB ]
-- =========================================================================

local PH_Sound = game:GetService("SoundService")
local PH_Lighting = game:GetService("Lighting")

-- Дополнительная таблица настроек для новых функций
local PCfg = {
    -- Tracers
    BulletTracers=false, TracerRainbow=false, TracerStyle="Block",
    TracerColor=Color3.fromRGB(0,170,255), TracerTime=2,
    BulletImpacts=false, BulletImpactsColor=Color3.fromRGB(255,0,0),
    -- Hitmarker
    HitMarkerEnabled=false, HitMarkerRainbow=false,
    HitMarkerColor=Color3.fromRGB(255,255,255),
    HitMarkerDuration=2, HitMarkerSpinSpeed=720,
    HitMarkerSize=25, HitMarkerThickness=2,
    -- Hit Sound
    HitSoundEnabled=false, CustomHitSoundToggle=false,
    HitSoundVolume=1, HitSoundPreset="Neverlose", CustomHitSoundID="",
    -- Custom Hands
    CustomHandsEnabled=false, HandsX=0.2, HandsY=-0.155, HandsZ=0.075,
    -- Weapon Chams
    WeaponChamsEnabled=false, WeaponChamsColor=Color3.fromRGB(0,150,255),
    WeaponChamsMode="Glass", GlassTransparency=0.4, MetalReflectance=1.0,
    -- Camera
    CustomFovToggle=false, FovAmount=90,
    ThirdPerson=false, ThirdPersonDist=10,
    -- Scope
    CustomScopeFov=false, ScopeFovValue=70, RemoveScope=false,
    CustomScopeCrosshair=false, ScopeCrosshairColor=Color3.fromRGB(255,255,255),
    ScopeCrosshairThickness=2, ScopeCrosshairLengthLR=150, ScopeCrosshairLengthTB=100,
    -- Movement
    AutoBhop=false, BhopSpeed=18, NoFallDamage=false,
    -- Penetration
    ShowPenetration=false,
    -- World
    EnableSkybox=false, SkyboxPreset="Night", WeatherType="None",
    EnableTime=false, WorldClockTime=12,
    EnableBrightness=false, WorldBrightness=2,
    EnableColors=false, WorldAmbient=Color3.fromRGB(127,127,127),
    WorldOutdoorAmbient=Color3.fromRGB(127,127,127),
    Atmosphere=false, AtmosphereDensity=0.3, SubAtmosphereHaze=0, AtmosphereGlare=0,
    EnableColorCorrection=false, SaturationSlider=0, ContrastSlider=0,
    -- Chams V3
    ChamsEnabled=false, ChamsTeamCheck=true,
    ChamsMaterialVisible="Neon", ChamsColorVisible=Color3.fromRGB(0,200,0),
    ChamsAlphaVisible=0.3, ChamsOutlineAlphaVisible=0,
    ChamsMaterialUnvisible="Metal", ChamsColorUnvisible=Color3.fromRGB(200,0,0),
    ChamsAlphaUnvisible=0.3, ChamsOutlineAlphaUnvisible=0,
    -- Weapon
    Firerate=false, FirerateSlider=0.01, NoRecoil=false, NoSpread=false,
    InstantReload=false, Antiflashbang=false, Antismoke=false,
    -- Grenade
    GrenadeTracers=false, GrenadeTracerColor=Color3.fromRGB(255,100,0),
    MolotovZoneESP=false, GrenadeZoneColor=Color3.fromRGB(255,60,0),
    SmokeZoneESP=false, SmokeZoneColor=Color3.fromRGB(180,180,180),
    -- World Color
    WorldColorToggle=false, WorldColorPicker=Color3.fromRGB(255,255,255),
    SkyColorToggle=false, SkyColorPicker=Color3.fromRGB(255,255,255),
}

-- ============ HIT SOUND ============
local PH_HitSoundPresets = {
    Neverlose="rbxassetid://139452805868562", Skeet="rbxassetid://83717596220569",
    Bell="rbxassetid://96481309571950", Bell2="rbxassetid://124010691633262",
    Bubble="rbxassetid://104824514322839", Rust="rbxassetid://1255040462",
    Agro1="rbxassetid://132463144859699", Agro2="rbxassetid://102651850556408",
    Coins="rbxassetid://5613553529", Schaater="rbxassetid://17405655409",
    Pick="rbxassetid://8616930816",
}
local function PH_PlayHitSound()
    pcall(function()
        if not PCfg.HitSoundEnabled then return end
        local sid = ""
        if PCfg.CustomHitSoundToggle and PCfg.CustomHitSoundID ~= "" then
            local ci = PCfg.CustomHitSoundID
            if not ci:find("rbxassetid://") then
                local clean = ci:gsub("%D","")
                if clean ~= "" then sid = "rbxassetid://"..clean end
            else sid = ci end
        end
        if sid == "" then sid = PH_HitSoundPresets[PCfg.HitSoundPreset] or PH_HitSoundPresets.Neverlose end
        local s = Instance.new("Sound")
        s.SoundId = sid; s.Volume = PCfg.HitSoundVolume or 1
        s.Parent = PH_Sound; s:Play()
        task.spawn(function() s.Ended:Wait(); s:Destroy() end)
    end)
end

-- ============ HITMARKER ============
local PH_activeHitMarkers = {}
local function PH_TriggerHitMarker(hitPos)
    if not PCfg.HitMarkerEnabled then return end
    local lines = {}
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Thickness = PCfg.HitMarkerThickness; l.Transparency = 1; l.Visible = false
        lines[i] = l
    end
    table.insert(PH_activeHitMarkers, {
        lines=lines, worldPos=hitPos, spawnTick=tick(),
        expireTick=tick()+PCfg.HitMarkerDuration
    })
end
task.spawn(function()
    while task.wait() do
        local now = tick()
        local col = PCfg.HitMarkerColor
        if PCfg.HitMarkerRainbow then col = Color3.fromHSV((now%5)/5,1,1) end
        local pf = 1 + 0.35*math.sin(now*math.pi)
        local cs = PCfg.HitMarkerSize * pf
        local gap = 6 * pf
        for i = #PH_activeHitMarkers, 1, -1 do
            local d = PH_activeHitMarkers[i]
            if not PCfg.HitMarkerEnabled or now > d.expireTick then
                for _,l in ipairs(d.lines) do pcall(function() l:Remove() end) end
                table.remove(PH_activeHitMarkers, i)
            else
                local sp, on = Cam:WorldToViewportPoint(d.worldPos)
                if on and sp.Z > 0 then
                    local c = Vector2.new(sp.X, sp.Y)
                    local lt = now - d.spawnTick
                    local a = math.rad((lt * PCfg.HitMarkerSpinSpeed) % 360)
                    for j = 1, 4 do
                        local l = d.lines[j]
                        l.Color = col; l.Thickness = PCfg.HitMarkerThickness
                        local ang = a + math.rad((j-1)*90)
                        local ca, sa = math.cos(ang), math.sin(ang)
                        l.From = c + Vector2.new(ca*gap, sa*gap)
                        l.To = c + Vector2.new(ca*(gap+cs), sa*(gap+cs))
                        l.Visible = true
                    end
                else for _,l in ipairs(d.lines) do l.Visible = false end end
            end
        end
    end
end)

-- ============ PENETRATION ============
local PH_MaterialLimits = {
    [Enum.Material.Asphalt]=0.25,[Enum.Material.Basalt]=0.25,[Enum.Material.Brick]=0.25,
    [Enum.Material.Cobblestone]=0.25,[Enum.Material.Concrete]=0.25,[Enum.Material.CrackedLava]=0.25,
    [Enum.Material.DiamondPlate]=0.25,[Enum.Material.Foil]=0.25,[Enum.Material.Glacier]=0.25,
    [Enum.Material.Granite]=0.25,[Enum.Material.Grass]=0.25,[Enum.Material.Ground]=0.25,
    [Enum.Material.Ice]=0.25,[Enum.Material.LeafyGrass]=0.25,[Enum.Material.Limestone]=0.25,
    [Enum.Material.Marble]=0.25,[Enum.Material.Metal]=0.25,[Enum.Material.Mud]=0.25,
    [Enum.Material.Pavement]=0.25,[Enum.Material.Rock]=0.25,[Enum.Material.Salt]=0.25,
    [Enum.Material.Sand]=0.25,[Enum.Material.Sandstone]=0.25,[Enum.Material.Slate]=0.25,
    [Enum.Material.Snow]=0.25,[Enum.Material.ForceField]=0.25,[Enum.Material.Neon]=0.25,
    [Enum.Material.CorrodedMetal]=0.25,[Enum.Material.Pebble]=0.25,[Enum.Material.CeramicTiles]=0.25,
    [Enum.Material.Plaster]=0.25,[Enum.Material.Plastic]=7,[Enum.Material.SmoothPlastic]=7,
    [Enum.Material.Wood]=7,[Enum.Material.WoodPlanks]=7,[Enum.Material.Cardboard]=7,
    [Enum.Material.Glass]=100,[Enum.Material.Fabric]=100,
}
local PH_MatVarLimits = { ["IndoorWall"]=0.25, ["Sandy Brick"]=0.25 }
local function PH_GetPenStats(origin, direction, maxPen, ignoreList, targetRoot)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.CollisionGroup = "Bullet"
    local filter = ignoreList or {LP.Character, Cam}
    params.FilterDescendantsInstances = filter
    local co, cd = origin, direction
    local accMat, accVar = {}, {}
    local stats = {TotalThickness=0,MaterialStats={},Success=false,FailReason="Max Steps",EndPos=Vector3.zero}
    local bp = RaycastParams.new()
    bp.FilterType = Enum.RaycastFilterType.Include
    bp.CollisionGroup = "Bullet"
    for i = 1, 100 do
        if not co or not cd then break end
        local r = workspace:Raycast(co, cd*1000, params)
        if not r then
            if not targetRoot then stats.Success=true; stats.EndPos=co+(cd*1000)
            else stats.FailReason="Void" end
            break
        end
        if not r.Instance or not r.Instance.Parent then stats.FailReason="Destroyed"; break end
        if targetRoot and r.Instance:IsDescendantOf(targetRoot) then
            stats.Success=true; stats.EndPos=r.Position; stats.FailReason="Hit"; return stats
        end
        table.insert(filter, r.Instance)
        params.FilterDescendantsInstances = filter
        local ep = r.Position
        local fe = ep + (cd*1000)
        bp.FilterDescendantsInstances = {r.Instance}
        local br = workspace:Raycast(fe, ep-fe, bp)
        local thick, limit = 0.5, 0.25
        if not br then thick=5; stats.FailReason="Infinite"
        else
            thick = (ep - br.Position).Magnitude
            local variant = br.Instance.MaterialVariant
            if variant ~= "" and PH_MatVarLimits[variant] then
                limit = PH_MatVarLimits[variant]
                accVar[variant] = (accVar[variant] or 0) + thick
                if accVar[variant] > limit + maxPen then stats.FailReason="Var"; return stats end
            else
                local mat = br.Material
                limit = PH_MaterialLimits[mat] or 0.25
                accMat[mat] = (accMat[mat] or 0) + thick
                if accMat[mat] > limit + maxPen then stats.FailReason="Mat"; return stats end
            end
            co = br.Position
        end
        stats.TotalThickness = stats.TotalThickness + thick
    end
    return stats
end
task.spawn(function()
    local PenText = Drawing.new("Text")
    PenText.Visible=false; PenText.Center=true; PenText.Size=18
    PenText.Font=2; PenText.Color=Color3.fromRGB(0,255,0); PenText.Outline=true
    local penParams = RaycastParams.new()
    penParams.FilterType = Enum.RaycastFilterType.Exclude
    penParams.CollisionGroup = "Bullet"
    RunService.RenderStepped:Connect(function()
        if not PCfg.ShowPenetration or not Cam then PenText.Visible=false; return end
        PenText.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2 - 70)
        penParams.FilterDescendantsInstances = {LP.Character, Cam}
        local res = workspace:Raycast(Cam.CFrame.Position, Cam.CFrame.LookVector*1000, penParams)
        if res then
            local st = PH_GetPenStats(Cam.CFrame.Position, Cam.CFrame.LookVector, 4, {LP.Character, Cam}, nil)
            if st.Success then
                PenText.Visible=true
                PenText.Text=string.format("WALLBANG: YES\n(%.1f studs)", st.TotalThickness or 0)
                PenText.Color=Color3.fromRGB(0,255,0)
            else
                PenText.Visible=true; PenText.Text="WALLBANG: NO"; PenText.Color=Color3.fromRGB(255,0,0)
            end
        else PenText.Visible=false end
    end)
end)

-- ============ CUSTOM HANDS ============
RunService.RenderStepped:Connect(function()
    pcall(function()
        if not PCfg.CustomHandsEnabled then return end
        for _, ch in ipairs(Cam:GetChildren()) do
            if ch:IsA("Model") then
                local sf = ch:FindFirstChild("Stats")
                if sf then
                    local d = sf:FindFirstChild("Default")
                    if d and d:IsA("Vector3Value") then
                        d.Value = Vector3.new(PCfg.HandsX, PCfg.HandsY, PCfg.HandsZ)
                    end
                end
            end
        end
    end)
end)

-- ============ WEAPON CHAMS ============
local PH_activeWeaponHLs = {}
RunService.RenderStepped:Connect(function()
    pcall(function()
        local en = PCfg.WeaponChamsEnabled
        local mode = PCfg.WeaponChamsMode
        local color = PCfg.WeaponChamsColor
        local wm = nil
        for _, ch in ipairs(Cam:GetChildren()) do
            if ch:IsA("Model") and ch.Name ~= "Viewmodel" and not ch.Name:lower():find("light") then
                local w = ch:FindFirstChild("Weapon") or ch
                if w:IsA("Model") and w.Name ~= "Viewmodel" and not w.Name:lower():find("light") then
                    wm = w; break
                end
            end
        end
        if not en or not wm then
            for _, h in pairs(PH_activeWeaponHLs) do if h and h.Parent then h:Destroy() end end
            PH_activeWeaponHLs = {}; return
        end
        local curParts = {}
        for _, part in ipairs(wm:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "Hitbox" and part.Name ~= "HumanoidRootPart" then
                if part.Name == "ViewmodelLight" or part:FindFirstAncestor("ViewmodelLight") then continue end
                pcall(function()
                    if mode == "Highlight" then
                        curParts[part] = true
                        local h = part:FindFirstChild("WeaponChamsHighlight")
                        if not h then
                            h = Instance.new("Highlight")
                            h.Name = "WeaponChamsHighlight"; h.Adornee = part; h.Parent = part
                            h.FillTransparency = 0; h.OutlineTransparency = 1
                            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            table.insert(PH_activeWeaponHLs, h)
                        end
                        h.FillColor = color
                    else
                        local h = part:FindFirstChild("WeaponChamsHighlight")
                        if h then h:Destroy() end
                        if mode ~= "Neon" then
                            for _, v in ipairs(part:GetChildren()) do
                                if v:IsA("SurfaceAppearance") or v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
                            end
                        end
                        if mode == "Glass" then part.Material=Enum.Material.Glass; part.Color=color; part.Transparency=PCfg.GlassTransparency
                        elseif mode == "ForceField" then part.Material=Enum.Material.ForceField; part.Color=color; part.Transparency=0
                        elseif mode == "Metal" then part.Material=Enum.Material.Metal; part.Color=color; part.Reflectance=PCfg.MetalReflectance; part.Transparency=0
                        elseif mode == "Neon" then part.Material=Enum.Material.Neon; part.Color=color; part.Transparency=0 end
                    end
                end)
            end
        end
        if mode == "Highlight" then
            for i = #PH_activeWeaponHLs, 1, -1 do
                local h = PH_activeWeaponHLs[i]
                if not h or not h.Parent or not curParts[h.Adornee] then
                    if h then h:Destroy() end
                    table.remove(PH_activeWeaponHLs, i)
                end
            end
        end
    end)
end)

-- ============ BHOP / NO FALL ============
local function PH_GetMoveDir()
    local d = Vector3.zero
    local lv = Cam.CFrame.LookVector; local rv = Cam.CFrame.RightVector
    if UIS:IsKeyDown(Enum.KeyCode.W) then d += lv end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d -= lv end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d -= rv end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d += rv end
    if d.Magnitude > 0 then return Vector3.new(d.X,0,d.Z).Unit end
    return Vector3.zero
end
RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum then return end
        if PCfg.AutoBhop then
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = {char}
                rp.FilterType = Enum.RaycastFilterType.Exclude
                if workspace:Raycast(root.Position, Vector3.new(0,-4,0), rp) then hum.Jump = true end
            end
            local dir = PH_GetMoveDir()
            if dir.Magnitude > 0 then
                local spd = math.clamp(PCfg.BhopSpeed, 5, 30)
                local d = dir * spd
                local v = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(v.X+(d.X-v.X)*0.2, v.Y, v.Z+(d.Z-v.Z)*0.2)
            end
        end
    end)
end)
RunService.Heartbeat:Connect(function()
    pcall(function()
        if PCfg.NoFallDamage then
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end
            end
        end
    end)
end)

-- ============ FOV / THIRD PERSON ============
RunService.RenderStepped:Connect(function()
    pcall(function()
        if PCfg.CustomFovToggle and Cam then Cam.FieldOfView = PCfg.FovAmount end
        if PCfg.ThirdPerson then
            local dd = math.clamp(PCfg.ThirdPersonDist, 5, 50)
            LP.CameraMode = Enum.CameraMode.Classic
            LP.CameraMaxZoomDistance = dd
            LP.CameraMinZoomDistance = dd
        end
    end)
end)

-- ============ CUSTOM SCOPE ============
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "DC_ScopeCrosshair"; sg.ResetOnSpawn = false
    pcall(function() sg.Parent = CoreGui end)
    local cont = Instance.new("Frame", sg)
    cont.BackgroundTransparency = 1
    cont.AnchorPoint = Vector2.new(0.5,0.5)
    cont.Position = UDim2.new(0.5,0,0.5,0)
    cont.Size = UDim2.new(0,0,0,0)
    local lL=Instance.new("Frame",cont); lL.AnchorPoint=Vector2.new(1,0.5); lL.BorderSizePixel=0
    local rL=Instance.new("Frame",cont); rL.AnchorPoint=Vector2.new(0,0.5); rL.BorderSizePixel=0
    local tL=Instance.new("Frame",cont); tL.AnchorPoint=Vector2.new(0.5,1); tL.BorderSizePixel=0
    local bL=Instance.new("Frame",cont); bL.AnchorPoint=Vector2.new(0.5,0); bL.BorderSizePixel=0
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local isScoped = false
            local pg = LP:FindFirstChild("PlayerGui")
            if pg then
                local s, sc = pcall(function() return pg.MainGui.Gameplay.Middle.SniperScope end)
                if s and sc and sc.Visible then isScoped = true end
            end
            local en = PCfg.CustomScopeCrosshair and isScoped
            cont.Visible = en
            if en then
                local c = PCfg.ScopeCrosshairColor
                lL.BackgroundColor3=c; rL.BackgroundColor3=c; tL.BackgroundColor3=c; bL.BackgroundColor3=c
                local t = PCfg.ScopeCrosshairThickness
                lL.Size=UDim2.new(0,PCfg.ScopeCrosshairLengthLR,0,t); lL.Position=UDim2.new(0,0,0,0)
                rL.Size=UDim2.new(0,PCfg.ScopeCrosshairLengthLR,0,t); rL.Position=UDim2.new(0,0,0,0)
                tL.Size=UDim2.new(0,t,0,PCfg.ScopeCrosshairLengthTB); tL.Position=UDim2.new(0,0,0,0)
                bL.Size=UDim2.new(0,t,0,PCfg.ScopeCrosshairLengthTB); bL.Position=UDim2.new(0,0,0,0)
            end
        end)
    end)
end)
task.spawn(function()
    local cached
    RunService.RenderStepped:Connect(function()
        if cached and not cached.Parent then cached = nil end
        if not cached then
            local pg = LP:FindFirstChild("PlayerGui")
            if pg then
                local s, sc = pcall(function() return pg.MainGui.Gameplay.Middle.SniperScope end)
                if s and sc then cached = sc end
            end
        end
        if not PCfg.RemoveScope then
            if cached and cached.Size ~= UDim2.new(1,0,1,0) then cached.Size = UDim2.new(1,0,1,0) end
            return
        end
        if cached then
            if cached.Visible then cached.Size = UDim2.new(0,0,0,0)
            else if cached.Size ~= UDim2.new(1,0,1,0) then cached.Size = UDim2.new(1,0,1,0) end end
        end
    end)
end)
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        pcall(function()
            if PCfg.CustomScopeFov and Cam then
                local pg = LP:FindFirstChild("PlayerGui")
                if pg then
                    local sc = pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("Gameplay") and pg.MainGui.Gameplay:FindFirstChild("Middle") and pg.MainGui.Gameplay.Middle:FindFirstChild("SniperScope")
                    if sc and sc.Visible then Cam.FieldOfView = PCfg.ScopeFovValue end
                end
            end
        end)
    end)
end)

-- ============ SKYBOX ============
local PH_Skybox = {
    Night={Bk="rbxassetid://1514717643",Dn="rbxassetid://1514716936",Ft="rbxassetid://1514715910",Lf="rbxassetid://1514714945",Rt="rbxassetid://1514714011",Up="rbxassetid://1514713374"},
    ["Ocean Sunset"]={Bk="rbxassetid://17525686840",Dn="rbxassetid://17525678473",Ft="rbxassetid://17525684686",Lf="rbxassetid://17525680663",Rt="rbxassetid://17525682665",Up="rbxassetid://17525674545"},
    Standard={Bk="http://www.roblox.com/asset/?id=91458024",Dn="http://www.roblox.com/asset/?id=91457980",Ft="http://www.roblox.com/asset/?id=91458024",Lf="http://www.roblox.com/asset/?id=91458024",Rt="http://www.roblox.com/asset/?id=91458024",Up="http://www.roblox.com/asset/?id=91458002"},
    Minecraft={Bk="http://www.roblox.com/asset/?id=8735166756",Dn="http://www.roblox.com/asset/?id=8735166707",Ft="http://www.roblox.com/asset/?id=8735231668",Lf="http://www.roblox.com/asset/?id=8735166755",Rt="http://www.roblox.com/asset/?id=8735166751",Up="http://www.roblox.com/asset/?id=8735166729"},
    ["Deep Space"]={Bk="http://www.roblox.com/asset/?id=159248188",Dn="http://www.roblox.com/asset/?id=159248183",Ft="http://www.roblox.com/asset/?id=159248187",Lf="http://www.roblox.com/asset/?id=159248173",Rt="http://www.roblox.com/asset/?id=159248192",Up="http://www.roblox.com/asset/?id=159248176"},
    Retro={Bk="rbxasset://sky/null_plainsky512_bk.jpg",Dn="rbxasset://sky/null_plainsky512_dn.jpg",Ft="rbxasset://sky/null_plainsky512_ft.jpg",Lf="rbxasset://sky/null_plainsky512_lf.jpg",Rt="rbxasset://sky/null_plainsky512_rt.jpg",Up="rbxasset://sky/null_plainsky512_up.jpg"},
    City={Bk="http://www.roblox.com/asset/?id=9134792889",Dn="http://www.roblox.com/asset/?id=9134791975",Ft="http://www.roblox.com/asset/?id=9134793457",Lf="http://www.roblox.com/asset/?id=9134791234",Rt="http://www.roblox.com/asset/?id=9134790419",Up="http://www.roblox.com/asset/?id=9134791633"},
}
local function PH_UpdateSkybox(name)
    local d = PH_Skybox[name]
    if not d then return end
    for _, v in pairs(PH_Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end
    end
    local sky = PH_Lighting:FindFirstChild("DC_Sky")
    if not sky then
        for _, v in pairs(PH_Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
        sky = Instance.new("Sky"); sky.Name = "DC_Sky"; sky.Parent = PH_Lighting
    end
    sky.SkyboxBk=d.Bk; sky.SkyboxDn=d.Dn; sky.SkyboxFt=d.Ft
    sky.SkyboxLf=d.Lf; sky.SkyboxRt=d.Rt; sky.SkyboxUp=d.Up
    sky.SunTextureId=""; sky.MoonTextureId=""; sky.StarCount=0
end

-- ============ WEATHER ============
local PH_WeatherPart, PH_GroundPart
local function PH_UpdateWeather(t)
    if PH_WeatherPart then PH_WeatherPart:Destroy(); PH_WeatherPart = nil end
    if PH_GroundPart then PH_GroundPart:Destroy(); PH_GroundPart = nil end
    if t == "None" then return end
    PH_WeatherPart = Instance.new("Part")
    PH_WeatherPart.Name="DC_Weather"; PH_WeatherPart.Size=Vector3.new(100,1,100)
    PH_WeatherPart.Transparency=1; PH_WeatherPart.Anchored=true; PH_WeatherPart.CanCollide=false
    PH_WeatherPart.Parent = Cam
    local se = Instance.new("ParticleEmitter", PH_WeatherPart)
    se.EmissionDirection = Enum.NormalId.Bottom; se.Enabled = true
    if t == "Rain" then
        se.Texture="rbxassetid://241868005"; se.Rate=10000
        se.Color=ColorSequence.new(Color3.fromRGB(255,255,255)); se.LightEmission=0.2
        se.Transparency=NumberSequence.new(0); se.Size=NumberSequence.new(3,6)
        se.Lifetime=NumberRange.new(2,2.5); se.Speed=NumberRange.new(80,100)
        se.SpreadAngle=Vector2.new(0,0); se.Acceleration=Vector3.new(0,-50,0)
        se.Orientation=Enum.ParticleOrientation.FacingCamera
    elseif t == "Snow" then
        se.Texture="rbxassetid://99851851"; se.Rate=200
        se.Color=ColorSequence.new(Color3.fromRGB(255,255,255))
        se.Size=NumberSequence.new(0.25,0.35); se.Speed=NumberRange.new(30,30)
        se.Lifetime=NumberRange.new(5,10); se.Acceleration=Vector3.new(0,0,0)
        se.SpreadAngle=Vector2.new(50,50); se.LightEmission=0.5
    end
end
RunService.RenderStepped:Connect(function()
    if PH_WeatherPart and Cam then
        PH_WeatherPart.CFrame = Cam.CFrame * CFrame.new(0,30,0)
    end
end)

-- ============ LIGHTING / ATMOSPHERE ============
local PH_DefaultLighting = {
    Ambient=PH_Lighting.Ambient, OutdoorAmbient=PH_Lighting.OutdoorAmbient,
    Brightness=PH_Lighting.Brightness, ClockTime=PH_Lighting.ClockTime,
}
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if PCfg.EnableTime then PH_Lighting.ClockTime = PCfg.WorldClockTime
            else PH_Lighting.ClockTime = PH_DefaultLighting.ClockTime end
            if PCfg.EnableBrightness then PH_Lighting.Brightness = PCfg.WorldBrightness
            else PH_Lighting.Brightness = PH_DefaultLighting.Brightness end
            if PCfg.EnableColors then
                PH_Lighting.Ambient = PCfg.WorldAmbient
                PH_Lighting.OutdoorAmbient = PCfg.WorldOutdoorAmbient
            else
                PH_Lighting.Ambient = PH_DefaultLighting.Ambient
                PH_Lighting.OutdoorAmbient = PH_DefaultLighting.OutdoorAmbient
            end
            if PCfg.EnableSkybox then PH_UpdateSkybox(PCfg.SkyboxPreset) end
            if PCfg.Atmosphere then
                local atm = PH_Lighting:FindFirstChildOfClass("Atmosphere")
                if not atm then atm = Instance.new("Atmosphere", PH_Lighting) end
                atm.Density = PCfg.AtmosphereDensity
                atm.Haze = PCfg.SubAtmosphereHaze
                atm.Glare = PCfg.AtmosphereGlare
            else
                local atm = PH_Lighting:FindFirstChildOfClass("Atmosphere")
                if atm then atm:Destroy() end
            end
            if PCfg.EnableColorCorrection then
                local cc = PH_Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if not cc then cc = Instance.new("ColorCorrectionEffect", PH_Lighting) end
                cc.Enabled = true
                cc.Saturation = PCfg.SaturationSlider
                cc.Contrast = PCfg.ContrastSlider
            else
                local cc = PH_Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if cc then cc.Enabled = false end
            end
        end)
    end
end)

-- ============ WORLD COLOR / NIGHT MODE ============
local PH_WorldSettings = {WorldColorEnabled=false, WorldColor=Color3.fromRGB(255,255,255),
                          SkyColorEnabled=false, SkyColor=Color3.fromRGB(255,255,255)}
local function PH_IsLocalObject(obj)
    local char = LP.Character
    if char and (obj == char or obj:IsDescendantOf(char)) then return true end
    if obj:IsDescendantOf(Cam) then return true end
    if obj.Name:find("DC_") or obj.Name:find("Memesense_") or obj.Name == "BS_RingSeg" then return true end
    return false
end
local function PH_ColorObj(obj)
    if PH_IsLocalObject(obj) then return end
    if obj:IsA("BasePart") then
        if not obj:GetAttribute("OrigColor") then obj:SetAttribute("OrigColor", obj.Color) end
        obj.Color = PH_WorldSettings.WorldColor
    elseif obj:IsA("Texture") or obj:IsA("Decal") then
        if not obj:GetAttribute("OrigColor3") then obj:SetAttribute("OrigColor3", obj.Color3) end
        obj.Color3 = PH_WorldSettings.WorldColor
    end
end
local function PH_RestoreObj(obj)
    if obj:IsA("BasePart") then
        if obj:GetAttribute("OrigColor") then obj.Color = obj:GetAttribute("OrigColor") end
    elseif obj:IsA("Texture") or obj:IsA("Decal") then
        if obj:GetAttribute("OrigColor3") then obj.Color3 = obj:GetAttribute("OrigColor3") end
    end
end
local function PH_RefreshWorld()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if PH_WorldSettings.WorldColorEnabled then PH_ColorObj(obj) else PH_RestoreObj(obj) end
    end
end
workspace.DescendantAdded:Connect(function(obj)
    if PH_WorldSettings.WorldColorEnabled then
        task.defer(function() if obj and obj.Parent then PH_ColorObj(obj) end end)
    end
end)
RunService.RenderStepped:Connect(function()
    if PH_WorldSettings.SkyColorEnabled then
        local c = PH_WorldSettings.SkyColor
        PH_Lighting.Ambient = c; PH_Lighting.OutdoorAmbient = c
        PH_Lighting.ColorShift_Bottom = c; PH_Lighting.ColorShift_Top = c
        PH_Lighting.FogColor = c
        local atm = PH_Lighting:FindFirstChild("DC_Atm")
        if not atm then
            atm = Instance.new("Atmosphere"); atm.Name = "DC_Atm"; atm.Parent = PH_Lighting
        end
        atm.Color = c; atm.Decay = c
    else
        local atm = PH_Lighting:FindFirstChild("DC_Atm")
        if atm then atm:Destroy() end
    end
end)

-- ============ CHAMS V3 ============
task.spawn(function()
    local ESPFolder
    pcall(function()
        ESPFolder = Instance.new("Folder", game:GetService("CoreGui"))
        ESPFolder.Name = "DC_Chams_Container"
    end)
    local Highlights = {}
    local function getMat(s)
        if s == "Metal" then return Enum.Material.Metal
        elseif s == "ForceField" then return Enum.Material.ForceField
        elseif s == "SmoothPlastic" then return Enum.Material.SmoothPlastic
        else return Enum.Material.Neon end
    end
    local function removeChams(char)
        if Highlights[char] then
            pcall(function() Highlights[char].visible:Destroy() end)
            pcall(function() Highlights[char].unvisible:Destroy() end)
            Highlights[char] = nil
        end
        if not char then return end
        for _, obj in ipairs(char:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") and obj:GetAttribute("OrigMat") then
                    obj.Material = Enum.Material[obj:GetAttribute("OrigMat")]
                    obj.Color = obj:GetAttribute("OrigColor") or obj.Color
                    obj:SetAttribute("OrigMat", nil); obj:SetAttribute("OrigColor", nil)
                end
            end)
        end
    end
    local function hasVest(c)
        if not c then return false end
        local a = c:FindFirstChild("CharacterArmor")
        return a and a:FindFirstChild("VestDetails") ~= nil
    end
    local function isTeammate(c)
        if not c or not LP.Character then return false end
        return hasVest(LP.Character) == hasVest(c)
    end
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    local function isVisible(c)
        local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
        if not root then return false end
        local cp = Cam.CFrame.Position
        local dir = root.Position - cp
        RayParams.FilterDescendantsInstances = {LP.Character, c}
        return workspace:Raycast(cp, dir, RayParams) == nil
    end
    RunService.RenderStepped:Connect(function()
        local en = PCfg.ChamsEnabled
        local tcOn = PCfg.ChamsTeamCheck
        local mv = getMat(PCfg.ChamsMaterialVisible)
        local mu = getMat(PCfg.ChamsMaterialUnvisible)
        local cv = PCfg.ChamsColorVisible
        local cu = PCfg.ChamsColorUnvisible
        local fv = PCfg.ChamsAlphaVisible
        local fu = PCfg.ChamsAlphaUnvisible
        local ov = PCfg.ChamsOutlineAlphaVisible
        local ou = PCfg.ChamsOutlineAlphaUnvisible
        local cf = workspace:FindFirstChild("Characters")
        if not cf then return end
        for _, obj in ipairs(cf:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                local char = obj
                if char == LP.Character then continue end
                if tcOn and isTeammate(char) then removeChams(char); continue end
                if not en then removeChams(char); continue end
                if not Highlights[char] then
                    local hv = Instance.new("Highlight")
                    hv.DepthMode = Enum.HighlightDepthMode.Occluded
                    hv.Parent = ESPFolder
                    local hu = Instance.new("Highlight")
                    hu.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hu.Parent = ESPFolder
                    Highlights[char] = { visible=hv, unvisible=hu }
                    char.AncestryChanged:Connect(function(_, np)
                        if np == nil then removeChams(char) end
                    end)
                end
                local hl = Highlights[char]
                local seen = isVisible(char)
                hl.visible.Adornee = char; hl.visible.FillColor = cv; hl.visible.OutlineColor = cv
                hl.visible.FillTransparency = fv; hl.visible.OutlineTransparency = ov
                hl.visible.Enabled = seen
                hl.unvisible.Adornee = char; hl.unvisible.FillColor = cu; hl.unvisible.OutlineColor = cu
                hl.unvisible.FillTransparency = fu; hl.unvisible.OutlineTransparency = ou
                hl.unvisible.Enabled = not seen
                local tm = seen and mv or mu
                local tc = seen and cv or cu
                for _, part in ipairs(char:GetDescendants()) do
                    pcall(function()
                        if part:IsA("SurfaceAppearance") or part:IsA("Decal") or part:IsA("Texture") then
                            part:Destroy()
                        elseif part:IsA("MeshPart") and part.TextureID ~= "" then part.TextureID = ""
                        elseif part:IsA("SpecialMesh") and part.TextureId ~= "" then part.TextureId = "" end
                        if part:IsA("BasePart") then
                            if not part:GetAttribute("OrigMat") then
                                part:SetAttribute("OrigMat", part.Material.Name)
                                part:SetAttribute("OrigColor", part.Color)
                            end
                            part.Material = tm; part.Color = tc
                        end
                    end)
                end
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if p.Character then removeChams(p.Character) end
    end)
end)

-- ============ GC HOOKS (Firerate / NoRecoil / NoSpread / Flash / Smoke) ============
local PH_originalFireRate = {}
local PH_firerateObjs = {}
local PH_SendFunc = nil
local PH_getCurrentEquipped = nil

pcall(function()
    for _, obj in next, getgc(true) do
        if type(obj) == "table" and rawget(obj, "FireRate") then
            pcall(function()
                table.insert(PH_originalFireRate, table.clone(obj))
                table.insert(PH_firerateObjs, obj)
            end)
        end
        if type(obj) == "table" and rawget(obj, "setWeaponRecoil") then
            pcall(function()
                local old
                old = hookfunction(obj.setWeaponRecoil, function(...)
                    if PCfg.NoRecoil then return end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "calculateRecoilOffset" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if PCfg.NoRecoil then return UDim2.new() end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "table" and rawget(obj, "weaponKick") then
            pcall(function()
                local old
                old = hookfunction(obj.weaponKick, function(p1, p2)
                    if PCfg.NoRecoil then return end
                    return old(p1, p2)
                end)
            end)
        end
        if type(obj) == "table" and rawget(obj, "getTrueSpread") then
            pcall(function()
                local old
                old = hookfunction(obj.getTrueSpread, function(p1)
                    if PCfg.NoSpread then return 0 end
                    return old(p1)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "Flash" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if PCfg.Antiflashbang then return end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "CreateVoxel" and debug.getupvalue(obj, 1) and tostring(debug.getupvalue(obj, 1)) == "Smoke" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if PCfg.Antismoke then return end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "table" and rawget(obj, "shoot") and typeof(obj.shoot) == "function" then
            pcall(function()
                for _, uv in pairs(debug.getupvalues(obj.shoot)) do
                    if type(uv) == "table" and rawget(uv, "Inventory") and rawget(uv.Inventory, "ShootWeapon") then
                        PH_SendFunc = uv.Inventory.ShootWeapon.Send
                        break
                    end
                end
            end)
        end
        if type(obj) == "table" and rawget(obj, "getCurrentEquipped") then
            pcall(function() PH_getCurrentEquipped = obj.getCurrentEquipped end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if PCfg.Firerate then
                for _, obj in next, PH_firerateObjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", math.max(PCfg.FirerateSlider, 0.01))
                        setreadonly(obj, true)
                    end)
                end
            else
                for i, obj in next, PH_firerateObjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", PH_originalFireRate[i].FireRate)
                        setreadonly(obj, true)
                    end)
                end
            end
        end)
    end
end)

-- ============ TRACERS + IMPACTS + SHOOT HOOK ============
local function PH_CreateTracer(startPos, endPos)
    if not PCfg.BulletTracers then return end
    if not startPos or not endPos then return end
    local style = PCfg.TracerStyle or "Block"
    local color = PCfg.TracerColor or Color3.fromRGB(0,170,255)
    if PCfg.TracerRainbow then color = Color3.fromHSV((tick()%5)/5, 1, 1) end
    local duration = PCfg.TracerTime or 2
    local bp = Instance.new("Part")
    bp.Name = "DC_Tracer"
    if style == "Cylinder (Obelius)" then
        bp.Shape = Enum.PartType.Cylinder
        bp.Size = Vector3.new((startPos-endPos).Magnitude, 0.12, 0.12)
        bp.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-bp.Size.X/2) * CFrame.Angles(0, math.rad(90), 0)
    else
        bp.Size = Vector3.new(0.1, 0.1, (startPos-endPos).Magnitude)
        bp.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-bp.Size.Z/2)
    end
    bp.Anchored = true; bp.CanCollide = false; bp.CanQuery = false; bp.CanTouch = false
    bp.Material = Enum.Material.Neon; bp.Color = color; bp.Transparency = 0
    bp.CastShadow = false; bp.Parent = workspace
    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < duration do
            local a = (tick()-t0)/duration
            bp.Transparency = a
            if PCfg.TracerRainbow then bp.Color = Color3.fromHSV((tick()%5)/5, 1, 1) end
            task.wait()
        end
        bp:Destroy()
    end)
end

local function PH_CreateImpact(hitPos)
    if not PCfg.BulletImpacts or not hitPos then return end
    local p = Instance.new("Part")
    p.Name = "DC_Impact"; p.Size = Vector3.new(0.6, 0.6, 0.6)
    p.Shape = Enum.PartType.Block; p.Position = hitPos
    p.Anchored = true; p.CanCollide = false
    p.Material = Enum.Material.Neon; p.Color = PCfg.BulletImpactsColor
    p.Transparency = 0; p.Parent = workspace
    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < 3 do
            p.Transparency = (tick()-t0)/3
            task.wait()
        end
        p:Destroy()
    end)
end

pcall(function()
    if not PH_SendFunc then return end
    local oldshoot
    oldshoot = hookfunction(PH_SendFunc, function(...)
        local args = {...}
        if args[1] and type(args[1].Bullets) == "table" then
            for _, bullet in pairs(args[1].Bullets) do
                if type(bullet.Hits) == "table" then
                    for _, hd in pairs(bullet.Hits) do
                        pcall(function()
                            if Cam and hd.Position then
                                PH_CreateTracer(Cam.CFrame.Position, hd.Position)
                                PH_CreateImpact(hd.Position)
                                PH_PlayHitSound()
                                PH_TriggerHitMarker(hd.Position)
                            end
                        end)
                    end
                end
            end
        end
        return oldshoot(unpack(args))
    end)
end)

print("[Danny's Cheats v2] Часть 2 загружена: обработчики PasteHub")

-- =========================================================================
-- [ ЧАСТЬ 3 — GUI С НОВЫМИ ВКЛАДКАМИ ]
-- =========================================================================

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
                if k and (Cfg[k] ~= nil and Cfg[k] or (PCfg and PCfg[k])) then o.BackgroundColor3 = ac
                else o.BackgroundColor3 = Color3.fromRGB(34, 34, 42) end
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

    local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(1, 0); rbc.Parent = reopenBtn
    local rbs = Instance.new("UIStroke"); rbs.Color = Color3.fromRGB(50, 50, 62); rbs.Thickness = 1; rbs.Transparency = 0.2; rbs.Parent = reopenBtn

    local dragging, dStart, sStart = false, nil, nil
    reopenBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dStart = i.Position; sStart = reopenBtn.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dStart
            reopenBtn.Position = UDim2.new(sStart.X.Scale, sStart.X.Offset + d.X, sStart.Y.Scale, sStart.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
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

    local mainC = Instance.new("UICorner"); mainC.CornerRadius = UDim.new(0, 10); mainC.Parent = main
    local mainS = Instance.new("UIStroke"); mainS.Color = Color3.fromRGB(45, 45, 55); mainS.Thickness = 1; mainS.Transparency = 0.2; mainS.Parent = main
    reg(mainS, "stroke")

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    header.BorderSizePixel = 0; header.ZIndex = 2; header.Parent = main
    reg(header, "bgSide")

    local hC = Instance.new("UICorner"); hC.CornerRadius = UDim.new(0, 10); hC.Parent = header
    local hFix = Instance.new("Frame")
    hFix.Size = UDim2.new(1, 0, 0, 12); hFix.Position = UDim2.new(0, 0, 1, -12)
    hFix.BackgroundColor3 = Color3.fromRGB(20, 20, 24); hFix.BorderSizePixel = 0; hFix.ZIndex = 2; hFix.Parent = header
    reg(hFix, "bgSide")

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 3, 0, 18); stripe.Position = UDim2.new(0, 12, 0.5, -9)
    stripe.BackgroundColor3 = Cfg.GuiColor; stripe.BorderSizePixel = 0; stripe.ZIndex = 3; stripe.Parent = header
    reg(stripe, "accent")
    local stripeC = Instance.new("UICorner"); stripeC.CornerRadius = UDim.new(1, 0); stripeC.Parent = stripe

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0, 220, 1, 0); titleLbl.Position = UDim2.new(0, 24, 0, 0)
    titleLbl.BackgroundTransparency = 1; titleLbl.Text = "Danny's Cheats v2"
    titleLbl.TextColor3 = Color3.fromRGB(240, 240, 250); titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 3; titleLbl.Parent = header

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26); minBtn.Position = UDim2.new(1, -34, 0.5, -13)
    minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42); minBtn.BorderSizePixel = 0
    minBtn.Text = "-"; minBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
    minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 15
    minBtn.AutoButtonColor = false; minBtn.ZIndex = 3; minBtn.Parent = header
    reg(minBtn, "bgInput")
    local mC = Instance.new("UICorner"); mC.CornerRadius = UDim.new(0, 6); mC.Parent = minBtn

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Size = UDim2.new(0, 120, 1, -48); sidebar.Position = UDim2.new(0, 6, 0, 42)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24); sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 1; sidebar.Parent = main
    sidebar.ScrollBarThickness = 2; sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    reg(sidebar, "bgSide")
    local sbC = Instance.new("UICorner"); sbC.CornerRadius = UDim.new(0, 8); sbC.Parent = sidebar
    local sbL = Instance.new("UIListLayout"); sbL.Padding = UDim.new(0, 3); sbL.SortOrder = Enum.SortOrder.LayoutOrder; sbL.Parent = sidebar
    local sbP = Instance.new("UIPadding"); sbP.PaddingTop = UDim.new(0, 6); sbP.PaddingLeft = UDim.new(0, 5); sbP.PaddingRight = UDim.new(0, 5); sbP.PaddingBottom = UDim.new(0, 6); sbP.Parent = sidebar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -136, 1, -48); content.Position = UDim2.new(0, 130, 0, 42)
    content.BackgroundColor3 = Color3.fromRGB(26, 26, 32); content.BorderSizePixel = 0
    content.ZIndex = 1; content.Parent = main
    reg(content, "bgCard")
    local contC = Instance.new("UICorner"); contC.CornerRadius = UDim.new(0, 8); contC.Parent = content

    local tabTitle = Instance.new("TextLabel")
    tabTitle.Size = UDim2.new(1, -20, 0, 26); tabTitle.Position = UDim2.new(0, 14, 0, 6)
    tabTitle.BackgroundTransparency = 1; tabTitle.Text = "ESP"
    tabTitle.TextColor3 = Color3.fromRGB(240, 240, 250); tabTitle.Font = Enum.Font.GothamBold
    tabTitle.TextSize = 13; tabTitle.TextXAlignment = Enum.TextXAlignment.Left; tabTitle.Parent = content

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -28, 0, 1); divider.Position = UDim2.new(0, 14, 0, 34)
    divider.BackgroundColor3 = Color3.fromRGB(45, 45, 55); divider.BorderSizePixel = 0
    divider.Parent = content
    reg(divider, "stroke")

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -48); scroll.Position = UDim2.new(0, 10, 0, 40)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Cfg.GuiColor
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = content
    reg(scroll, "scroll")

    local scrollL = Instance.new("UIListLayout"); scrollL.Padding = UDim.new(0, 4); scrollL.SortOrder = Enum.SortOrder.LayoutOrder; scrollL.Parent = scroll

    local tabs, tabButtons = {}, {}

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
        b.Size = UDim2.new(1, 0, 0, 26)
        b.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.Parent = sidebar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
        local bar = Instance.new("Frame")
        bar.Name = "ActiveBar"; bar.Size = UDim2.new(0, 3, 0, 14)
        bar.Position = UDim2.new(0, 0, 0.5, -7); bar.BackgroundColor3 = Cfg.GuiColor
        bar.BorderSizePixel = 0; bar.Visible = false; bar.Parent = b
        reg(bar, "accent")
        local barC = Instance.new("UICorner"); barC.CornerRadius = UDim.new(1, 0); barC.Parent = bar
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -14, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(160, 160, 180); lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = b
        b.MouseButton1Click:Connect(function() switchTab(name) end)
        tabButtons[name] = b
        return b
    end

    local function makeTab(name)
        local f = Instance.new("Frame")
        f.Name = name; f.Size = UDim2.new(1, 0, 0, 0); f.BackgroundTransparency = 1
        f.Visible = false; f.AutomaticSize = Enum.AutomaticSize.Y; f.Parent = scroll
        local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 4); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = f
        tabs[name] = f
        makeTabBtn(name)
        return f
    end

    local function section(parent, txt)
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, 0, 0, 18); s.BackgroundTransparency = 1
        s.Text = string.upper(txt); s.TextColor3 = Cfg.GuiColor
        s.Font = Enum.Font.GothamBold; s.TextSize = 9
        s.TextXAlignment = Enum.TextXAlignment.Left; s.Parent = parent
        reg(s, "textAccent")
    end

    local function toggle(parent, txt, key, cb, cfgTable)
        cfgTable = cfgTable or Cfg
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 28); row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0; row.Text = ""; row.AutoButtonColor = false; row.Parent = parent
        reg(row, "bgInput")
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = row
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235); lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local tg = Instance.new("Frame")
        tg.Size = UDim2.new(0, 30, 0, 16); tg.Position = UDim2.new(1, -42, 0.5, -8)
        tg.BackgroundColor3 = cfgTable[key] and Cfg.GuiColor or Color3.fromRGB(55, 55, 68)
        tg.BorderSizePixel = 0; tg.Parent = row
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = cfgTable[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.Parent = tg
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob
        row.MouseButton1Click:Connect(function()
            cfgTable[key] = not cfgTable[key]
            Tween:Create(tg, TweenInfo.new(0.15), {
                BackgroundColor3 = cfgTable[key] and Cfg.GuiColor or Color3.fromRGB(55, 55, 68)
            }):Play()
            Tween:Create(knob, TweenInfo.new(0.15), {
                Position = cfgTable[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }):Play()
            if cb then cb(cfgTable[key]) end
        end)
    end

    local function slider(parent, txt, key, mn, mx, step, cfgTable)
        cfgTable = cfgTable or Cfg
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 42); row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0; row.Parent = parent
        reg(row, "bgInput")
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = row
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 0, 16); lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1; lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235); lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 55, 0, 16); val.Position = UDim2.new(1, -60, 0, 4)
        val.BackgroundTransparency = 1; val.Text = tostring(cfgTable[key])
        val.TextColor3 = Cfg.GuiColor; val.Font = Enum.Font.GothamBold
        val.TextSize = 11; val.TextXAlignment = Enum.TextXAlignment.Right; val.Parent = row
        reg(val, "textAccent")
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 5); bar.Position = UDim2.new(0, 12, 0, 28)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 62); bar.BorderSizePixel = 0; bar.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((cfgTable[key] - mn) / (mx - mn), 0, 1, 0)
        fill.BackgroundColor3 = Cfg.GuiColor; fill.BorderSizePixel = 0; fill.Parent = bar
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill
        reg(fill, "accent")
        local dr = false
        local function upd(i)
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = math.floor((mn + (mx - mn) * rel) / step) * step
            cfgTable[key] = v
            val.Text = tostring(v)
            fill.Size = UDim2.new(rel, 0, 1, 0)
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dr = true; upd(i)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = false end
        end)
    end

    local function optionRow(parent, txt, key, opts, cfgTable, cb)
        cfgTable = cfgTable or Cfg
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54); row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0; row.Parent = parent
        reg(row, "bgInput")
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = row
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 16); lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1; lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235); lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local holder = Instance.new("ScrollingFrame")
        holder.Size = UDim2.new(1, -24, 0, 24); holder.Position = UDim2.new(0, 12, 0, 24)
        holder.BackgroundTransparency = 1; holder.BorderSizePixel = 0
        holder.ScrollBarThickness = 0
        holder.CanvasSize = UDim2.new(0, #opts * 57, 0, 0)
        holder.ScrollingDirection = Enum.ScrollingDirection.X; holder.Parent = row
        local hl = Instance.new("UIListLayout"); hl.FillDirection = Enum.FillDirection.Horizontal; hl.Padding = UDim.new(0, 3); hl.Parent = holder
        local btns = {}
        local function refresh()
            for _, b in ipairs(btns) do
                if cfgTable[key] == b.Val then
                    b.Btn.BackgroundColor3 = Cfg.GuiColor
                    b.Btn.TextColor3 = Color3.new(1, 1, 1)
                else
                    b.Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
                    b.Btn.TextColor3 = Color3.fromRGB(170, 170, 190)
                end
            end
        end
        for _, v in ipairs(opts) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 54, 1, 0); b.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
            b.BorderSizePixel = 0; b.Text = tostring(v)
            b.TextColor3 = Color3.fromRGB(170, 170, 190); b.Font = Enum.Font.GothamBold
            b.TextSize = 9; b.AutoButtonColor = false; b.Parent = holder
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 5); bc.Parent = b
            table.insert(btns, {Btn=b, Val=v})
            b.MouseButton1Click:Connect(function()
                cfgTable[key] = v; refresh()
                if cb then cb(v) end
            end)
        end
        refresh()
    end

    local function colorRow(parent, lblTxt, setter)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54); row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        row.BorderSizePixel = 0; row.Parent = parent
        reg(row, "bgInput")
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = row
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 16); lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1; lbl.Text = lblTxt
        lbl.TextColor3 = Color3.fromRGB(225, 225, 235); lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local row2 = Instance.new("ScrollingFrame")
        row2.Size = UDim2.new(1, -24, 0, 24); row2.Position = UDim2.new(0, 12, 0, 24)
        row2.BackgroundTransparency = 1; row2.BorderSizePixel = 0
        row2.ScrollBarThickness = 0
        row2.CanvasSize = UDim2.new(0, #PALETTE * 28, 0, 0)
        row2.ScrollingDirection = Enum.ScrollingDirection.X; row2.Parent = row
        local rl = Instance.new("UIListLayout"); rl.FillDirection = Enum.FillDirection.Horizontal; rl.Padding = UDim.new(0, 4); rl.Parent = row2
        for _, col in ipairs(PALETTE) do
            local s = Instance.new("TextButton")
            s.Size = UDim2.new(0, 24, 0, 24); s.BackgroundColor3 = col
            s.BorderSizePixel = 0; s.Text = ""; s.AutoButtonColor = false; s.Parent = row2
            local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 6); sc.Parent = s
            s.MouseButton1Click:Connect(function() setter(col) end)
        end
    end

    -- ================ ОРИГИНАЛЬНЫЕ ВКЛАДКИ ================

    -- ESP
    local espTab = makeTab("ESP")
    section(espTab, "ESP")
    toggle(espTab, "ESP", "ESPEnabled")
    toggle(espTab, "Обводка", "Boxes")
    toggle(espTab, "Враги", "ShowEnemies")
    toggle(espTab, "Скрыть союзников", "TeamCheck")
    toggle(espTab, "Проверка видимости", "VisibilityCheck")
    toggle(espTab, "Красить видимых", "VisibleColor")
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

    -- AIM
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

    -- EFFECTS
    local effectsTab = makeTab("EFFECTS")
    section(effectsTab, "Визуальные")
    toggle(effectsTab, "No Flash", "EffectsNoFlash")
    toggle(effectsTab, "No Smoke", "EffectsNoSmoke")

    -- SKINS (упрощённая версия без скролл-бара скинов)
    local skinsTab = makeTab("SKINS")
    section(skinsTab, "Skin Changer")
    toggle(skinsTab, "Включить скины", "SkinChangerEnabled")
    local weaponOrder = {"AK-47", "M4A4", "M4A1-S", "AWP", "AUG", "FAMAS", "Glock", "USP-S", "P250", "Desert Eagle"}
    for _, w in ipairs(weaponOrder) do
        local skins = SD.SkinSelections[w]
        if skins then
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 54); holder.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
            holder.BorderSizePixel = 0; holder.Parent = skinsTab
            reg(holder, "bgInput")
            local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 6); hc.Parent = holder
            local hl = Instance.new("TextLabel")
            hl.Size = UDim2.new(1, -20, 0, 16); hl.Position = UDim2.new(0, 12, 0, 4)
            hl.BackgroundTransparency = 1; hl.Text = w
            hl.TextColor3 = Color3.fromRGB(225, 225, 235); hl.Font = Enum.Font.Gotham
            hl.TextSize = 11; hl.TextXAlignment = Enum.TextXAlignment.Left; hl.Parent = holder
            local hs = Instance.new("ScrollingFrame")
            hs.Size = UDim2.new(1, -24, 0, 24); hs.Position = UDim2.new(0, 12, 0, 24)
            hs.BackgroundTransparency = 1; hs.BorderSizePixel = 0
            hs.ScrollBarThickness = 0
            hs.CanvasSize = UDim2.new(0, math.min(#skins, 15) * 74, 0, 0)
            hs.ScrollingDirection = Enum.ScrollingDirection.X; hs.Parent = holder
            local hsl = Instance.new("UIListLayout"); hsl.FillDirection = Enum.FillDirection.Horizontal; hsl.Padding = UDim.new(0, 4); hsl.Parent = hs
            local btns = {}
            local function refresh()
                for _, b in ipairs(btns) do
                    if b.Val == Cfg.SkinChangerSkins[w] then
                        b.Btn.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
                        b.Btn.TextColor3 = Color3.new(1, 1, 1)
                    else
                        b.Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
                        b.Btn.TextColor3 = Color3.fromRGB(170, 170, 190)
                    end
                end
            end            for i, v in ipairs(skins) do
                if i > 15 then break end
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 70, 1, 0); b.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
                b.BorderSizePixel = 0; b.Text = v
                b.TextColor3 = Color3.fromRGB(170, 170, 190); b.Font = Enum.Font.GothamBold
                b.TextSize = 9; b.AutoButtonColor = false; b.Parent = hs
                local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 5); bc.Parent = b
                table.insert(btns, {Btn=b, Val=v})
                b.MouseButton1Click:Connect(function() Cfg.SkinChangerSkins[w] = v; refresh() end)
            end
            refresh()
        end
    end
    section(skinsTab, "Нож")
    toggle(skinsTab, "Включить нож", "KnifeChangerEnabled")
    local KM = {"Karambit", "Butterfly Knife", "Flip Knife", "Gut Knife", "M9 Bayonet", "Skeleton Knife", "Stiletto Knife"}
    optionRow(skinsTab, "Модель", "KnifeChangerModel", KM)
    section(skinsTab, "Перчатки")
    toggle(skinsTab, "Включить перчатки", "GloveChangerEnabled")
    local GM = {}
    for k in pairs(SD.GloveSelections) do GM[#GM + 1] = k end
    table.sort(GM)
    if #GM > 0 then optionRow(skinsTab, "Модель", "GloveChangerModel", GM) end

    -- VISUALS
    local visualTab = makeTab("VISUALS")
    section(visualTab, "Тема")
    colorRow(visualTab, "Цвет меню", function(c)
        Cfg.GuiColor = c
        task.spawn(applyTheme)
        stripe.BackgroundColor3 = c
        fovStroke.Color = c
    end)

    -- ================ НОВЫЕ ВКЛАДКИ ================

    -- TRACERS
    local trTab = makeTab("TRACERS")
    section(trTab, "Bullet Tracers")
    toggle(trTab, "Включить трассеры", "BulletTracers", nil, PCfg)
    toggle(trTab, "Rainbow режим", "TracerRainbow", nil, PCfg)
    optionRow(trTab, "Стиль", "TracerStyle", {"Block", "Cylinder"}, PCfg)
    slider(trTab, "Время жизни", "TracerTime", 0.1, 10, 0.5, PCfg)
    colorRow(trTab, "Цвет трассера", function(c) PCfg.TracerColor = c end)
    section(trTab, "Bullet Impacts")
    toggle(trTab, "Показывать попадания", "BulletImpacts", nil, PCfg)
    colorRow(trTab, "Цвет попадания", function(c) PCfg.BulletImpactsColor = c end)

    -- HIT
    local hitTab = makeTab("HIT")
    section(hitTab, "Hitmarker")
    toggle(hitTab, "Включить hitmarker", "HitMarkerEnabled", nil, PCfg)
    toggle(hitTab, "Rainbow", "HitMarkerRainbow", nil, PCfg)
    slider(hitTab, "Длительность", "HitMarkerDuration", 0.5, 5, 0.5, PCfg)
    slider(hitTab, "Скорость вращения", "HitMarkerSpinSpeed", 0, 1440, 60, PCfg)
    slider(hitTab, "Размер", "HitMarkerSize", 5, 50, 1, PCfg)
    slider(hitTab, "Толщина", "HitMarkerThickness", 1, 6, 1, PCfg)
    colorRow(hitTab, "Цвет hitmarker", function(c) PCfg.HitMarkerColor = c end)
    section(hitTab, "Hit Sound")
    toggle(hitTab, "Включить звук", "HitSoundEnabled", nil, PCfg)
    slider(hitTab, "Громкость", "HitSoundVolume", 0.1, 5, 0.1, PCfg)
    optionRow(hitTab, "Пресет", "HitSoundPreset", {"Neverlose", "Skeet", "Bell", "Bell2", "Bubble", "Rust", "Agro1", "Agro2", "Coins", "Schaater", "Pick"}, PCfg)
    section(hitTab, "Wallbang")
    toggle(hitTab, "Показывать WALLBANG", "ShowPenetration", nil, PCfg)

    -- CAMERA
    local camTab = makeTab("CAMERA")
    section(camTab, "FOV")
    toggle(camTab, "Свой FOV", "CustomFovToggle", nil, PCfg)
    slider(camTab, "FOV", "FovAmount", 70, 120, 1, PCfg)
    section(camTab, "Third Person")
    toggle(camTab, "Вид от 3-го лица", "ThirdPerson", nil, PCfg)
    slider(camTab, "Дистанция", "ThirdPersonDist", 5, 50, 1, PCfg)
    section(camTab, "Scope")
    toggle(camTab, "Свой FOV прицела", "CustomScopeFov", nil, PCfg)
    slider(camTab, "FOV прицела", "ScopeFovValue", 10, 100, 1, PCfg)
    toggle(camTab, "Убрать прицел", "RemoveScope", nil, PCfg)
    toggle(camTab, "Свой крестик", "CustomScopeCrosshair", nil, PCfg)
    slider(camTab, "Толщина крестика", "ScopeCrosshairThickness", 1, 10, 1, PCfg)
    slider(camTab, "Длина LR", "ScopeCrosshairLengthLR", 0, 1000, 10, PCfg)
    slider(camTab, "Длина TB", "ScopeCrosshairLengthTB", 0, 1000, 10, PCfg)
    colorRow(camTab, "Цвет крестика", function(c) PCfg.ScopeCrosshairColor = c end)
    section(camTab, "Custom Hands")
    toggle(camTab, "Смещение рук", "CustomHandsEnabled", nil, PCfg)
    slider(camTab, "X", "HandsX", -2, 2, 0.01, PCfg)
    slider(camTab, "Y", "HandsY", -2, 2, 0.01, PCfg)
    slider(camTab, "Z", "HandsZ", -2, 2, 0.01, PCfg)

    -- CHAMS
    local chTab = makeTab("CHAMS")
    section(chTab, "Chams V3 (игроки)")
    toggle(chTab, "Включить Chams", "ChamsEnabled", nil, PCfg)
    toggle(chTab, "Скрыть союзников", "ChamsTeamCheck", nil, PCfg)
    section(chTab, "Видимые")
    optionRow(chTab, "Материал видимых", "ChamsMaterialVisible", {"Neon", "Metal", "ForceField", "SmoothPlastic"}, PCfg)
    slider(chTab, "Прозрачность видимых", "ChamsAlphaVisible", 0, 1, 0.05, PCfg)
    slider(chTab, "Прозрачность контура видимых", "ChamsOutlineAlphaVisible", 0, 1, 0.05, PCfg)
    colorRow(chTab, "Цвет видимых", function(c) PCfg.ChamsColorVisible = c end)
    section(chTab, "Невидимые")
    optionRow(chTab, "Материал невидимых", "ChamsMaterialUnvisible", {"Neon", "Metal", "ForceField", "SmoothPlastic"}, PCfg)
    slider(chTab, "Прозрачность невидимых", "ChamsAlphaUnvisible", 0, 1, 0.05, PCfg)
    slider(chTab, "Прозрачность контура невидимых", "ChamsOutlineAlphaUnvisible", 0, 1, 0.05, PCfg)
    colorRow(chTab, "Цвет невидимых", function(c) PCfg.ChamsColorUnvisible = c end)
    section(chTab, "Weapon Chams")
    toggle(chTab, "Chams оружия", "WeaponChamsEnabled", nil, PCfg)
    optionRow(chTab, "Материал оружия", "WeaponChamsMode", {"Glass", "ForceField", "Metal", "Highlight", "Neon"}, PCfg)
    slider(chTab, "Прозрачность Glass", "GlassTransparency", 0, 1, 0.05, PCfg)
    slider(chTab, "Reflectance Metal", "MetalReflectance", 0, 1, 0.1, PCfg)
    colorRow(chTab, "Цвет оружия", function(c) PCfg.WeaponChamsColor = c end)

    -- WORLD
    local wTab = makeTab("WORLD")
    section(wTab, "Skybox")
    toggle(wTab, "Включить Skybox", "EnableSkybox", nil, PCfg)
    optionRow(wTab, "Пресет Skybox", "SkyboxPreset", {"Night", "Ocean Sunset", "Standard", "Minecraft", "Deep Space", "Retro", "City"}, PCfg)
    section(wTab, "Weather")
    optionRow(wTab, "Погода", "WeatherType", {"None", "Rain", "Snow"}, PCfg, function(v) PH_UpdateWeather(v) end)
    section(wTab, "Lighting")
    toggle(wTab, "Время", "EnableTime", nil, PCfg)
    slider(wTab, "Час", "WorldClockTime", 0, 24, 1, PCfg)
    toggle(wTab, "Яркость", "EnableBrightness", nil, PCfg)
    slider(wTab, "Яркость", "WorldBrightness", 0, 10, 0.5, PCfg)
    toggle(wTab, "Цвета", "EnableColors", nil, PCfg)
    colorRow(wTab, "Ambient", function(c) PCfg.WorldAmbient = c end)
    colorRow(wTab, "Outdoor", function(c) PCfg.WorldOutdoorAmbient = c end)
    section(wTab, "Atmosphere")
    toggle(wTab, "Атмосфера", "Atmosphere", nil, PCfg)
    slider(wTab, "Плотность", "AtmosphereDensity", 0, 1, 0.05, PCfg)
    slider(wTab, "Haze", "SubAtmosphereHaze", 0, 10, 0.5, PCfg)
    slider(wTab, "Glare", "AtmosphereGlare", 0, 10, 0.5, PCfg)
    toggle(wTab, "Color Correction", "EnableColorCorrection", nil, PCfg)
    slider(wTab, "Saturation", "SaturationSlider", -1, 1, 0.1, PCfg)
    slider(wTab, "Contrast", "ContrastSlider", -1, 1, 0.1, PCfg)
    section(wTab, "Night Mode")
    toggle(wTab, "World Color", "WorldColorToggle", nil, PCfg, function(v)
        PH_WorldSettings.WorldColorEnabled = v
        PH_RefreshWorld()
    end)
    colorRow(wTab, "World Color", function(c)
        PCfg.WorldColorPicker = c
        PH_WorldSettings.WorldColor = c
        if PH_WorldSettings.WorldColorEnabled then PH_RefreshWorld() end
    end)
    toggle(wTab, "Second Color", "SkyColorToggle", nil, PCfg, function(v)
        PH_WorldSettings.SkyColorEnabled = v
    end)
    colorRow(wTab, "Second Color", function(c)
        PCfg.SkyColorPicker = c
        PH_WorldSettings.SkyColor = c
    end)

    -- WEAPON
    local wpnTab = makeTab("WEAPON")
    section(wpnTab, "Стрельба")
    toggle(wpnTab, "Firerate Changer", "Firerate", nil, PCfg)
    slider(wpnTab, "Firerate", "FirerateSlider", 0, 1, 0.01, PCfg)
    toggle(wpnTab, "No Recoil", "NoRecoil", nil, PCfg)
    toggle(wpnTab, "No Spread", "NoSpread", nil, PCfg)
    section(wpnTab, "Гранаты")
    toggle(wpnTab, "Anti-Flash", "Antiflashbang", nil, PCfg)
    toggle(wpnTab, "Anti-Smoke", "Antismoke", nil, PCfg)

    -- MISC
    local miscTab = makeTab("MISC")
    section(miscTab, "Движение")
    toggle(miscTab, "Auto Bhop", "AutoBhop", nil, PCfg)
    slider(miscTab, "Bhop Speed", "BhopSpeed", 5, 30, 1, PCfg)
    toggle(miscTab, "No Fall Damage", "NoFallDamage", nil, PCfg)
    section(miscTab, "Инфо")
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, 0, 0, 70); infoLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Danny's Cheats v2\nESP + WH + Aim + Skins + PasteHub\nLeft Alt — открыть/закрыть"
    infoLbl.TextColor3 = Color3.fromRGB(180, 180, 200); infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 10; infoLbl.TextWrapped = true; infoLbl.Parent = miscTab
    local infoC = Instance.new("UICorner"); infoC.CornerRadius = UDim.new(0, 6); infoC.Parent = infoLbl
    reg(infoLbl, "bgInput")

    -- ================ СВОРАЧИВАНИЕ ================
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

buildGUI()

print("[Danny's Cheats] ESP: OK")
print("[Danny's Cheats] Aim: " .. (Aim.Ready and "OK" or "FAIL"))
print("[Danny's Cheats] Skins: " .. (SD.SkinsRoot and ("OK (" .. #SD.SkinsRoot:GetChildren() .. " категорий)") or "Skins не найдены"))
print("[Danny's Cheats v2] Часть 3 загружена: GUI с 13 вкладками")

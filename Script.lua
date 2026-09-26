--[[
    DeNsI v3 — Blox Strike
    Executor: Arceus X Neo
    Single-file build
]]

-- === Проверка окружения ===
local REQUIRED = {"hookfunction", "getgc", "setreadonly"}
for _, f in ipairs(REQUIRED) do
    if not _G[f] and not rawget(_G, f) then
        warn("[DeNsI] Инжектор не поддерживает: " .. f)
        return
    end
end
if not Drawing or not Drawing.new then
    warn("[DeNsI] Drawing API недоступен")
    return
end

print("[DeNsI] Окружение OK")

-- === Очистка ===
if _G.DeNsI_Cleanup then pcall(_G.DeNsI_Cleanup) end
_G.DeNsI_Cleanup = nil

-- === Сервисы ===
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Tween        = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Lighting     = game:GetService("Lighting")
local LP           = Players.LocalPlayer
local Cam          = workspace.CurrentCamera

-- Удаляем старые GUI
for _, g in ipairs(LP:WaitForChild("PlayerGui"):GetChildren()) do
    if g.Name:sub(1,4) == "DCS_" or g.Name:sub(1,6) == "DeNsI_" then
        pcall(function() g:Destroy() end)
    end
end

-- === Конфиг ===
local Cfg = {
    ESPEnabled = false, ESPTeamCheck = true, ESPBoxType = "2D Box",
    ESPBoxColorA = Color3.fromRGB(255,255,255), ESPBoxColorB = Color3.fromRGB(0,200,255),
    ESPName = false, ESPNameColor = Color3.new(1,1,1),
    ESPHealth = false, ESPHealthTopColor = Color3.fromRGB(0,255,0), ESPHealthBottomColor = Color3.fromRGB(255,0,0),
    ESPDistance = false, ESPDistanceColor = Color3.new(1,1,1),
    ESPTracer = false, ESPTracerColor = Color3.new(1,1,1),
    ESPSkeleton = false, ESPSkeletonColorA = Color3.new(1,1,1), ESPSkeletonColorB = Color3.fromRGB(0,255,255),

    SilentEnabled = false, SilentTeamCheck = true, SilentVisibleOnly = true,
    SilentTargetPart = "Head", SilentPriority = "Crosshair", SilentMaxDistance = 1200,
    SilentHitChance = 100, SilentFOV = 150, SilentPrediction = true, SilentBulletSpeed = 1000,

    AimbotEnabled = false, AimbotTeamCheck = true, AimbotVisibleOnly = true,
    AimbotHitPart = "Head", AimbotFOV = 120, AimbotSmooth = 4,
    AimbotMaxDistance = 800, AimbotPrediction = true, AimbotBulletSpeed = 1000,

    Antiflashbang = false, Antismoke = false,

    SkinChangerEnabled = false, SkinChangerSkins = {},
    KnifeChangerEnabled = false, KnifeChangerModel = "Skeleton Knife",
    GloveChangerEnabled = false, GloveChangerModel = "Sports Gloves", GloveChangerGloves = {},

    TracerColor = Color3.fromRGB(0,170,255),

    CrosshairEnabled = false, CrosshairColor = Color3.fromRGB(0,255,0),
    CrosshairSize = 10, CrosshairGap = 5, CrosshairThick = 2,
    CrosshairDot = true, CrosshairRainbow = false,

    CustomFovToggle = false, FovAmount = 90,
    ThirdPerson = false, ThirdPersonDist = 10,

    EnableSkybox = false, SkyboxPreset = "Night",

    AutoBhop = false, BhopSpeed = 18,

    GuiColor = Color3.fromRGB(100,130,255),
}

local PALETTE = {
    Color3.fromRGB(255,95,105), Color3.fromRGB(87,181,255), Color3.fromRGB(115,238,159),
    Color3.fromRGB(255,195,80), Color3.fromRGB(160,100,255), Color3.fromRGB(255,80,220),
    Color3.fromRGB(242,244,250), Color3.fromRGB(80,80,90),
}

-- === Утилиты ===
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

-- === Bullet module ===
local Bullet = nil
pcall(function()
    Bullet = require(RS.Components.Weapon.Classes.Bullet)
end)
print("[DeNsI] Bullet: " .. (Bullet and "OK" or "FAIL"))

-- === Поиск цели ===
local AimParts = {"Head", "UpperTorso", "LowerTorso"}

local function findTarget(maxDist, fov, teamCheck, visibleOnly, partName, priority)
    if not Cam then return nil end
    local center = Cam.ViewportSize * 0.5
    local myTeam = teamOf(LP)
    local origin = Cam.CFrame.Position
    local best, bestScore = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c, h = matchChar(p)
            if c and (not teamCheck or teamOf(p) ~= myTeam) then
                local names = (partName == "Closest" or partName == "Random") and AimParts or {partName}
                for _, n in ipairs(names) do
                    local part = c:FindFirstChild(n)
                    if part and part:IsA("BasePart") and part.Parent then
                        local pos = part.Position
                        local dist = (pos - origin).Magnitude
                        if dist > 0.05 and dist <= maxDist then
                            local sp, onScreen = Cam:WorldToViewportPoint(pos)
                            if onScreen and sp.Z > 0 then
                                local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if screenDist <= fov then
                                    local visible = true
                                    if visibleOnly then
                                        local rp = RaycastParams.new()
                                        rp.FilterType = Enum.RaycastFilterType.Exclude
                                        rp.FilterDescendantsInstances = {LP.Character, c, Cam}
                                        local r = workspace:Raycast(origin, pos - origin, rp)
                                        visible = (r == nil) or r.Instance:IsDescendantOf(c)
                                    end
                                    if visible then
                                        local score = priority == "Distance" and dist
                                                   or priority == "Health" and h
                                                   or screenDist
                                        if score < bestScore then
                                            bestScore = score
                                            best = {Player = p, Character = c, Part = part, Position = pos, Distance = dist}
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- === Silent Aim ===
local Aim = {Ready = false, Target = nil}
local AimRandom = Random.new()

if Bullet and Bullet._performRaycast then
    pcall(function()
        local getIgnore = require(RS.Components.Common.GetRayIgnore)
        Aim.GetIgnore = getIgnore
        Aim.Original = Bullet._performRaycast

        local function predictPos(part, origin)
            local pos = part.Position
            if not Cfg.SilentPrediction then return pos end
            local v = part.AssemblyLinearVelocity
            if not v or v.Magnitude < 1 then return pos end
            local d = (pos - origin).Magnitude
            local t = math.min(d / math.max(Cfg.SilentBulletSpeed, 1), 0.3)
            return pos + v * t
        end

        Aim.Wrapper = function(self, spread, ...)
            local isLocal = self.IsActive and not self.IsDestroyed
                and self.Weapon and self.Weapon.Player == LP
            local shot = Aim.Original(self, spread, ...)
            if not isLocal or type(shot) ~= "table" then return shot end
            if not Cfg.SilentEnabled then return shot end
            if UIS:GetFocusedTextBox() then return shot end
            if AimRandom:NextInteger(1, 100) > Cfg.SilentHitChance then return shot end

            local target = findTarget(Cfg.SilentMaxDistance, Cfg.SilentFOV,
                Cfg.SilentTeamCheck, Cfg.SilentVisibleOnly,
                Cfg.SilentTargetPart, Cfg.SilentPriority)
            if not target then return shot end

            local predicted = predictPos(target.Part, shot.Origin)
            local dir = (predicted - shot.Origin)
            if dir.Magnitude < 0.05 then return shot end
            dir = dir.Unit

            local props = self.Properties or {}
            local range = props.Range or 500
            local ignore = getIgnore and getIgnore() or {LP.Character, Cam}

            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = ignore
            local hit = workspace:Raycast(shot.Origin, dir * range, rp)

            local result = {
                Origin = shot.Origin,
                Direction = dir,
                Distance = range,
                Hits = {}
            }
            if hit then
                result.Distance = (hit.Position - shot.Origin).Magnitude
                table.insert(result.Hits, {
                    Position = hit.Position,
                    Instance = hit.Instance,
                    Material = hit.Material and hit.Material.Name or "Plastic",
                    Normal = hit.Normal or Vector3.zero,
                    Exit = false,
                })
            end

            Aim.Target = target
            return result
        end

        Bullet._performRaycast = Aim.Wrapper
        Aim.Ready = Bullet._performRaycast == Aim.Wrapper
    end)
end
print("[DeNsI] Silent Aim: " .. (Aim.Ready and "OK" or "FAIL"))

-- === Aimbot ===
local AimbotHeld = false
local AimbotTarget = nil

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.E then AimbotHeld = true end
end)
UIS.InputEnded:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.E then AimbotHeld = false end
end)

RunService.RenderStepped:Connect(function(dt)
    if not Cfg.AimbotEnabled or not AimbotHeld then
        AimbotTarget = nil
        return
    end
    if not Cam then return end

    if not AimbotTarget or not AimbotTarget.Part or not AimbotTarget.Part.Parent then
        AimbotTarget = findTarget(Cfg.AimbotMaxDistance, Cfg.AimbotFOV,
            Cfg.AimbotTeamCheck, Cfg.AimbotVisibleOnly,
            Cfg.AimbotHitPart, "Crosshair")
    end
    if not AimbotTarget then return end

    local part = AimbotTarget.Part
    if not part or not part.Parent then AimbotTarget = nil; return end

    local targetPos = part.Position
    if Cfg.AimbotPrediction then
        local v = part.AssemblyLinearVelocity
        local d = (targetPos - Cam.CFrame.Position).Magnitude
        local t = math.min(d / math.max(Cfg.AimbotBulletSpeed, 1), 0.3)
        targetPos = targetPos + v * t
    end

    local desired = CFrame.new(Cam.CFrame.Position, targetPos)
    local alpha = math.clamp(dt * (10 / math.max(Cfg.AimbotSmooth, 0.1)), 0, 1)
    Cam.CFrame = Cam.CFrame:Lerp(desired, alpha)
end)

-- === Skybox ===
local SkyboxTable = {
    Night = {Bk="rbxassetid://1514717643", Dn="rbxassetid://1514716936", Ft="rbxassetid://1514715910", Lf="rbxassetid://1514714945", Rt="rbxassetid://1514714011", Up="rbxassetid://1514713374"},
    ["Ocean Sunset"] = {Bk="rbxassetid://17525686840", Dn="rbxassetid://17525678473", Ft="rbxassetid://17525684686", Lf="rbxassetid://17525680663", Rt="rbxassetid://17525682665", Up="rbxassetid://17525674545"},
    ["Deep Space"] = {Bk="rbxassetid://159248188", Dn="rbxassetid://159248183", Ft="rbxassetid://159248187", Lf="rbxassetid://159248173", Rt="rbxassetid://159248192", Up="rbxassetid://159248176"},
    Retro = {Bk="rbxasset://sky/null_plainsky512_bk.jpg", Dn="rbxasset://sky/null_plainsky512_dn.jpg", Ft="rbxasset://sky/null_plainsky512_ft.jpg", Lf="rbxasset://sky/null_plainsky512_lf.jpg", Rt="rbxasset://sky/null_plainsky512_rt.jpg", Up="rbxasset://sky/null_plainsky512_up.jpg"},
}

local function UpdateSkybox(name)
    local d = SkyboxTable[name]
    if not d then return end
    local sky = Lighting:FindFirstChild("DeNsI_Sky")
    if not sky then
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
        sky = Instance.new("Sky")
        sky.Name = "DeNsI_Sky"
        sky.Parent = Lighting
    end
    sky.SkyboxBk = d.Bk; sky.SkyboxDn = d.Dn; sky.SkyboxFt = d.Ft
    sky.SkyboxLf = d.Lf; sky.SkyboxRt = d.Rt; sky.SkyboxUp = d.Up
end

RunService.Heartbeat:Connect(function()
    if Cfg.EnableSkybox then
        local sky = Lighting:FindFirstChild("DeNsI_Sky")
        local preset = SkyboxTable[Cfg.SkyboxPreset]
        if not sky or (preset and sky.SkyboxBk ~= preset.Bk) then
            UpdateSkybox(Cfg.SkyboxPreset)
        end
    end
end)

-- === Auto Bhop ===
local function getMoveDir()
    local d = Vector3.zero
    local lv = Cam.CFrame.LookVector
    local rv = Cam.CFrame.RightVector
    if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + lv end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - lv end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - rv end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + rv end
    if d.Magnitude > 0 then return Vector3.new(d.X, 0, d.Z).Unit end
    return Vector3.zero
end

RunService.Heartbeat:Connect(function()
    if not Cfg.AutoBhop then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {char}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        if workspace:Raycast(root.Position, Vector3.new(0, -4, 0), rp) then
            hum.Jump = true
        end
    end
end)

-- === Anti-Flash ===
pcall(function()
    for _, obj in next, getgc(true) do
        if type(obj) == "function" then
            local info = debug.getinfo(obj)
            if info and info.name == "Flash" then
                local old
                old = hookfunction(obj, function(...)
                    if Cfg.Antiflashbang then return end
                    return old(...)
                end)
            end
        end
    end
end)

-- === Camera FOV / Third Person ===
RunService.RenderStepped:Connect(function()
    if not Cam then return end
    if Cfg.CustomFovToggle then Cam.FieldOfView = Cfg.FovAmount end
    if Cfg.ThirdPerson then
        local dd = math.clamp(Cfg.ThirdPersonDist, 5, 50)
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = dd
        LP.CameraMinZoomDistance = dd
    end
end)

-- === ESP ===
local ESPData = {}

local function getBox(inst)
    if not inst or not inst.Parent then return nil end
    local head = inst:FindFirstChild("Head")
    local hrp = inst:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then return nil end
    local pos = hrp.Position
    local top, onScreen = Cam:WorldToViewportPoint(pos + Vector3.new(0, 3, 0))
    local bottom = Cam:WorldToViewportPoint(pos - Vector3.new(0, 3, 0))
    if not onScreen then return nil end
    local h = math.abs(bottom.Y - top.Y)
    local w = h * 0.6
    return {
        x = top.X - w/2, y = top.Y,
        w = w, h = h,
        cx = top.X, cy = top.Y + h/2,
        dist = (Cam.CFrame.Position - pos).Magnitude,
        health = inst:GetAttribute("Health") or 100,
        maxHealth = inst:GetAttribute("MaxHealth") or 100,
    }
end

local function getESP(inst)
    if not ESPData[inst] then
        ESPData[inst] = {
            outline = Drawing.new("Square"),
            name = Drawing.new("Text"),
            dist = Drawing.new("Text"),
            healthBar = Drawing.new("Line"),
            tracer = Drawing.new("Line"),
        }
        local d = ESPData[inst]
        d.outline.Thickness = 1; d.outline.Filled = false; d.outline.Visible = false
        d.name.Center = true; d.name.Outline = true; d.name.Size = 13; d.name.Visible = false
        d.dist.Center = true; d.dist.Outline = true; d.dist.Size = 12; d.dist.Visible = false
        d.healthBar.Thickness = 3; d.healthBar.Visible = false
        d.tracer.Thickness = 1; d.tracer.Visible = false
    end
    return ESPData[inst]
end

RunService.RenderStepped:Connect(function()
    if not Cfg.ESPEnabled then
        for inst, d in pairs(ESPData) do
            d.outline.Visible = false
            d.name.Visible = false
            d.dist.Visible = false
            d.healthBar.Visible = false
            d.tracer.Visible = false
        end
        return
    end

    local cf = workspace:FindFirstChild("Characters")
    if not cf then return end
    local myTeam = teamOf(LP)

    for _, inst in ipairs(cf:GetDescendants()) do
        if inst:IsA("Model") and inst ~= LP.Character and inst:FindFirstChild("HumanoidRootPart") then
            local d = getESP(inst)
            local p = Players:GetPlayerFromCharacter(inst)
            local skip = false
            if Cfg.ESPTeamCheck and p and teamOf(p) == myTeam then skip = true end

            if skip then
                d.outline.Visible = false; d.name.Visible = false
                d.dist.Visible = false; d.healthBar.Visible = false
                d.tracer.Visible = false
            else
                local box = getBox(inst)
                if box then
                    d.outline.Position = Vector2.new(box.x, box.y)
                    d.outline.Size = Vector2.new(box.w, box.h)
                    d.outline.Color = Cfg.ESPBoxColorA
                    d.outline.Visible = true

                    d.name.Text = p and p.Name or inst.Name
                    d.name.Position = Vector2.new(box.cx, box.y - 16)
                    d.name.Color = Cfg.ESPNameColor
                    d.name.Visible = Cfg.ESPName

                    d.dist.Text = tostring(math.floor(box.dist)) .. "m"
                    d.dist.Position = Vector2.new(box.cx, box.y + box.h + 2)
                    d.dist.Color = Cfg.ESPDistanceColor
                    d.dist.Visible = Cfg.ESPDistance

                    local hp = math.clamp(box.health / box.maxHealth, 0, 1)
                    d.healthBar.From = Vector2.new(box.x - 5, box.y + box.h * (1 - hp))
                    d.healthBar.To = Vector2.new(box.x - 5, box.y + box.h)
                    d.healthBar.Color = Cfg.ESPHealthTopColor:Lerp(Cfg.ESPHealthBottomColor, 1 - hp)
                    d.healthBar.Visible = Cfg.ESPHealth

                    d.tracer.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                    d.tracer.To = Vector2.new(box.cx, box.cy)
                    d.tracer.Color = Cfg.ESPTracerColor
                    d.tracer.Visible = Cfg.ESPTracer
                else
                    d.outline.Visible = false; d.name.Visible = false
                    d.dist.Visible = false; d.healthBar.Visible = false
                    d.tracer.Visible = false
                end
            end
        end
    end
end)

-- === Custom Crosshair ===
local chGui = Instance.new("ScreenGui")
chGui.Name = "DeNsI_Crosshair"
chGui.ResetOnSpawn = false
chGui.IgnoreGuiInset = true
chGui.DisplayOrder = 97
chGui.Parent = LP:WaitForChild("PlayerGui")

local chCont = Instance.new("Frame")
chCont.AnchorPoint = Vector2.new(0.5, 0.5)
chCont.Position = UDim2.new(0.5, 0, 0.5, 0)
chCont.Size = UDim2.new(0, 0, 0, 0)
chCont.BackgroundTransparency = 1
chCont.Parent = chGui

local function mkCH(anchor, pos)
    local f = Instance.new("Frame")
    f.AnchorPoint = anchor
    f.Position = pos
    f.BorderSizePixel = 0
    f.BackgroundColor3 = Cfg.CrosshairColor
    f.Parent = chCont
    return f
end

local chTop    = mkCH(Vector2.new(0.5, 1), UDim2.new(0, 0, 0, -Cfg.CrosshairGap))
local chBottom = mkCH(Vector2.new(0.5, 0), UDim2.new(0, 0, 0,  Cfg.CrosshairGap))
local chLeft   = mkCH(Vector2.new(1, 0.5), UDim2.new(0, -Cfg.CrosshairGap, 0, 0))
local chRight  = mkCH(Vector2.new(0, 0.5), UDim2.new(0,  Cfg.CrosshairGap, 0, 0))
local chDot    = mkCH(Vector2.new(0.5, 0.5), UDim2.new(0, 0, 0, 0))

RunService.RenderStepped:Connect(function()
    chCont.Visible = Cfg.CrosshairEnabled
    if not Cfg.CrosshairEnabled then return end

    local col = Cfg.CrosshairColor
    if Cfg.CrosshairRainbow then col = Color3.fromHSV((tick() % 5) / 5, 1, 1) end

    local s, g, t = Cfg.CrosshairSize, Cfg.CrosshairGap, Cfg.CrosshairThick
    chTop.Size = UDim2.new(0, t, 0, s); chTop.Position = UDim2.new(0, 0, 0, -g)
    chBottom.Size = UDim2.new(0, t, 0, s); chBottom.Position = UDim2.new(0, 0, 0, g)
    chLeft.Size = UDim2.new(0, s, 0, t); chLeft.Position = UDim2.new(0, -g, 0, 0)
    chRight.Size = UDim2.new(0, s, 0, t); chRight.Position = UDim2.new(0, g, 0, 0)
    chDot.Size = UDim2.new(0, math.max(t, 2), 0, math.max(t, 2))
    chDot.Visible = Cfg.CrosshairDot

    for _, f in ipairs({chTop, chBottom, chLeft, chRight, chDot}) do
        f.BackgroundColor3 = col
    end
end)

-- === GUI ===
local function buildGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeNsI_GUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100
    gui.Parent = LP:WaitForChild("PlayerGui")

    local W, H = 480, 360
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, W, 0, H)
    main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    main.BackgroundColor3 = Color3.fromRGB(15,15,18)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.ClipsDescendants = true
    main.Parent = gui

    local mainC = Instance.new("UICorner")
    mainC.CornerRadius = UDim.new(0, 10)
    mainC.Parent = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(20,20,24)
    header.BorderSizePixel = 0
    header.Parent = main

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -100, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "DeNsI v3"
    titleLbl.TextColor3 = Color3.fromRGB(240,240,250)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = header

    local closeC = Instance.new("UICorner")
    closeC.CornerRadius = UDim.new(1, 0)
    closeC.Parent = closeBtn

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Size = UDim2.new(0, 110, 1, -42)
    sidebar.Position = UDim2.new(0, 6, 0, 40)
    sidebar.BackgroundColor3 = Color3.fromRGB(20,20,24)
    sidebar.BorderSizePixel = 0
    sidebar.ScrollBarThickness = 2
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebar.Parent = main

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
    content.Size = UDim2.new(1, -126, 1, -48)
    content.Position = UDim2.new(0, 120, 0, 42)
    content.BackgroundColor3 = Color3.fromRGB(26,26,32)
    content.BorderSizePixel = 0
    content.Parent = main

    local contC = Instance.new("UICorner")
    contC.CornerRadius = UDim.new(0, 8)
    contC.Parent = content

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -20)
    scroll.Position = UDim2.new(0, 10, 0, 10)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Cfg.GuiColor
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = content

    local scrollL = Instance.new("UIListLayout")
    scrollL.Padding = UDim.new(0, 4)
    scrollL.SortOrder = Enum.SortOrder.LayoutOrder
    scrollL.Parent = scroll

    local tabs = {}
    local tabButtons = {}

    local function switchTab(name)
        for n, f in pairs(tabs) do f.Visible = (n == name) end
        for n, b in pairs(tabButtons) do
            local active = (n == name)
            b.BackgroundColor3 = active and Color3.fromRGB(34,34,42) or Color3.fromRGB(20,20,24)
            local lbl = b:FindFirstChildOfClass("TextLabel")
            if lbl then
                lbl.TextColor3 = active and Color3.fromRGB(240,240,250) or Color3.fromRGB(160,160,180)
            end
        end
    end

    local function makeTabBtn(name)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 26)
        b.BackgroundColor3 = Color3.fromRGB(20,20,24)
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.Parent = sidebar

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -14, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(160,160,180)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = b

        b.MouseButton1Click:Connect(function() switchTab(name) end)
        tabButtons[name] = b
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
        s.TextSize = 10
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = parent
    end

    local function toggle(parent, txt, key)
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(30,30,38)
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.Parent = parent

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225,225,235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local tg = Instance.new("Frame")
        tg.Size = UDim2.new(0, 30, 0, 16)
        tg.Position = UDim2.new(1, -42, 0.5, -8)
        tg.BackgroundColor3 = Cfg[key] and Cfg.GuiColor or Color3.fromRGB(55,55,68)
        tg.BorderSizePixel = 0
        tg.Parent = row

        local tgC = Instance.new("UICorner")
        tgC.CornerRadius = UDim.new(1, 0)
        tgC.Parent = tg

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = Cfg[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.BorderSizePixel = 0
        knob.Parent = tg

        local knobC = Instance.new("UICorner")
        knobC.CornerRadius = UDim.new(1, 0)
        knobC.Parent = knob

        row.MouseButton1Click:Connect(function()
            Cfg[key] = not Cfg[key]
            Tween:Create(tg, TweenInfo.new(0.15), {BackgroundColor3 = Cfg[key] and Cfg.GuiColor or Color3.fromRGB(55,55,68)}):Play()
            Tween:Create(knob, TweenInfo.new(0.15), {Position = Cfg[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
        end)
    end

    local function slider(parent, txt, key, mn, mx, step)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(30,30,38)
        row.BorderSizePixel = 0
        row.Parent = parent

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225,225,235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 60, 0, 16)
        val.Position = UDim2.new(1, -65, 0, 4)
        val.BackgroundTransparency = 1
        val.Text = tostring(Cfg[key])
        val.TextColor3 = Cfg.GuiColor
        val.Font = Enum.Font.GothamBold
        val.TextSize = 12
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 5)
        bar.Position = UDim2.new(0, 12, 0, 28)
        bar.BackgroundColor3 = Color3.fromRGB(50,50,62)
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
                dr = true; upd(i)
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

    local function colorRow(parent, txt, setter)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = Color3.fromRGB(30,30,38)
        row.BorderSizePixel = 0
        row.Parent = parent

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = txt
        lbl.TextColor3 = Color3.fromRGB(225,225,235)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local row2 = Instance.new("ScrollingFrame")
        row2.Size = UDim2.new(1, -24, 0, 24)
        row2.Position = UDim2.new(0, 12, 0, 24)
        row2.BackgroundTransparency = 1
        row2.BorderSizePixel = 0
        row2.ScrollBarThickness = 0
        row2.CanvasSize = UDim2.new(0, #PALETTE * 28, 0, 0)
        row2.ScrollingDirection = Enum.ScrollingDirection.X
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

            s.MouseButton1Click:Connect(function() setter(col) end)
        end
    end

    -- ESP вкладка
    local espTab = makeTab("ESP")
    section(espTab, "Основное")
    toggle(espTab, "ESP Enabled", "ESPEnabled")
    toggle(espTab, "Team Check", "ESPTeamCheck")
    section(espTab, "Инфо")
    toggle(espTab, "Name", "ESPName")
    toggle(espTab, "Health", "ESPHealth")
    toggle(espTab, "Distance", "ESPDistance")
    toggle(espTab, "Tracer", "ESPTracer")
    section(espTab, "Цвета")
    colorRow(espTab, "Box Color", function(c) Cfg.ESPBoxColorA = c end)
    colorRow(espTab, "Name Color", function(c) Cfg.ESPNameColor = c end)
    colorRow(espTab, "Tracer Color", function(c) Cfg.ESPTracerColor = c end)

    -- AIM вкладка
    local aimTab = makeTab("AIM")
    section(aimTab, "Silent Aim")
    toggle(aimTab, "Silent Aim", "SilentEnabled")
    toggle(aimTab, "Team Check", "SilentTeamCheck")
    toggle(aimTab, "Visible Only", "SilentVisibleOnly")
    toggle(aimTab, "Prediction", "SilentPrediction")
    slider(aimTab, "FOV", "SilentFOV", 20, 500, 10)
    slider(aimTab, "Distance", "SilentMaxDistance", 100, 3000, 100)
    slider(aimTab, "Hit Chance", "SilentHitChance", 1, 100, 1)
    section(aimTab, "Aimbot")
    toggle(aimTab, "Aimbot (E)", "AimbotEnabled")
    toggle(aimTab, "Team Check", "AimbotTeamCheck")
    toggle(aimTab, "Prediction", "AimbotPrediction")
    slider(aimTab, "Smooth", "AimbotSmooth", 0.5, 20, 0.5)
    slider(aimTab, "FOV", "AimbotFOV", 10, 500, 10)

    -- VISUAL вкладка
    local visTab = makeTab("VISUAL")
    section(visTab, "Crosshair")
    toggle(visTab, "Crosshair", "CrosshairEnabled")
    toggle(visTab, "Dot", "CrosshairDot")
    toggle(visTab, "Rainbow", "CrosshairRainbow")
    slider(visTab, "Size", "CrosshairSize", 1, 50, 1)
    slider(visTab, "Gap", "CrosshairGap", 0, 30, 1)
    slider(visTab, "Thickness", "CrosshairThick", 1, 10, 1)
    colorRow(visTab, "Color", function(c) Cfg.CrosshairColor = c end)
    section(visTab, "Camera")
    toggle(visTab, "Custom FOV", "CustomFovToggle")
    slider(visTab, "FOV", "FovAmount", 70, 120, 1)
    toggle(visTab, "Third Person", "ThirdPerson")
    slider(visTab, "Distance", "ThirdPersonDist", 5, 50, 1)

    -- MISC вкладка
    local miscTab = makeTab("MISC")
    section(miscTab, "Movement")
    toggle(miscTab, "Auto Bhop", "AutoBhop")
    slider(miscTab, "Bhop Speed", "BhopSpeed", 5, 30, 1)
    section(miscTab, "Effects")
    toggle(miscTab, "Anti-Flashbang", "Antiflashbang")
    section(miscTab, "Skybox")
    toggle(miscTab, "Enable Skybox", "EnableSkybox")
    section(miscTab, "Тема")
    colorRow(miscTab, "Цвет GUI", function(c) Cfg.GuiColor = c end)

    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    switchTab("ESP")
end

buildGUI()

-- === Cleanup ===
_G.DeNsI_Cleanup = function()
    for _, d in pairs(ESPData) do
        pcall(function() d.outline:Remove() end)
        pcall(function() d.name:Remove() end)
        pcall(function() d.dist:Remove() end)
        pcall(function() d.healthBar:Remove() end)
        pcall(function() d.tracer:Remove() end)
    end
end

print("[DeNsI] v3 загружен успешно")
print("[DeNsI] Silent Aim: " .. (Aim.Ready and "OK" or "FAIL"))
print("[DeNsI] Bullet module: " .. (Bullet and "OK" or "FAIL"))

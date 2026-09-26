--[[ DeNsI v7 — Full Diagnostic Build ]]

-- === Диагностическая панель ПЕРВЫМ делом ===
local __dgui = Instance.new("ScreenGui")
__dgui.Name = "DeNsI_Diag"
__dgui.ResetOnSpawn = false
__dgui.DisplayOrder = 999
pcall(function() __dgui.Parent = game:GetService("CoreGui") end)
if not __dgui.Parent then
    __dgui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local __dframe = Instance.new("Frame")
__dframe.Size = UDim2.new(0, 360, 0, 240)
__dframe.Position = UDim2.new(0.5, -180, 0, 60)
__dframe.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
__dframe.BorderSizePixel = 2
__dframe.BorderColor3 = Color3.fromRGB(100, 130, 255)
__dframe.Parent = __dgui

local __dtitle = Instance.new("TextLabel")
__dtitle.Size = UDim2.new(1, 0, 0, 24)
__dtitle.BackgroundColor3 = Color3.fromRGB(100, 130, 255)
__dtitle.BorderSizePixel = 0
__dtitle.Text = "  DeNsI v7 — загрузка"
__dtitle.TextColor3 = Color3.new(1,1,1)
__dtitle.Font = Enum.Font.GothamBold
__dtitle.TextSize = 14
__dtitle.TextXAlignment = Enum.TextXAlignment.Left
__dtitle.Parent = __dframe

local __dscroll = Instance.new("ScrollingFrame")
__dscroll.Size = UDim2.new(1, -10, 1, -34)
__dscroll.Position = UDim2.new(0, 5, 0, 29)
__dscroll.BackgroundTransparency = 1
__dscroll.BorderSizePixel = 0
__dscroll.ScrollBarThickness = 4
__dscroll.CanvasSize = UDim2.new(0, 0, 0, 0)
__dscroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
__dscroll.Parent = __dframe

local __dlayout = Instance.new("UIListLayout")
__dlayout.Padding = UDim.new(0, 2)
__dlayout.Parent = __dscroll

local __hasErr = false
local function __log(msg, isErr)
    if isErr then __hasErr = true end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = tostring(msg)
    l.TextColor3 = isErr and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(180, 255, 180)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = __dscroll
    print(msg)
end

__log("[Boot] старт")

-- === Основной код в pcall ===
local __ok, __err = pcall(function()

-- Проверка окружения
local __env_ok = true
if not Drawing or not Drawing.new then __log("Нет Drawing", true); __env_ok = false end
if not hookfunction then __log("Нет hookfunction", true); __env_ok = false end
if not getgc then __log("Нет getgc", true); __env_ok = false end
if not __env_ok then error("Окружение не подходит") end
__log("[1] Окружение OK")

-- Сервисы
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local RS         = game:GetService("ReplicatedStorage")
local Lighting   = game:GetService("Lighting")
local LP         = Players.LocalPlayer
local Cam        = workspace.CurrentCamera

__log("[2] Сервисы OK")

for _, g in ipairs(LP:WaitForChild("PlayerGui"):GetChildren()) do
    if g.Name:sub(1,4) == "DCS_" or g.Name:sub(1,6) == "DeNsI_" or g.Name:sub(1,7) == "SkinGUI" then
        pcall(function() g:Destroy() end)
    end
end

-- Конфиг
local Cfg = {
    ESPEnabled = false, ESPTeamCheck = true,
    ESPBoxColor = Color3.fromRGB(0,200,255),
    ESPName = false, ESPNameColor = Color3.new(1,1,1),
    ESPHealth = false, ESPHealthTopColor = Color3.fromRGB(0,255,0), ESPHealthBottomColor = Color3.fromRGB(255,0,0),
    ESPDistance = false, ESPDistanceColor = Color3.new(1,1,1),
    ESPTracer = false, ESPTracerColor = Color3.new(1,1,1),

    SilentEnabled = false, SilentTeamCheck = true, SilentVisibleOnly = true,
    SilentTargetPart = "Head", SilentPriority = "Crosshair", SilentMaxDistance = 1200,
    SilentHitChance = 100, SilentFOV = 150, SilentPrediction = true, SilentBulletSpeed = 1000,

    AimbotEnabled = false, AimbotTeamCheck = true, AimbotVisibleOnly = true,
    AimbotHitPart = "Head", AimbotFOV = 120, AimbotSmooth = 4,
    AimbotMaxDistance = 800, AimbotPrediction = true, AimbotBulletSpeed = 1000,

    CrosshairEnabled = false, CrosshairColor = Color3.fromRGB(0,255,0),
    CrosshairSize = 10, CrosshairGap = 5, CrosshairThick = 2,
    CrosshairDot = true, CrosshairRainbow = false,

    CustomFovToggle = false, FovAmount = 90,
    ThirdPerson = false, ThirdPersonDist = 10,

    EnableSkybox = false, SkyboxPreset = "Night",
    AutoBhop = false, BhopSpeed = 18,
    Antiflashbang = false,

    SkinChangerEnabled = false,
    KnifeChangerEnabled = false,
    GloveChangerEnabled = false,
    Skins = {},
    KnifeModel = "Karambit",
    GloveModel = "Sports Gloves",
    Gloves = {},

    GuiColor = Color3.fromRGB(100,130,255),
}

local PALETTE = {
    Color3.fromRGB(255,95,105), Color3.fromRGB(87,181,255), Color3.fromRGB(115,238,159),
    Color3.fromRGB(255,195,80), Color3.fromRGB(160,100,255), Color3.fromRGB(255,80,220),
    Color3.fromRGB(242,244,250), Color3.fromRGB(80,80,90),
}

-- Утилиты
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

__log("[3] Утилиты OK")

-- Bullet
local Bullet = nil
pcall(function()
    Bullet = require(RS.Components.Weapon.Classes.Bullet)
end)
__log("[4] Bullet: " .. (Bullet and "OK" or "FAIL"))

-- Поиск цели
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

-- Silent Aim
local Aim = {Ready = false, Target = nil}
local AimRandom = Random.new()

if Bullet and Bullet._performRaycast then
    pcall(function()
        local getIgnore = require(RS.Components.Common.GetRayIgnore)
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
__log("[5] Silent Aim: " .. (Aim.Ready and "OK" or "FAIL"))

-- Aimbot
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

__log("[6] Aimbot OK")

-- Skybox
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

__log("[7] Skybox OK")

-- Auto Bhop
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

__log("[8] Bhop OK")

-- Anti-Flash
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

__log("[9] Anti-Flash OK")

-- Camera
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

__log("[10] Camera OK")

-- ESP (пофикшено)
local ESPData = {}

local function getBox(inst)
    if not inst or not inst.Parent then return nil end
    local hrp = inst:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local pos = hrp.Position
    local top, onScreen = Cam:WorldToViewportPoint(pos + Vector3.new(0, 3, 0))
    local bottom = Cam:WorldToViewportPoint(pos - Vector3.new(0, 3, 0))
    if not onScreen then return nil end
    local h = math.abs(bottom.Y - top.Y)
    local w = h * 0.6
    return {
        x = top.X - w/2, y = top.Y, w = w, h = h,
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

local function hideESP(inst)
    if not inst or not ESPData[inst] then return end
    local d = ESPData[inst]
    d.outline.Visible = false
    d.name.Visible = false
    d.dist.Visible = false
    d.healthBar.Visible = false
    d.tracer.Visible = false
end

RunService.RenderStepped:Connect(function()
    if not Cfg.ESPEnabled then
        for inst, _ in pairs(ESPData) do hideESP(inst) end
        return
    end

    local cf = workspace:FindFirstChild("Characters")
    if not cf then return end
    local myTeam = teamOf(LP)

    for inst, _ in pairs(ESPData) do
        if not inst.Parent or not inst:IsDescendantOf(cf) then
            hideESP(inst)
        end
    end

    for _, inst in ipairs(cf:GetDescendants()) do
        if inst:IsA("Model") and inst ~= LP.Character and inst:FindFirstChild("HumanoidRootPart") then
            local p = Players:GetPlayerFromCharacter(inst)
            local isDead = false

            if not p then
                isDead = true
            else
                local _, h = matchChar(p)
                if not h then isDead = true end
            end

            if inst:GetAttribute("Dead") == true then isDead = true end
            local hpAttr = inst:GetAttribute("Health")
            if hpAttr and hpAttr <= 0 then isDead = true end

            if isDead then
                hideESP(inst)
            else
                local d = getESP(inst)
                local skip = false
                if Cfg.ESPTeamCheck and p and teamOf(p) == myTeam then skip = true end

                if skip then
                    hideESP(inst)
                else
                    local box = getBox(inst)
                    if box then
                        d.outline.Position = Vector2.new(box.x, box.y)
                        d.outline.Size = Vector2.new(box.w, box.h)
                        d.outline.Color = Cfg.ESPBoxColor
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
                        hideESP(inst)
                    end
                end
            end
        end
    end
end)

__log("[11] ESP OK")

-- Crosshair
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

__log("[12] Crosshair OK")

-- Skin Changer data
local SkinData = {Root = nil, SkinSelections = {}, GloveSelections = {}, AllWeapons = {}}

pcall(function()
    SkinData.Root = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Skins")
end)

if SkinData.Root then
    for _, wf in ipairs(SkinData.Root:GetChildren()) do
        local skins = {}
        for _, sf in ipairs(wf:GetChildren()) do
            table.insert(skins, sf.Name)
        end
        table.sort(skins)
        SkinData.SkinSelections[wf.Name] = skins
        table.insert(SkinData.AllWeapons, wf.Name)
    end
    table.sort(SkinData.AllWeapons)

    for _, wf in ipairs(SkinData.Root:GetChildren()) do
        local n = wf.Name
        if n:match("Glove") or n:match("Hand Wrap") then
            local skins = {"Default"}
            for _, sf in ipairs(wf:GetChildren()) do
                table.insert(skins, sf.Name)
            end
            SkinData.GloveSelections[n] = skins
        end
    end
end

local function findDefaultSkin(w)
    local skins = SkinData.SkinSelections[w]
    if not skins or #skins == 0 then return "Default" end
    for _, s in ipairs(skins) do if s == "Stock" then return s end end
    for _, s in ipairs(skins) do if s == "Vanilla" then return s end end
    for _, s in ipairs(skins) do if s == "Default" then return s end end
    return skins[1]
end

for w, _ in pairs(SkinData.SkinSelections) do
    Cfg.Skins[w] = findDefaultSkin(w)
end
for g, _ in pairs(SkinData.GloveSelections) do
    Cfg.Gloves[g] = "Default"
end

__log("[13] Skin data: " .. #SkinData.AllWeapons .. " оружий")

-- Категории
local CATEGORIES = {
    {Name = "Пистолеты", Items = {"Desert Eagle","Dual Berettas","Five-SeveN","Glock-18","P250","R8 Revolver","Tec-9","USP-S"}},
    {Name = "ПП", Items = {"MAC-10","MP9","MP7","MP5-SD","P90","UMP-45"}},
    {Name = "Винтовки", Items = {"AK-47","AUG","FAMAS","Galil AR","M4A1-S","M4A4","SG 553"}},
    {Name = "Snipers", Items = {"AWP","SSG 08"}},
    {Name = "Shotguns", Items = {"MAG-7","Nova","Sawed-Off","XM1014"}},
    {Name = "Machine Guns", Items = {"M249","Negev"}},
    {Name = "Ножи", Items = {"Butterfly Knife","Flip Knife","Gut Knife","Karambit","M9 Bayonet","Skeleton Knife","Stiletto Knife","CT Knife","T Knife","LightSaber"}},
    {Name = "Перчатки", Items = {"CT Glove","Driver Gloves","Hand Wraps","Operator Gloves","Sports Gloves","T Glove"}},
    {Name = "Гранаты", Items = {"C4","Decoy Grenade","Flashbang","HE Grenade","Incendiary Grenade","Molotov","Smoke Grenade","Zeus x27"}},
}

local KNIFE_LIST = {"CT Knife","T Knife","Knife","Karambit","Butterfly Knife",
                    "Flip Knife","Gut Knife","M9 Bayonet","Skeleton Knife",
                    "Stiletto Knife","LightSaber"}

local function isKnife(w)
    if not w then return false end
    for _, k in ipairs(KNIFE_LIST) do if w == k then return true end end
    return false
end

local function SafeRequire(m)
    if not m then return nil end
    local ok, r = pcall(function() return require(m) end)
    if ok and r and type(r) == "table" then return r end
    return nil
end

pcall(function()
    local SkinsMod = RS:FindFirstChild("Database")
        and RS.Database:FindFirstChild("Components")
        and RS.Database.Components:FindFirstChild("Libraries")
        and RS.Database.Components.Libraries:FindFirstChild("Skins")

    local VmMod = RS:FindFirstChild("Classes")
        and RS.Classes:FindFirstChild("WeaponComponent")
        and RS.Classes.WeaponComponent:FindFirstChild("Classes")
        and RS.Classes.WeaponComponent.Classes:FindFirstChild("Viewmodel")

    local Sk = SafeRequire(SkinsMod)
    local Vm = SafeRequire(VmMod)
    if not Sk then return end

    if Sk.GetCameraModel then
        local orig = Sk.GetCameraModel
        Sk.GetCameraModel = function(w, sk, ...)
            if Cfg.KnifeChangerEnabled and w and isKnife(w) then
                local nm = Cfg.KnifeModel
                local ns = Cfg.Skins[nm] or "Vanilla"
                local ok, r = pcall(orig, nm, ns, ...)
                if ok and r then return r end
            end
            return orig(w, sk, ...)
        end
    end

    if Sk.GetCharacterModel then
        local orig = Sk.GetCharacterModel
        Sk.GetCharacterModel = function(w, sk, ...)
            if Cfg.KnifeChangerEnabled and w and isKnife(w) then
                local nm = Cfg.KnifeModel
                local ns = Cfg.Skins[nm] or "Vanilla"
                local ok, r = pcall(orig, nm, ns, ...)
                if ok and r then return r end
            end
            return orig(w, sk, ...)
        end
    end

    if Vm and Vm.new then
        local orig = Vm.new
        Vm.new = function(vc, w, sk, ...)
            if Cfg.KnifeChangerEnabled and w and isKnife(w) then
                local nm = Cfg.KnifeModel
                local ns = Cfg.Skins[nm] or "Vanilla"
                local ok, r = pcall(orig, vc, nm, ns, ...)
                if ok and r then return r end
            end
            return orig(vc, w, sk, ...)
        end
    end

    if Sk.GetGloves then
        local orig = Sk.GetGloves
        Sk.GetGloves = function(g, sk)
            if Cfg.GloveChangerEnabled and Cfg.GloveModel then
                local gm = Cfg.GloveModel
                local gs = Cfg.Gloves[gm] or "Default"
                local ok, r = pcall(orig, gm, gs)
                if ok and r then return r end
            end
            return orig(g, sk)
        end
    end
end)

__log("[14] Хуки скинов OK")

-- Применение скинов
local function getWeaponModel()
    if not Cam then return nil end
    for _, ch in pairs(Cam:GetChildren()) do
        if ch:IsA("Model") and ch.Name ~= "Arms" and ch.Name ~= "Arms1"
            and ch.Name ~= "Arms2" and ch.Name ~= "Viewmodel" then
            return ch
        end
    end
    return nil
end

local function applySkinToModel()
    if not SkinData.Root then return end
    local wm = getWeaponModel()
    if not wm then return end
    local own = wm.Name
    local effective = own
    local shouldApply = false

    if isKnife(own) then
        if Cfg.KnifeChangerEnabled then
            effective = Cfg.KnifeModel
            shouldApply = true
        end
    else
        if Cfg.SkinChangerEnabled then
            shouldApply = true
        end
    end
    if not shouldApply then return end

    local sel = Cfg.Skins[effective]
    if not sel or sel == "Default" then return end

    local wf = SkinData.Root:FindFirstChild(effective)
    if not wf then return end
    local sf = wf:FindFirstChild(sel)
    if not sf then return end
    local cf = sf:FindFirstChild("Camera")
    if not cf then return end
    local fn = cf:FindFirstChild("Factory New")
    if not fn then return end

    for _, sa in pairs(fn:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            local target = wm:FindFirstChild(sa.Name, true)
            if target and (target:IsA("BasePart") or target:IsA("MeshPart")) then
                for _, old in pairs(target:GetChildren()) do
                    if old:IsA("SurfaceAppearance") then old:Destroy() end
                end
                sa:Clone().Parent = target
            end
        end
    end
end

local function applyGloves()
    if not Cfg.GloveChangerEnabled then return end
    if not Cam then return end

    local arms
    for _, ch in ipairs(Cam:GetChildren()) do
        if ch:IsA("Model") and (ch.Name:match("Arms") or ch:FindFirstChild("Right Arm")) then
            arms = ch; break
        end
    end
    if not arms then return end

    local lA = arms:FindFirstChild("Left Arm")
    local rA = arms:FindFirstChild("Right Arm")
    if not lA or not rA then return end
    local lG = lA:FindFirstChild("Glove")
    local rG = rA:FindFirstChild("Glove")
    if not lG or not rG then return end

    for _, old in pairs(lG:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
    for _, old in pairs(rG:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end

    local gm = Cfg.GloveModel
    local gs = Cfg.Gloves[gm]
    if not gs or gs == "Default" then return end

    local gf = SkinData.Root:FindFirstChild(gm)
    if not gf then return end
    local sv = gf:FindFirstChild(gs)
    if not sv then return end
    local cf = sv:FindFirstChild("Camera")
    if not cf then return end
    local fn = cf:FindFirstChild("Factory New")
    if not fn then return end

    for _, sa in pairs(fn:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            sa:Clone().Parent = lG
            sa:Clone().Parent = rG
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Cfg.SkinChangerEnabled or Cfg.KnifeChangerEnabled then applySkinToModel() end
            if Cfg.GloveChangerEnabled then applyGloves() end
        end)
    end
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DeNsI_GUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.Parent = LP:WaitForChild("PlayerGui")

local W, H = 520, 380
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
titleLbl.Text = "DeNsI v7"
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
sidebar.Size = UDim2.new(0, 120, 1, -42)
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
content.Size = UDim2.new(1, -136, 1, -48)
content.Position = UDim2.new(0, 130, 0, 42)
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
    b.Size = UDim2.new(1, 0, 0, 24)
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
    lbl.TextSize = 10
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

local function skinRow(parent, title, options, getValue, setValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 6)
    rc.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 16)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local holder = Instance.new("ScrollingFrame")
    holder.Size = UDim2.new(1, -24, 0, 32)
    holder.Position = UDim2.new(0, 12, 0, 24)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.ScrollBarThickness = 0
    holder.CanvasSize = UDim2.new(0, #options * 88, 0, 0)
    holder.ScrollingDirection = Enum.ScrollingDirection.X
    holder.Parent = row

    local hl = Instance.new("UIListLayout")
    hl.FillDirection = Enum.FillDirection.Horizontal
    hl.Padding = UDim.new(0, 4)
    hl.Parent = holder

    local btns = {}
    local function refresh()
        local cur = getValue()
        for _, b in ipairs(btns) do
            if b.Val == cur then
                b.Btn.BackgroundColor3 = Cfg.GuiColor
                b.Btn.TextColor3 = Color3.new(1, 1, 1)
            else
                b.Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
                b.Btn.TextColor3 = Color3.fromRGB(170, 170, 190)
            end
        end
    end

    for _, v in ipairs(options) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 84, 1, 0)
        b.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
        b.BorderSizePixel = 0
        b.Text = tostring(v)
        b.TextColor3 = Color3.fromRGB(170, 170, 190)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 9
        b.TextWrapped = true
        b.AutoButtonColor = false
        b.Parent = holder

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 5)
        bc.Parent = b

        table.insert(btns, {Btn = b, Val = v})

        b.MouseButton1Click:Connect(function()
            setValue(v)
            refresh()
        end)
    end

    refresh()
end

-- ESP tab
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
colorRow(espTab, "Box Color", function(c) Cfg.ESPBoxColor = c end)
colorRow(espTab, "Name Color", function(c) Cfg.ESPNameColor = c end)
colorRow(espTab, "Tracer Color", function(c) Cfg.ESPTracerColor = c end)

-- AIM tab
local aimTab = makeTab("AIM")
section(aimTab, "Silent Aim")
toggle(aimTab, "Silent Aim", "SilentEnabled")
toggle(aimTab, "Team Check", "SilentTeamCheck")
toggle(aimTab, "Visible Only", "SilentVisibleOnly")
toggle(aimTab, "Prediction", "SilentPrediction")
slider(aimTab, "FOV", "SilentFOV", 20, 500, 10)
slider(aimTab, "Distance", "SilentMaxDistance", 100, 3000, 100)
slider(aimTab, "Hit Chance", "SilentHitChance", 1, 100, 1)
section(aimTab, "Aimbot (E)")
toggle(aimTab, "Aimbot", "AimbotEnabled")
toggle(aimTab, "Team Check", "AimbotTeamCheck")
toggle(aimTab, "Prediction", "AimbotPrediction")
slider(aimTab, "Smooth", "AimbotSmooth", 0.5, 20, 0.5)
slider(aimTab, "FOV", "AimbotFOV", 10, 500, 10)

-- Visual tab
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

-- Misc tab
local miscTab = makeTab("MISC")
section(miscTab, "Movement")
toggle(miscTab, "Auto Bhop", "AutoBhop")
slider(miscTab, "Bhop Speed", "BhopSpeed", 5, 30, 1)
section(miscTab, "Effects")
toggle(miscTab, "Anti-Flashbang", "Antiflashbang")
section(miscTab, "Skybox")
toggle(miscTab, "Enable Skybox", "EnableSkybox")

-- Skin tabs
for _, cat in ipairs(CATEGORIES) do
    local availableItems = {}
    for _, item in ipairs(cat.Items) do
        if SkinData.SkinSelections[item] then
            table.insert(availableItems, item)
        end
    end
    if #availableItems > 0 then
        local tab = makeTab(cat.Name)
        section(tab, cat.Name .. " (" .. #availableItems .. ")")
        if cat.Name == "Пистолеты" then
            toggle(tab, "Enable Skin Changer", "SkinChangerEnabled")
        end
        for _, w in ipairs(availableItems) do
            local skins = SkinData.SkinSelections[w]
            if skins then
                skinRow(tab, w, skins,
                    function() return Cfg.Skins[w] or findDefaultSkin(w) end,
                    function(v) Cfg.Skins[w] = v end)
            end
        end
    end
end

-- Knife Model
local knifeTab = makeTab("Knife Model")
section(knifeTab, "Knife Changer")
toggle(knifeTab, "Enable Knife Changer", "KnifeChangerEnabled")

-- Gloves Model
local glovesTab = makeTab("Gloves Model")
section(glovesTab, "Gloves Changer")
toggle(glovesTab, "Enable Gloves Changer", "GloveChangerEnabled")

-- Reset tab
local resetTab = makeTab("Reset")
section(resetTab, "Сброс")
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, 0, 0, 40)
resetBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
resetBtn.BorderSizePixel = 0
resetBtn.Text = "СБРОСИТЬ ВСЕ СКИНЫ"
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 13
resetBtn.Parent = resetTab
local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(0,6); rbc.Parent = resetBtn
resetBtn.MouseButton1Click:Connect(function()
    for w, _ in pairs(SkinData.SkinSelections) do
        Cfg.Skins[w] = findDefaultSkin(w)
    end
    for g, _ in pairs(SkinData.GloveSelections) do
        Cfg.Gloves[g] = "Default"
    end
end)

__log("[15] GUI OK")

-- Кнопка возврата
local reopenBtn = Instance.new("TextButton")
reopenBtn.Name = "DeNsI_Reopen"
reopenBtn.Size = UDim2.new(0, 44, 0, 44)
reopenBtn.Position = UDim2.new(0, 14, 0, 100)
reopenBtn.BackgroundColor3 = Cfg.GuiColor
reopenBtn.BorderSizePixel = 0
reopenBtn.Text = "D"
reopenBtn.TextColor3 = Color3.new(1,1,1)
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 20
reopenBtn.AutoButtonColor = false
reopenBtn.Visible = false
reopenBtn.Active = true
reopenBtn.Parent = gui

local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1,0); rc.Parent = reopenBtn
local rstroke = Instance.new("UIStroke"); rstroke.Color = Color3.new(1,1,1); rstroke.Thickness = 2; rstroke.Transparency = 0.4; rstroke.Parent = reopenBtn

local dragStart, startPos, isDragging, moved = nil, nil, false, false
reopenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true; moved = false; dragStart = input.Position; startPos = reopenBtn.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then moved = true end
        reopenBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

local isMinimized = false
local function minimize()
    if isMinimized then return end
    isMinimized = true; main.Visible = false; reopenBtn.Visible = true
end
local function maximize()
    if not isMinimized then return end
    isMinimized = false; main.Visible = true; reopenBtn.Visible = false
end

reopenBtn.MouseButton1Click:Connect(function() if not moved then maximize() end end)
closeBtn.MouseButton1Click:Connect(function() minimize() end)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        if isMinimized then maximize() else minimize() end
    end
end)

switchTab("ESP")

_G.DeNsI_Cleanup = function()
    for inst, d in pairs(ESPData) do
        pcall(function() d.outline:Remove() end)
        pcall(function() d.name:Remove() end)
        pcall(function() d.dist:Remove() end)
        pcall(function() d.healthBar:Remove() end)
        pcall(function() d.tracer:Remove() end)
    end
    pcall(function() gui:Destroy() end)
end

__log("[16] Всё OK")

end)  -- конец pcall

if not __ok then
    __log("[CRASH] " .. tostring(__err), true)
else
    __log("[OK] Скрипт загружен")
end

task.spawn(function()
    task.wait(20)
    if not __hasErr then
        pcall(function() __dgui:Destroy() end)
    end
end)

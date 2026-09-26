--[[ DeNsI v7 — Part 1: Core ]]

local __dgui = Instance.new("ScreenGui")
__dgui.Name = "DeNsI_Diag"
__dgui.ResetOnSpawn = false
__dgui.DisplayOrder = 999
pcall(function() __dgui.Parent = game:GetService("CoreGui") end)
if not __dgui.Parent then
    __dgui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local __dframe = Instance.new("Frame")
__dframe.Size = UDim2.new(0, 360, 0, 200)
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

local __ok, __err = pcall(function()

local __env_ok = true
if not Drawing or not Drawing.new then __log("Нет Drawing", true); __env_ok = false end
if not hookfunction then __log("Нет hookfunction", true); __env_ok = false end
if not getgc then __log("Нет getgc", true); __env_ok = false end
if not __env_ok then error("Окружение не подходит") end
__log("[1] Окружение OK")

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

local Bullet = nil
pcall(function()
    Bullet = require(RS.Components.Weapon.Classes.Bullet)
end)
__log("[4] Bullet: " .. (Bullet and "OK" or "FAIL"))

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

            local result = { Origin = shot.Origin, Direction = dir, Distance = range, Hits = {} }
            if hit then
                result.Distance = (hit.Position - shot.Origin).Magnitude
                table.insert(result.Hits, {
                    Position = hit.Position, Instance = hit.Instance,
                    Material = hit.Material and hit.Material.Name or "Plastic",
                    Normal = hit.Normal or Vector3.zero, Exit = false,
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
    if not Cfg.AimbotEnabled or not AimbotHeld then AimbotTarget = nil; return end
    if not Cam then return end
    if not AimbotTarget or not AimbotTarget.Part or not AimbotTarget.Part.Parent then
        AimbotTarget = findTarget(Cfg.AimbotMaxDistance, Cfg.AimbotFOV,
            Cfg.AimbotTeamCheck, Cfg.AimbotVisibleOnly, Cfg.AimbotHitPart, "Crosshair")
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

-- === ДИАГНОСТИКА: сообщаем что Часть 1 загружена ===
__log("[Part1] Загружена успешно")
__log("[INFO] Теперь залей Часть 2 (следующее сообщение)")

end)  -- конец pcall части 1

if not __ok then
    __log("[CRASH] " .. tostring(__err), true)
else
    __log("[OK] Часть 1 работает")
end

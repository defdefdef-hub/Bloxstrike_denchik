-- Danny's Cheats | Blox Strike v2 (PasteHub ESP Edition)
-- ESP (PasteHub) + Silent Aim + Effects + Skins + Tracers + Camera + World + Misc
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
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

for _, g in ipairs(LP:WaitForChild("PlayerGui"):GetChildren()) do
    if g.Name:sub(1,3) == "DC_" then g:Destroy() end
end

local State = { Running = true, Connections = {} }
local Aim = { Ready = false, Target = nil }
local Effects = { Ready = false, Records = {} }

local Cfg = {
    -- PasteHub ESP
    ESPEnabled = false, ESPTeamCheck = true,
    ESPBoxType = "2D Box",
    ESPBoxColorA = Color3.fromRGB(255,255,255), ESPBoxColorB = Color3.fromRGB(0,200,255),
    ESPBoxOutline = Color3.fromRGB(0,0,0),
    ESPBoxFillGradient = false,
    ESPFillColorA = Color3.fromRGB(255,50,50), ESPFillColorB = Color3.fromRGB(50,50,255),
    ESPBoxFillRotation = false, ESPBoxRotationSpeed = 2,
    ESPName = false, ESPNameColor = Color3.new(1,1,1),
    ESPHealth = false, ESPHealthTopColor = Color3.fromRGB(0,255,0), ESPHealthBottomColor = Color3.fromRGB(255,0,0),
    ESPHealthText = false, ESPHealthTextColor = Color3.new(1,1,1),
    ESPDistance = false, ESPDistanceColor = Color3.new(1,1,1),
    ESPWeapon = false, ESPWeaponColor = Color3.new(1,1,1),
    ESPTracer = false, ESPTracerColor = Color3.new(1,1,1), ESPTracerColorB = Color3.fromRGB(255,0,128),
    ESPTracerOrigin = "Bottom",
    ESPSkeleton = false, ESPSkeletonColorA = Color3.new(1,1,1), ESPSkeletonColorB = Color3.fromRGB(0,255,255),
    ESPCircularTarget = false, ESPCircularTargetColor = Color3.fromRGB(255,200,0),
    -- Silent Aim
    SilentEnabled = false, SilentTeamCheck = true, SilentVisibleOnly = true,
    SilentTargetPart = "Head", SilentPriority = "Crosshair", SilentMaxDistance = 1200,
    SilentHitChance = 100, SilentFOV = 150, SilentShowTarget = true,
    SilentPrediction = true, SilentBulletSpeed = 1000,
    -- Effects (новые, через хуки)
    Antiflashbang = false, Antismoke = false,
    -- Skins
    SkinChangerEnabled = false, SkinChangerSkins = {},
    KnifeChangerEnabled = false, KnifeChangerModel = "Skeleton Knife",
    GloveChangerEnabled = false, GloveChangerModel = "Sports Gloves", GloveChangerGloves = {},
    -- Tracers
    BulletTracers = false, TracerRainbow = false, TracerStyle = "Block",
    TracerColor = Color3.fromRGB(0,170,255), TracerTime = 2,
    BulletImpacts = false, BulletImpactsColor = Color3.fromRGB(255,0,0),
    GrenadeTracers = false, GrenadeTracerColor = Color3.fromRGB(255,100,0),
    MolotovZoneESP = false, GrenadeZoneColor = Color3.fromRGB(255,60,0),
    SmokeZoneESP = false, SmokeZoneColor = Color3.fromRGB(180,180,180),
    ShowPenetration = false,
    -- Camera
    CustomFovToggle = false, FovAmount = 90,
    ThirdPerson = false, ThirdPersonDist = 10,
    CustomScopeFov = false, ScopeFovValue = 70, RemoveScope = false,
    CustomScopeCrosshair = false, ScopeCrosshairColor = Color3.fromRGB(255,255,255),
    ScopeCrosshairThickness = 2, ScopeCrosshairLengthLR = 150, ScopeCrosshairLengthTB = 100,
    CustomHandsEnabled = false, HandsX = 0.2, HandsY = -0.155, HandsZ = 0.075,
    -- World
    EnableSkybox = false, SkyboxPreset = "Night", WeatherType = "None",
    EnableTime = false, WorldClockTime = 12,
    EnableBrightness = false, WorldBrightness = 2,
    EnableColors = false, WorldAmbient = Color3.fromRGB(127,127,127), WorldOutdoorAmbient = Color3.fromRGB(127,127,127),
    Atmosphere = false, AtmosphereDensity = 0.3, SubAtmosphereHaze = 0, AtmosphereGlare = 0,
    EnableColorCorrection = false, SaturationSlider = 0, ContrastSlider = 0,
    WorldColorToggle = false, WorldColorPicker = Color3.fromRGB(255,255,255),
    SkyColorToggle = false, SkyColorPicker = Color3.fromRGB(255,255,255),
    -- Misc
    AutoBhop = false, BhopSpeed = 18, NoFallDamage = false,
    -- GUI
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

-- =========================================================================
-- [ PASTEHUB ESP ]
-- =========================================================================
local PH = {}

local SKELETON_BONES_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local SKELETON_BONES_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local AABB_CORNER_SIGNS = {
    {0,0,0},{1,0,0},{0,1,0},{1,1,0},{0,0,1},{1,0,1},{0,1,1},{1,1,1},
}
local BOX_3D_EDGES = {
    {1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8},
}

local abs, huge, floor, clamp = math.abs, math.huge, math.floor, math.clamp
local sin, cos, pi, pi2 = math.sin, math.cos, math.pi, math.pi * 2
local WorldToViewportPoint = Cam.WorldToViewportPoint

local BASE_DIST, BASE_W, BASE_H = 20, 86, 155
local _rotAngle = 0
local espinstances = {}
local partHalfExtentCache = setmetatable({},{__mode="k"})
local MAX_FILL_LINES = 400

local function lerpColor(a,b,t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

local function get_part_half_extent(part)
    local c = partHalfExtentCache[part]
    if not c then
        local s = part.Size
        c = {hx=s.X*.5, hy=s.Y*.5, hz=s.Z*.5}
        partHalfExtentCache[part] = c
    end
    return c.hx, c.hy, c.hz
end

local function compute_world_aabb(parts)
    local x0,y0,z0 = huge, huge, huge
    local x1,y1,z1 = -huge, -huge, -huge
    for i=1,#parts do
        local p=parts[i]
        local hx,hy,hz=get_part_half_extent(p)
        local px,py,pz,r00,r01,r02,r10,r11,r12,r20,r21,r22 = p.CFrame:GetComponents()
        local ex=abs(r00)*hx+abs(r01)*hy+abs(r02)*hz
        local ey=abs(r10)*hx+abs(r11)*hy+abs(r12)*hz
        local ez=abs(r20)*hx+abs(r21)*hy+abs(r22)*hz
        if px-ex<x0 then x0=px-ex end; if py-ey<y0 then y0=py-ey end; if pz-ez<z0 then z0=pz-ez end
        if px+ex>x1 then x1=px+ex end; if py+ey>y1 then y1=py+ey end; if pz+ez>z1 then z1=pz+ez end
    end
    if x0==huge then return nil end
    return x0,y0,z0,x1,y1,z1
end

local function project_fixed_box(x0,y0,z0,x1,y1,z1)
    local cx=(x0+x1)*.5; local cy=(y0+y1)*.5; local cz=(z0+z1)*.5
    local sp,vis=WorldToViewportPoint(Cam,Vector3.new(cx,cy,cz))
    if not vis and sp.Z <= 0 then return nil,nil,false end
    local depth=sp.Z
    if depth<=0 then depth = 0.1 end
    local scale=BASE_DIST/depth
    local w=BASE_W*scale
    local h=BASE_H*scale
    local sx,sy=sp.X,sp.Y
    return Vector2.new(sx-w*.5,sy-h*.5), Vector2.new(sx+w*.5,sy+h*.5), true
end

local function project_aabb_corners_3d(x0,y0,z0,x1,y1,z1)
    local sc={}; local on=false
    for i=1,8 do
        local s=AABB_CORNER_SIGNS[i]
        local wx=s[1]==0 and x0 or x1; local wy=s[2]==0 and y0 or y1; local wz=s[3]==0 and z0 or z1
        local pos,vis=WorldToViewportPoint(Cam,Vector3.new(wx,wy,wz))
        sc[i]=Vector2.new(pos.X,pos.Y); if vis then on=true end
    end
    return sc,on
end

local function ensure_character_parts(instance,data)
    if data.partlist then return data.partlist end
    local list={}; local idx=setmetatable({},{__mode="k"})
    local function add(p)
        if p:IsA("BasePart") and not idx[p] then
            list[#list+1]=p; idx[p]=#list
            local c=p:GetPropertyChangedSignal("Size"):Connect(function() partHalfExtentCache[p]=nil end)
            data.sizeConns=data.sizeConns or {}; data.sizeConns[p]=c
        end
    end
    local function rem(p)
        local i=idx[p]; if not i then return end
        local last=#list; local lp=list[last]
        list[i]=lp; idx[lp]=i; list[last]=nil; idx[p]=nil
        if data.sizeConns and data.sizeConns[p] then data.sizeConns[p]:Disconnect(); data.sizeConns[p]=nil end
    end
    if instance:IsA("Model") then
        for _,p in next,instance:GetDescendants() do add(p) end
        data.partConnAdd=instance.DescendantAdded:Connect(add)
        data.partConnRemove=instance.DescendantRemoving:Connect(rem)
    elseif instance:IsA("BasePart") then add(instance) end
    data.partlist=list; return list
end

local function setupFillLines()
    local lines = {}
    for i = 1, MAX_FILL_LINES do
        local l = Drawing.new("Line")
        l.Thickness = 4.0; l.Transparency = 0.3; l.Visible = false
        lines[i] = l
    end
    return lines
end

local function drawFillGradient360(fillLines, x, y, w, h, colorA, colorB, angle)
    local dx = cos(angle); local dy = sin(angle)
    local cx = x + w * 0.5; local cy = y + h * 0.5
    local maxDot = math.max((abs(dx) * w + abs(dy) * h) * 0.5, 1)
    local targetRows = clamp(floor(h * 0.8), 15, MAX_FILL_LINES)
    local rowH = h / targetRows
    for i = 1, targetRows do
        local py = y + (i - 0.5) * rowH
        local dotL = ((x     - cx) * dx + (py - cy) * dy) / maxDot
        local dotR = ((x + w - cx) * dx + (py - cy) * dy) / maxDot
        local tL = clamp(dotL * 0.5 + 0.5, 0, 1)
        local tR = clamp(dotR * 0.5 + 0.5, 0, 1)
        local line = fillLines[i]
        line.Color = lerpColor(colorA, colorB, (tL + tR) * 0.5)
        line.Thickness = clamp(rowH + 1.5, 2, 8)
        line.From  = Vector2.new(x + 1, py)
        line.To    = Vector2.new(x + w - 1, py)
        line.Visible = true
    end
    for i = targetRows + 1, #fillLines do fillLines[i].Visible = false end
end

local GRAD_STEPS = 4
local function drawBoxOutlineGradient(box, x, y, w, h, colorA, colorB, rotOff)
    local grad=box.grad_lines; local idx=0
    local sides={{x,y,x+w,y},{x+w,y,x+w,y+h},{x+w,y+h,x,y+h},{x,y+h,x,y}}
    for si=1,4 do
        local s=sides[si]; local x1,y1,x2,y2=s[1],s[2],s[3],s[4]
        for step=0,GRAD_STEPS-1 do
            idx=idx+1
            local tA=step/GRAD_STEPS; local tB=(step+1)/GRAD_STEPS
            local tMid=(((si-1)/4)+(tA/4)+rotOff)%1
            local col=lerpColor(colorA,colorB,tMid)
            local line=grad[idx]
            if line then
                line.From=Vector2.new(x1+(x2-x1)*tA,y1+(y2-y1)*tA)
                line.To  =Vector2.new(x1+(x2-x1)*tB,y1+(y2-y1)*tB)
                line.Color=col; line.Visible=true
            end
        end
    end
    for i=idx+1,#grad do grad[i].Visible=false end
end

local function hideBox(box)
    box.outline.Visible=false; box.fill.Visible=false
    for _,l in ipairs(box.grad_lines)      do l.Visible=false end
    for _,l in ipairs(box.fill_grad_lines)  do l.Visible=false end
    for _,l in ipairs(box.corner_fill)     do l.Visible=false end
    for _,l in ipairs(box.corner_outline)   do l.Visible=false end
    for _,l in ipairs(box.box_3d_lines)    do l.Visible=false end
end

local function esp_add_box(instance)
    if not instance or (espinstances[instance] and espinstances[instance].box) then return end
    local function mkLine(th) local l=Drawing.new("Line"); l.Thickness=th; l.Transparency=1; l.Visible=false; return l end
    local function mkSq(th,f) local s=Drawing.new("Square"); s.Thickness=th; s.Filled=f; s.Transparency=1; s.Visible=false; return s end
    local box={}
    box.outline=mkSq(3,false); box.fill=mkSq(1,false)
    box.grad_lines={}; for i=1,16 do box.grad_lines[i]=mkLine(1) end
    box.fill_grad_lines = setupFillLines()
    box.corner_fill={}; box.corner_outline={}
    for i=1,8 do box.corner_fill[i]=mkLine(1); box.corner_outline[i]=mkLine(3) end
    box.box_3d_lines={}; for i=1,12 do box.box_3d_lines[i]=mkLine(2) end
    espinstances[instance]=espinstances[instance] or {}
    espinstances[instance].box=box
end

local MAX_HP_SEGMENTS = 12
local function esp_add_healthbar(instance)
    if not instance or (espinstances[instance] and espinstances[instance].healthbar) then return end
    local bg = Drawing.new("Square")
    bg.Thickness = 1; bg.Filled = true; bg.Color = Color3.new(0, 0, 0)
    bg.Transparency = 0.5; bg.Visible = false
    local segs = {}
    for i = 1, MAX_HP_SEGMENTS do
        local l = Drawing.new("Line")
        l.Thickness = 3; l.Transparency = 1; l.Visible = false
        segs[i] = l
    end
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].healthbar = { background = bg, segments = segs }
end

local function esp_add_healthtext(instance)
    if not instance or (espinstances[instance] and espinstances[instance].healthtext) then return end
    local t = Drawing.new("Text")
    t.Center = false; t.Outline = true; t.Font = 1; t.Transparency = 1; t.Visible = false
    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].healthtext = t
end

local function esp_add_name(instance)
    if not instance or (espinstances[instance] and espinstances[instance].name) then return end
    local t=Drawing.new("Text"); t.Center=true; t.Outline=true; t.Font=1; t.Transparency=1
    espinstances[instance]=espinstances[instance] or {}; espinstances[instance].name=t
end

local function esp_add_distance(instance)
    if not instance or (espinstances[instance] and espinstances[instance].distance) then return end
    local t=Drawing.new("Text"); t.Center=true; t.Outline=true; t.Font=1; t.Transparency=1
    espinstances[instance]=espinstances[instance] or {}; espinstances[instance].distance=t
end

local function esp_add_tracer(instance)
    if not instance or (espinstances[instance] and espinstances[instance].tracer) then return end
    local o=Drawing.new("Line"); o.Thickness=3; o.Transparency=1
    local f=Drawing.new("Line"); f.Thickness=1; f.Transparency=1
    espinstances[instance]=espinstances[instance] or {}; espinstances[instance].tracer={outline=o,fill=f}
end

local function esp_add_skeleton(instance,options)
    if not instance or (espinstances[instance] and espinstances[instance].skeleton) then return end
    options=options or {}
    local isR15=instance:FindFirstChild("UpperTorso")~=nil
    local bones=isR15 and SKELETON_BONES_R15 or SKELETON_BONES_R6
    local lines={}; local bp={}
    for i=1,#bones do
        local l=Drawing.new("Line"); l.Thickness=options.thickness or 2; l.Transparency=1; l.Visible=false; lines[i]=l
        bp[i]={instance:FindFirstChild(bones[i][1]),instance:FindFirstChild(bones[i][2])}
    end
    espinstances[instance]=espinstances[instance] or {}
    espinstances[instance].skeleton={lines=lines,bone_parts=bp,screenCache={}}
end

local function esp_add_weapon(instance)
    if not instance or (espinstances[instance] and espinstances[instance].weapon) then return end
    local t=Drawing.new("Text"); t.Center=true; t.Outline=true; t.Font=1; t.Transparency=1; t.Visible=false
    espinstances[instance]=espinstances[instance] or {}; espinstances[instance].weapon=t
end

local function esp_add_circulartarget(instance)
    if not instance or (espinstances[instance] and espinstances[instance].circulartarget) then return end
    local SEGS=32; local lines={}
    for i=1,SEGS do local l=Drawing.new("Line"); l.Thickness=1.5; l.Transparency=1; l.Visible=false; lines[i]=l end
    local TRAIL_SEGS = 25
    local trailLines = {}
    local neonGlowLines = {}
    for i = 1, TRAIL_SEGS do
        local l = Drawing.new("Line")
        l.Thickness = 2.5; l.Transparency = 0.4; l.Visible = false
        trailLines[i] = l
        local glow = Drawing.new("Line")
        glow.Thickness = 5.0; glow.Transparency = 0.15; glow.Visible = false
        neonGlowLines[i] = glow
    end
    espinstances[instance]=espinstances[instance] or {}
    espinstances[instance].circulartarget={
        lines = lines, trailLines = trailLines, neonGlowLines = neonGlowLines,
        segments = SEGS, alpha = 0, movingUp = true, trailHistory = {}
    }
end

local function hide_all(data)
    if data.box      then hideBox(data.box) end
    if data.healthbar then
        data.healthbar.background.Visible=false
        for _,seg in ipairs(data.healthbar.segments) do seg.Visible=false end
    end
    if data.healthtext then data.healthtext.Visible=false end
    if data.name      then data.name.Visible=false end
    if data.distance  then data.distance.Visible=false end
    if data.tracer    then data.tracer.outline.Visible=false; data.tracer.fill.Visible=false end
    if data.skeleton  then for _,l in ipairs(data.skeleton.lines) do l.Visible=false end end
    if data.weapon    then data.weapon.Visible=false end
    if data.circulartarget then
        for _,l in ipairs(data.circulartarget.lines) do l.Visible=false end
        for _,l in ipairs(data.circulartarget.trailLines) do l.Visible=false end
        for _,l in ipairs(data.circulartarget.neonGlowLines) do l.Visible=false end
    end
end

local function cleanup_instance(instance,data)
    pcall(function()
        if data.box then
            data.box.outline:Remove(); data.box.fill:Remove()
            for _,l in next,data.box.grad_lines      do l:Remove() end
            for _,l in next,data.box.fill_grad_lines  do l:Remove() end
            for _,l in next,data.box.corner_fill      do l:Remove() end
            for _,l in next,data.box.corner_outline   do l:Remove() end
            for _,l in next,data.box.box_3d_lines     do l:Remove() end
        end
        if data.healthbar  then
            data.healthbar.background:Remove()
            for _,seg in ipairs(data.healthbar.segments) do seg:Remove() end
        end
        if data.healthtext then data.healthtext:Remove() end
        if data.name       then data.name:Remove() end
        if data.distance   then data.distance:Remove() end
        if data.tracer     then data.tracer.outline:Remove(); data.tracer.fill:Remove() end
        if data.skeleton   then for _,l in next,data.skeleton.lines do l:Remove() end end
        if data.weapon     then data.weapon:Remove() end
        if data.circulartarget then
            for _,l in ipairs(data.circulartarget.lines) do l:Remove() end
            for _,l in ipairs(data.circulartarget.trailLines) do l:Remove() end
            for _,l in ipairs(data.circulartarget.neonGlowLines) do l:Remove() end
        end
        if data.partConnAdd    then data.partConnAdd:Disconnect() end
        if data.partConnRemove then data.partConnRemove:Disconnect() end
        if data.sizeConns then for _,c in next,data.sizeConns do c:Disconnect() end end
    end)
end

local weaponAttrCache={}; local weaponNameCache={}
local function GetWeaponName(player)
    if not player then return "None" end
    local attr=player:GetAttribute("CurrentEquipped")
    if attr~=weaponAttrCache[player] then
        weaponAttrCache[player]=attr
        if attr then
            local ok,dec=pcall(function() return HS:JSONDecode(attr) end)
            weaponNameCache[player]=(ok and dec and dec.Name) or "None"
        else weaponNameCache[player]="None" end
    end
    return weaponNameCache[player] or "None"
end

local function get_cached_screen_pos(cache,part)
    local c=cache[part]; if c then return c[1],c[2] end
    local pos,vis=WorldToViewportPoint(Cam,part.Position)
    local sp=Vector2.new(pos.X,pos.Y); cache[part]={sp,vis}; return sp,vis
end

RunService.RenderStepped:Connect(function(dt)
    if Cfg.ESPBoxFillRotation then
        _rotAngle = (_rotAngle + dt * (Cfg.ESPBoxRotationSpeed or 2)) % pi2
    end
    local camPos = Cam.CFrame.Position
    local vp = Cam.ViewportSize
    local teamCheck = Cfg.ESPTeamCheck
    local rotOff1 = _rotAngle / pi2

    for instance,data in next,espinstances do
        if not instance or not instance.Parent then
            cleanup_instance(instance,data); espinstances[instance]=nil; continue
        end
        if instance == LP.Character then hide_all(data); continue end

        if instance:IsA("Model") and not instance.PrimaryPart then
            local head = instance:FindFirstChild("Head")
            local torso = instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso") or instance:FindFirstChild("UpperTorso")
            if head then instance.PrimaryPart = head elseif torso then instance.PrimaryPart = torso end
        end

        if teamCheck then
            local isAlly = false
            local myHasVest = LP.Character and LP.Character:FindFirstChild("CharacterArmor") and LP.Character.CharacterArmor:FindFirstChild("VestDetails")
            local targetHasVest = instance:FindFirstChild("CharacterArmor") and instance.CharacterArmor:FindFirstChild("VestDetails")
            if myHasVest then isAlly = not targetHasVest else isAlly = (targetHasVest ~= nil) end
            if isAlly then hide_all(data); continue end
        end

        local healthAttr = instance:GetAttribute("Health")
        local maxHealthAttr = instance:GetAttribute("MaxHealth") or 100
        local isDeadAttr = instance:GetAttribute("Dead")
        if isDeadAttr == true or (healthAttr and healthAttr <= 0) then hide_all(data); continue end

        local needBox    = Cfg.ESPEnabled and Cfg.ESPBoxType ~= "Disabled" and data.box ~= nil
        local needHp     = Cfg.ESPHealth and data.healthbar~=nil
        local needHpTxt  = Cfg.ESPHealthText and data.healthtext~=nil
        local needName   = Cfg.ESPName and data.name ~=nil
        local needDist   = Cfg.ESPDistance and data.distance ~=nil
        local needTracer = Cfg.ESPTracer and data.tracer ~=nil
        local needSkel   = Cfg.ESPSkeleton and data.skeleton ~=nil
        local needWep    = Cfg.ESPWeapon and data.weapon ~=nil
        local needCirc   = Cfg.ESPCircularTarget and data.circulartarget ~=nil

        if data.box      and not needBox    then hideBox(data.box) end
        if data.healthbar and not needHp    then
            data.healthbar.background.Visible=false
            for _,seg in ipairs(data.healthbar.segments) do seg.Visible=false end
        end
        if data.healthtext and not needHpTxt then data.healthtext.Visible=false end
        if data.name     and not needName   then data.name.Visible=false end
        if data.distance and not needDist   then data.distance.Visible=false end
        if data.tracer   and not needTracer then data.tracer.outline.Visible=false; data.tracer.fill.Visible=false end
        if data.skeleton and not needSkel   then for _,l in ipairs(data.skeleton.lines) do l.Visible=false end end
        if data.weapon   and not needWep    then data.weapon.Visible=false end
        if data.circulartarget and not needCirc then
            for _,l in ipairs(data.circulartarget.lines) do l.Visible=false end
            for _,l in ipairs(data.circulartarget.trailLines) do l.Visible=false end
            for _,l in ipairs(data.circulartarget.neonGlowLines) do l.Visible=false end
        end
        if not(needBox or needHp or needHpTxt or needName or needDist or needTracer or needSkel or needWep or needCirc) then continue end

        local parts=ensure_character_parts(instance,data)
        local min2,max2,onscreen=nil,nil,false
        local c3d,on3d=nil,false
        local x0,y0,z0,x1,y1,z1=compute_world_aabb(parts)
        if x0 then
            min2,max2,onscreen=project_fixed_box(x0,y0,z0,x1,y1,z1)
            if needBox and Cfg.ESPBoxType=="3D Box" then
                c3d,on3d=project_aabb_corners_3d(x0,y0,z0,x1,y1,z1)
            end
        end

        if data.box then
            if needBox and onscreen and min2 and max2 then
                local x,y = min2.X,min2.Y
                local w = max2.X-min2.X
                local h = max2.Y-min2.Y
                local cA = Cfg.ESPBoxColorA; local cB = Cfg.ESPBoxColorB
                local fA = Cfg.ESPFillColorA; local fB = Cfg.ESPFillColorB

                if Cfg.ESPBoxType=="2D Box" then
                    if Cfg.ESPBoxFillGradient then
                        drawFillGradient360(data.box.fill_grad_lines, x, y, w, h, fA, fB, _rotAngle)
                    else
                        for _,l in ipairs(data.box.fill_grad_lines) do l.Visible=false end
                    end
                    drawBoxOutlineGradient(data.box, x, y, w, h, cA, cB, rotOff1)
                    data.box.outline.Visible=false; data.box.fill.Visible=false
                    for _,l in ipairs(data.box.corner_fill)   do l.Visible=false end
                    for _,l in ipairs(data.box.corner_outline) do l.Visible=false end
                    for _,l in ipairs(data.box.box_3d_lines)   do l.Visible=false end
                elseif Cfg.ESPBoxType=="Corner Box" then
                    for _,l in ipairs(data.box.grad_lines) do l.Visible=false end
                    data.box.outline.Visible=false; data.box.fill.Visible=false
                    if Cfg.ESPBoxFillGradient then
                        drawFillGradient360(data.box.fill_grad_lines, x, y, w, h, fA, fB, _rotAngle)
                    else for _,l in ipairs(data.box.fill_grad_lines) do l.Visible=false end end
                    local len=math.min(w,h)*.25
                    local corners={
                        {Vector2.new(x,y),     Vector2.new(x+len,y)  },
                        {Vector2.new(x,y),     Vector2.new(x,y+len)  },
                        {Vector2.new(x+w-len,y),Vector2.new(x+w,y)   },
                        {Vector2.new(x+w,y),   Vector2.new(x+w,y+len)},
                        {Vector2.new(x,y+h),   Vector2.new(x+len,y+h)},
                        {Vector2.new(x,y+h-len),Vector2.new(x,y+h)   },
                        {Vector2.new(x+w-len,y+h),Vector2.new(x+w,y+h)},
                        {Vector2.new(x+w,y+h-len),Vector2.new(x+w,y+h)},
                    }
                    for i=1,8 do
                        local t=(i-1)/8; local col=lerpColor(cA,cB,t)
                        data.box.corner_outline[i].From=corners[i][1]; data.box.corner_outline[i].To=corners[i][2]
                        data.box.corner_outline[i].Color=Cfg.ESPBoxOutline; data.box.corner_outline[i].Visible=true
                        data.box.corner_fill[i].From=corners[i][1]; data.box.corner_fill[i].To=corners[i][2]
                        data.box.corner_fill[i].Color=col; data.box.corner_fill[i].Visible=true
                    end
                    for _,l in ipairs(data.box.box_3d_lines) do l.Visible=false end
                elseif Cfg.ESPBoxType=="3D Box" then
                    for _,l in ipairs(data.box.fill_grad_lines) do l.Visible=false end
                    for _,l in ipairs(data.box.grad_lines)      do l.Visible=false end
                    data.box.outline.Visible=false; data.box.fill.Visible=false
                    for _,l in ipairs(data.box.corner_fill)   do l.Visible=false end
                    for _,l in ipairs(data.box.corner_outline) do l.Visible=false end
                    if c3d and #c3d==8 then
                        for i=1,12 do
                            local e=BOX_3D_EDGES[i]
                            data.box.box_3d_lines[i].From=c3d[e[1]]; data.box.box_3d_lines[i].To=c3d[e[2]]
                            data.box.box_3d_lines[i].Color=lerpColor(cA,cB,(i-1)/12)
                            data.box.box_3d_lines[i].Visible=on3d
                        end
                    else for _,l in ipairs(data.box.box_3d_lines) do l.Visible=false end end
                end
            else hideBox(data.box) end
        end

        if data.healthbar then
            local bg = data.healthbar.background
            local segs = data.healthbar.segments
            if needHp and onscreen and min2 and max2 and healthAttr then
                local x = min2.X - 6
                local y = min2.Y
                local w = 3
                local h = max2.Y - min2.Y
                local maxHp = maxHealthAttr > 0 and maxHealthAttr or 100
                local hpFraction = clamp(healthAttr / maxHp, 0, 1)
                bg.Position = Vector2.new(x - 1, y - 1)
                bg.Size = Vector2.new(w + 2, h + 2)
                bg.Visible = true
                local barHeight = h * hpFraction
                local startY = y + (h - barHeight)
                local activeSegCount = clamp(floor(MAX_HP_SEGMENTS * hpFraction), 1, MAX_HP_SEGMENTS)
                local segH = barHeight / activeSegCount
                for i = 1, MAX_HP_SEGMENTS do
                    local segLine = segs[i]
                    if i <= activeSegCount then
                        local segmentFraction = (i - 0.5) / MAX_HP_SEGMENTS
                        segLine.Color = lerpColor(Cfg.ESPHealthBottomColor, Cfg.ESPHealthTopColor, segmentFraction)
                        local py1 = startY + (i - 1) * segH
                        local py2 = startY + i * segH
                        segLine.From = Vector2.new(x + w * 0.5, py1)
                        segLine.To = Vector2.new(x + w * 0.5, py2)
                        segLine.Thickness = w
                        segLine.Visible = true
                    else segLine.Visible = false end
                end
            else
                bg.Visible = false
                for _,seg in ipairs(segs) do seg.Visible = false end
            end
        end

        if data.healthtext then
            if needHpTxt and onscreen and min2 and max2 and healthAttr then
                local currentHp = floor(healthAttr + 0.5)
                local maxHp = maxHealthAttr > 0 and maxHealthAttr or 100
                data.healthtext.Text = tostring(currentHp)
                data.healthtext.Size = 12
                data.healthtext.Color = Cfg.ESPHealthTextColor
                local textX = max2.X + 4
                local textY = min2.Y + (max2.Y - min2.Y) * (1 - (healthAttr / maxHp)) - 4
                data.healthtext.Position = Vector2.new(textX, textY)
                data.healthtext.Visible = true
            else data.healthtext.Visible = false end
        end

        if data.name then
            if needName and onscreen and min2 and max2 then
                data.name.Text=instance.Name; data.name.Size=13; data.name.Color=Cfg.ESPNameColor
                data.name.Position=Vector2.new((min2.X+max2.X)*.5,min2.Y-15); data.name.Visible=true
            else data.name.Visible=false end
        end

        if data.distance then
            if needDist and onscreen and min2 and max2 then
                local dist=999
                if instance:IsA("Model") and instance.PrimaryPart then dist=(camPos-instance.PrimaryPart.Position).Magnitude
                elseif instance:IsA("BasePart") then dist=(camPos-instance.Position).Magnitude end
                data.distance.Text=tostring(floor(dist)).."m"; data.distance.Size=13
                data.distance.Color=Cfg.ESPDistanceColor
                data.distance.Position=Vector2.new((min2.X+max2.X)*.5,max2.Y+2); data.distance.Visible=true
            else data.distance.Visible=false end
        end

        if data.weapon then
            if needWep and onscreen and min2 and max2 then
                if not data.player then data.player=Players:GetPlayerFromCharacter(instance) end
                local wn=data.player and GetWeaponName(data.player) or "None"
                data.weapon.Text="["..wn.."]"; data.weapon.Size=13
                data.weapon.Color=Cfg.ESPWeaponColor
                data.weapon.Position=Vector2.new((min2.X+max2.X)*.5,max2.Y+15)
                data.weapon.Center=true; data.weapon.Visible=true
            else data.weapon.Visible=false end
        end

        if data.tracer then
            if needTracer and onscreen and min2 and max2 then
                local from_pos
                local originMode = Cfg.ESP tracerOrigin or "Bottom"
                if originMode=="Mouse" then local ml=UIS:GetMouseLocation(); from_pos=Vector2.new(ml.X,ml.Y)
                elseif originMode=="Top" then from_pos=Vector2.new(vp.X/2,0)
                elseif originMode=="Center" then from_pos=Vector2.new(vp.X/2,vp.Y/2)
                else from_pos=Vector2.new(vp.X/2,vp.Y) end
                local to_pos=(min2+max2)/2
                local dist=0
                if instance:IsA("Model") and instance.PrimaryPart then dist=clamp((camPos-instance.PrimaryPart.Position).Magnitude/200,0,1) end
                local col=lerpColor(Cfg.ESPTracerColor,Cfg.ESPTracerColorB,dist)
                data.tracer.outline.From=from_pos; data.tracer.outline.To=to_pos; data.tracer.outline.Color=Color3.new(0,0,0); data.tracer.outline.Visible=true
                data.tracer.fill.From=from_pos; data.tracer.fill.To=to_pos; data.tracer.fill.Color=col; data.tracer.fill.Visible=true
            else data.tracer.outline.Visible=false; data.tracer.fill.Visible=false end
        end

        if data.skeleton then
            if needSkel then
                local bp=data.skeleton.bone_parts; local lines=data.skeleton.lines; local sc=data.skeleton.screenCache
                for k in next,sc do sc[k]=nil end
                local anyDrawn = false
                for i=1,#bp do
                    local pair=bp[i]; local pA,pB=pair[1],pair[2]; local line=lines[i]
                    if pA and pB and pA.Parent and pB.Parent then
                        local posA,vA=get_cached_screen_pos(sc,pA); local posB,vB=get_cached_screen_pos(sc,pB)
                        if vA or vB then
                            line.From=posA; line.To=posB
                            line.Color=lerpColor(Cfg.ESPSkeletonColorA,Cfg.ESPSkeletonColorB,(i-1)/#bp)
                            line.Thickness=2; line.Visible=true
                            anyDrawn = true
                        else line.Visible=false end
                    else line.Visible=false end
                end
                if not anyDrawn then for _,l in ipairs(lines) do l.Visible=false end end
            else for _,l in ipairs(data.skeleton.lines) do l.Visible=false end end
        end

        if data.circulartarget then
            local ct = data.circulartarget
            local head = instance:FindFirstChild("Head")
            local root = instance:IsA("Model") and instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or head
            if needCirc and head and root then
                local speed = 2.0
                if ct.movingUp then
                    ct.alpha = ct.alpha + dt * speed
                    if ct.alpha >= 1 then ct.alpha = 1; ct.movingUp = false end
                else
                    ct.alpha = ct.alpha - dt * speed
                    if ct.alpha <= 0 then ct.alpha = 0; ct.movingUp = true end
                end
                local footPos = root.Position - Vector3.new(0, (root.Size.Y * 0.8) + 1.2, 0)
                local headPos = head.Position + Vector3.new(0, 0.3, 0)
                local currentWorldPos = footPos:Lerp(headPos, ct.alpha)
                table.insert(ct.trailHistory, 1, currentWorldPos)
                if #ct.trailHistory > #ct.trailLines then table.remove(ct.trailHistory) end
                for i = 1, #ct.trailLines do
                    local trailLine = ct.trailLines[i]
                    local glowLine = ct.neonGlowLines[i]
                    local p1 = ct.trailHistory[i]
                    local p2 = ct.trailHistory[i + 1]
                    if p1 and p2 then
                        local s1, v1 = WorldToViewportPoint(Cam, p1)
                        local s2, v2 = WorldToViewportPoint(Cam, p2)
                        if v1 or v2 then
                            local fadeFactor = clamp(1 - (i / #ct.trailLines), 0.05, 1)
                            glowLine.From = Vector2.new(s1.X, s1.Y); glowLine.To = Vector2.new(s2.X, s2.Y)
                            glowLine.Color = Cfg.ESPCircularTargetColor
                            glowLine.Transparency = fadeFactor * 0.35; glowLine.Visible = true
                            trailLine.From = Vector2.new(s1.X, s1.Y); trailLine.To = Vector2.new(s2.X, s2.Y)
                            trailLine.Color = Cfg.ESPCircularTargetColor
                            trailLine.Transparency = fadeFactor * 0.85; trailLine.Visible = true
                        else trailLine.Visible = false; glowLine.Visible = false end
                    else trailLine.Visible = false; glowLine.Visible = false end
                end
                local R = 2.2; local SEGS = ct.segments
                for i = 1, SEGS do
                    local aA = pi2 * ((i - 1) / SEGS)
                    local aB = pi2 * (i / SEGS)
                    local wA = currentWorldPos + Vector3.new(cos(aA) * R, 0, sin(aA) * R)
                    local wB = currentWorldPos + Vector3.new(cos(aB) * R, 0, sin(aB) * R)
                    local sA, vA = WorldToViewportPoint(Cam, wA)
                    local sB, vB = WorldToViewportPoint(Cam, wB)
                    local line = ct.lines[i]
                    if vA or vB then
                        line.From = Vector2.new(sA.X, sA.Y); line.To = Vector2.new(sB.X, sB.Y)
                        line.Color = Cfg.ESPCircularTargetColor; line.Visible = true
                    else line.Visible = false end
                end
            else
                for _,l in ipairs(ct.lines) do l.Visible=false end
                for _,l in ipairs(ct.trailLines) do l.Visible=false end
                for _,l in ipairs(ct.neonGlowLines) do l.Visible=false end
            end
        end
    end
end)

local espCharacters={}
local function addEspToCharacter(character)
    if not character or espCharacters[character] then return end
    if character == LP.Character then return end
    esp_add_box(character)
    esp_add_name(character)
    esp_add_healthbar(character)
    esp_add_healthtext(character)
    esp_add_distance(character)
    esp_add_tracer(character)
    esp_add_skeleton(character, {thickness=2})
    esp_add_weapon(character)
    esp_add_circulartarget(character)
    espCharacters[character]=true
end
local function removeEspFromCharacter(character)
    if character then
        if espinstances[character] then
            cleanup_instance(character, espinstances[character])
            espinstances[character] = nil
        end
        espCharacters[character]=nil
    end
end
local charactersFolder = workspace:WaitForChild("Characters", 5)
local function scanCharactersFolder()
    if not charactersFolder then return end
    local function processContainer(container)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") then
                if child:GetAttribute("Health") ~= nil or child:FindFirstChild("Head") then addEspToCharacter(child) end
                processContainer(child)
            end
        end
    end
    processContainer(charactersFolder)
end
scanCharactersFolder()
if charactersFolder then
    charactersFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Model") then
            task.wait(0.1)
            if descendant:GetAttribute("Health") ~= nil or descendant:FindFirstChild("Head") then addEspToCharacter(descendant) end
        end
    end)
    charactersFolder.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("Model") then removeEspFromCharacter(descendant) end
    end)
end

-- ====== [ОБРЫВ ЗДЕСЬ] ======

-- =========================================================================
-- [ SILENT AIM ]
-- =========================================================================
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

-- =========================================================================
-- [ SKIN CHANGER ]
-- =========================================================================
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
        local SM = RS:FindFirstChild("Database") and RS.Database:FindFirstChild("Components")
            and RS.Database.Components:FindFirstChild("Libraries") and RS.Database.Components.Libraries:FindFirstChild("Skins")
        local VM = RS:FindFirstChild("Classes") and RS.Classes:FindFirstChild("WeaponComponent")
            and RS.Classes.WeaponComponent:FindFirstChild("Classes") and RS.Classes.WeaponComponent.Classes:FindFirstChild("Viewmodel")
        if not SM or not VM then return end
        local Sk = SafeRequire(SM); local Vm = SafeRequire(VM)
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
    local own = wm.Name; local ewn = own; local ca = false
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
    local la = am:FindFirstChild("Left Arm"); local ra = am:FindFirstChild("Right Arm")
    if not la or not ra then return end
    local lg = la:FindFirstChild("Glove"); local rg = ra:FindFirstChild("Glove")
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
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Cfg.SkinChangerEnabled or Cfg.KnifeChangerEnabled then ApplySkin() end
            if Cfg.GloveChangerEnabled then ApplyGloves() end
        end)
    end
end)

-- =========================================================================
-- [ GC HOOKS (Anti-Flash / Anti-Smoke) ]
-- =========================================================================
pcall(function()
    for _, obj in next, getgc(true) do
        if type(obj) == "function" and debug.getinfo(obj).name == "Flash" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if Cfg.Antiflashbang then return end
                    return old(...)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "CreateVoxel" and debug.getupvalue(obj, 1) and tostring(debug.getupvalue(obj, 1)) == "Smoke" then
            pcall(function()
                local old
                old = hookfunction(obj, function(...)
                    if Cfg.Antismoke then return end
                    return old(...)
                end)
            end)
        end
    end
end)

-- =========================================================================
-- [ FOV CIRCLE (Silent Aim target ring) ]
-- =========================================================================
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
ringStroke.Color = Cfg.GuiColor; ringStroke.Thickness = 3; ringStroke.Parent = targetRing
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

task.spawn(function()
    while task.wait(0.05) do
        if not Cfg.SilentEnabled or not Aim.Ready then Aim.Target = nil
        else
            local cam = workspace.CurrentCamera
            if cam and aimAllowed() then
                Aim.Target = selectTarget(cam, cam.CFrame.Position, Cfg.SilentMaxDistance, false)
            else Aim.Target = nil end
        end
    end
end)

connect(Players.PlayerRemoving, function(p) end)

-- ====== [ОБРЫВ 2] ======
-- =========================================================================
-- [ TRACERS / IMPACTS / GRENADES / ZONE ESP / PENETRATION ]
-- =========================================================================

local PH_Sound = SoundService
local PH_Lighting = Lighting

-- --- Hit Sound ---
local HitSoundPresets = {
    Neverlose="rbxassetid://139452805868562", Skeet="rbxassetid://83717596220569",
    Bell="rbxassetid://96481309571950", Bell2="rbxassetid://124010691633262",
    Bubble="rbxassetid://104824514322839", Rust="rbxassetid://1255040462",
    Agro1="rbxassetid://132463144859699", Agro2="rbxassetid://102651850556408",
    Coins="rbxassetid://5613553529", Schaater="rbxassetid://17405655409",
    Pick="rbxassetid://8616930816",
}

-- --- Penetration Stats ---
local MaterialLimits = {
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
local MatVarLimits = { ["IndoorWall"]=0.25, ["Sandy Brick"]=0.25 }

local function GetPenStats(origin, direction, maxPen, ignoreList, targetRoot)
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
            if variant ~= "" and MatVarLimits[variant] then
                limit = MatVarLimits[variant]
                accVar[variant] = (accVar[variant] or 0) + thick
                if accVar[variant] > limit + maxPen then stats.FailReason="Var"; return stats end
            else
                local mat = br.Material
                limit = MaterialLimits[mat] or 0.25
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
        if not Cfg.ShowPenetration or not Cam then PenText.Visible=false; return end
        PenText.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2 - 70)
        penParams.FilterDescendantsInstances = {LP.Character, Cam}
        local res = workspace:Raycast(Cam.CFrame.Position, Cam.CFrame.LookVector*1000, penParams)
        if res then
            local st = GetPenStats(Cam.CFrame.Position, Cam.CFrame.LookVector, 4, {LP.Character, Cam}, nil)
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

-- --- Tracers + Shoot Hook ---
local SendFunc = nil
local getCurrentEquipped = nil
pcall(function()
    for _, obj in next, getgc(true) do
        if type(obj) == "table" and rawget(obj, "shoot") and typeof(obj.shoot) == "function" then
            pcall(function()
                for _, uv in pairs(debug.getupvalues(obj.shoot)) do
                    if type(uv) == "table" and rawget(uv, "Inventory") and rawget(uv.Inventory, "ShootWeapon") then
                        SendFunc = uv.Inventory.ShootWeapon.Send
                        break
                    end
                end
            end)
        end
        if type(obj) == "table" and rawget(obj, "getCurrentEquipped") then
            pcall(function() getCurrentEquipped = obj.getCurrentEquipped end)
        end
    end
end)

local function CreateTracer(startPos, endPos)
    if not Cfg.BulletTracers then return end
    if not startPos or not endPos then return end
    local style = Cfg.TracerStyle or "Block"
    local color = Cfg.TracerColor or Color3.fromRGB(0,170,255)
    if Cfg.TracerRainbow then color = Color3.fromHSV((tick()%5)/5, 1, 1) end
    local duration = Cfg.TracerTime or 2
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
            if Cfg.TracerRainbow then bp.Color = Color3.fromHSV((tick()%5)/5, 1, 1) end
            task.wait()
        end
        bp:Destroy()
    end)
end

local function CreateImpact(hitPos)
    if not Cfg.BulletImpacts or not hitPos then return end
    local p = Instance.new("Part")
    p.Name = "DC_Impact"; p.Size = Vector3.new(0.6, 0.6, 0.6)
    p.Shape = Enum.PartType.Block; p.Position = hitPos
    p.Anchored = true; p.CanCollide = false
    p.Material = Enum.Material.Neon; p.Color = Cfg.BulletImpactsColor
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
    if not SendFunc then return end
    local oldshoot
    oldshoot = hookfunction(SendFunc, function(...)
        local args = {...}
        if args[1] and type(args[1].Bullets) == "table" then
            for _, bullet in pairs(args[1].Bullets) do
                if type(bullet.Hits) == "table" then
                    for _, hd in pairs(bullet.Hits) do
                        pcall(function()
                            if Cam and hd.Position then
                                CreateTracer(Cam.CFrame.Position, hd.Position)
                                CreateImpact(hd.Position)
                            end
                        end)
                    end
                end
            end
        end
        return oldshoot(unpack(args))
    end)
end)

-- --- Grenade Tracers ---
local GrenadeTracers = {}
local function StartGrenadeTracer(part)
    if not part or not part:IsA("BasePart") then return end
    if GrenadeTracers[part] then return end
    local MAX_T = 30
    local history, lines = {}, {}
    for i = 1, MAX_T do
        local l = Drawing.new("Line")
        l.Visible=false; l.Thickness=2; l.Transparency=1
        lines[i] = l
    end
    GrenadeTracers[part] = lines
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local en = Cfg.GrenadeTracers
        local col = Cfg.GrenadeTracerColor
        if not part or not part.Parent then
            conn:Disconnect(); GrenadeTracers[part] = nil
            for _, l in ipairs(lines) do pcall(function() l:Remove() end) end
            return
        end
        if not en then for _, l in ipairs(lines) do l.Visible = false end; return end
        table.insert(history, 1, part.Position)
        if #history > MAX_T + 1 then table.remove(history) end
        local cam = Cam
        for i = 1, MAX_T do
            local l = lines[i]
            local p1 = history[i]; local p2 = history[i+1]
            if not p1 or not p2 then l.Visible = false; continue end
            local s1,o1 = cam:WorldToViewportPoint(p1)
            local s2,o2 = cam:WorldToViewportPoint(p2)
            if (o1 or o2) and s1.Z > 0 and s2.Z > 0 then
                local fade = 1 - (i/MAX_T)
                l.From = Vector2.new(s1.X, s1.Y)
                l.To = Vector2.new(s2.X, s2.Y)
                l.Color = col
                l.Thickness = math.max(2*fade, 0.5)
                l.Transparency = 1 - fade
                l.Visible = true
            else l.Visible = false end
        end
    end)
end

local TrackedGrenades = {}
local GREN_PAT = {"grenade","flash","molotov","bang","frag","he_","_he","throwable","projectile","nade","incendiary","decoy","c4"}
local GREN_BL = {"gun","rifle","pistol","bullet","casing","debris","light","muzzle","launch","effect","arm","leg","torso","head","humanoid","mesh","handle","constraint","weld","motor","zone","voxel"}
local function isGrenade(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    local n = obj.Name:lower()
    for _, p in ipairs(GREN_BL) do if n:find(p) then return false end end
    for _, p in ipairs(GREN_PAT) do if n:find(p) then return true end end
    return false
end
local function TryTrackGrenade(obj)
    if TrackedGrenades[obj] then return end
    local part = obj
    if obj:IsA("Model") then
        part = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
    end
    if not part or not part:IsA("BasePart") then return end
    if part.Size.Magnitude > 8 then return end
    if Players:GetPlayerFromCharacter(obj) then return end
    if Players:GetPlayerFromCharacter(obj.Parent) then return end
    TrackedGrenades[obj] = true
    obj.AncestryChanged:Connect(function(_, p) if p == nil then TrackedGrenades[obj] = nil end end)
    StartGrenadeTracer(part)
end
task.spawn(function()
    task.wait(0.5)
    for _, child in ipairs(workspace:GetChildren()) do
        if isGrenade(child) then TryTrackGrenade(child) end
        for _, sub in ipairs(child:GetChildren()) do
            if isGrenade(sub) then TryTrackGrenade(sub) end
        end
    end
    workspace.ChildAdded:Connect(function(child)
        task.wait()
        if isGrenade(child) then TryTrackGrenade(child) end
        child.ChildAdded:Connect(function(sub)
            task.wait()
            if isGrenade(sub) then TryTrackGrenade(sub) end
        end)
    end)
end)

-- --- Zone ESP (Smoke / Molotov) ---
if _G.DC_ZoneLoaded then
    warn("[ZoneESP] Already running")
else
    _G.DC_ZoneLoaded = true
    local SETTINGS = {
        Smoke = {RadiusTrim=0.0, HeightOffset=0.3, Segments=40, Thickness=0.28},
        Molotov = {RadiusTrim=4.5, HeightOffset=0.3, Segments=40, Thickness=0.28},
    }
    local FADE_IN, FADE_OUT, RECALC, RAY = 0.4, 0.6, 0.05, 14
    local ActiveZones = {}
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude

    local function ComputeBounds(parent)
        local sx, sz, minY, count = 0, 0, math.huge, 0
        local parts = {}
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("BasePart") then
                count = count+1; sx=sx+v.Position.X; sz=sz+v.Position.Z
                local b = v.Position.Y - v.Size.Y*0.5
                if b < minY then minY = b end
                table.insert(parts, v)
            end
        end
        if count == 0 then return nil, nil, false end
        local cx, cz = sx/count, sz/count
        local maxR = 0
        for _, p in ipairs(parts) do
            local dx=p.Position.X-cx; local dz=p.Position.Z-cz
            local ext = math.max(p.Size.X, p.Size.Z)*0.5
            local r = math.sqrt(dx*dx+dz*dz)+ext
            if r > maxR then maxR = r end
        end
        return Vector3.new(cx,minY,cz), math.max(maxR,1.2), true
    end
    local function GroundY(x, baseY, z, ex)
        RayParams.FilterDescendantsInstances = ex or {}
        local r = workspace:Raycast(Vector3.new(x,baseY+5,z), Vector3.new(0,-RAY,0), RayParams)
        return r and r.Position.Y or baseY
    end
    local function MakeCyl(col, thick)
        local p = Instance.new("Part")
        p.Name="BS_RingSeg"; p.Anchored=true; p.CanCollide=false; p.CanQuery=false
        p.CastShadow=false; p.Material=Enum.Material.Neon; p.Color=col
        p.Transparency=1; p.Shape=Enum.PartType.Cylinder
        p.Size=Vector3.new(thick,thick,thick); p.Parent=workspace
        return p
    end
    local function CreateZone(parent, cfg, isMolotov)
        if ActiveZones[parent] then return end
        local segs = cfg.Segments; local thick = cfg.Thickness
        local initCol = isMolotov and Cfg.GrenadeZoneColor or Cfg.SmokeZoneColor
        local cyls, allP = {}, {}
        for i = 1, segs do
            local c = MakeCyl(initCol, thick)
            table.insert(cyls, c); table.insert(allP, c)
        end
        local rec = {cyls=cyls, allParts=allP, cfg=cfg, isMolotov=isMolotov,
                     lastRecalc=0, lastRadius=1, alive=true, fadingOut=false, fadeAlpha=0}
        ActiveZones[parent] = rec
        local fadeIn = tick()
        local function CurAlpha()
            if rec.fadingOut then return rec.fadeAlpha end
            return math.clamp((tick()-fadeIn)/FADE_IN, 0, 1)
        end
        local function FadeOut()
            if rec.fadingOut then return end
            rec.fadingOut = true; rec.fadeAlpha = CurAlpha()
            local t0, a0 = tick(), rec.fadeAlpha
            local c
            c = RunService.Heartbeat:Connect(function()
                local t = math.clamp((tick()-t0)/FADE_OUT, 0, 1)
                rec.fadeAlpha = a0*(1-t)
                local tr = 1-rec.fadeAlpha
                for _, cy in ipairs(cyls) do pcall(function() cy.Transparency = tr end) end
                if t >= 1 then
                    c:Disconnect(); rec.alive = false
                    for _, cy in ipairs(cyls) do pcall(function() cy:Destroy() end) end
                    ActiveZones[parent] = nil
                end
            end)
        end
        parent.AncestryChanged:Connect(function(_, np) if np == nil then FadeOut() end end)
        local uc
        uc = RunService.Heartbeat:Connect(function()
            if not rec.alive then uc:Disconnect(); return end
            if not parent or not parent.Parent then uc:Disconnect(); FadeOut(); return end
            local now = tick()
            if now - rec.lastRecalc < RECALC then return end
            rec.lastRecalc = now
            local c, r, f = ComputeBounds(parent)
            if not f then return end
            local trim = cfg.RadiusTrim or 0
            local sm = rec.lastRadius + (r - rec.lastRadius)*0.25
            rec.lastRadius = sm
            local finalR = math.max(sm-trim, 0.8)
            local alpha = CurAlpha()
            local tr = 1-alpha
            local col = rec.isMolotov and Cfg.GrenadeZoneColor or Cfg.SmokeZoneColor
            for i, cy in ipairs(cyls) do
                local aA = (2*math.pi)*((i-1)/segs)
                local aB = (2*math.pi)*(i/segs)
                local aM = (aA+aB)/2
                local xA = c.X + math.cos(aA)*finalR
                local zA = c.Z + math.sin(aA)*finalR
                local xB = c.X + math.cos(aB)*finalR
                local zB = c.Z + math.sin(aB)*finalR
                local xM = c.X + math.cos(aM)*finalR
                local zM = c.Z + math.sin(aM)*finalR
                local yA = GroundY(xA, c.Y, zA, allP) + cfg.HeightOffset
                local yB = GroundY(xB, c.Y, zB, allP) + cfg.HeightOffset
                local yM = (yA+yB)*0.5
                local pA = Vector3.new(xA,yA,zA)
                local pB = Vector3.new(xB,yB,zB)
                local mid = Vector3.new(xM,yM,zM)
                local dir = pB - pA
                local len = dir.Magnitude
                if len < 0.001 then continue end
                local cf = CFrame.lookAt(mid, mid+dir) * CFrame.Angles(0, math.rad(90), 0)
                cy.CFrame = cf
                cy.Size = Vector3.new(len, thick, thick)
                cy.Color = col
                cy.Transparency = tr
            end
        end)
        rec.updateConn = uc
    end
    local Scanned = {}
    local function TryZone(obj)
        if not obj or not obj.Parent then return end
        if Scanned[obj] then return end
        local n = obj.Name:lower()
        local isMol = n:find("firezone") or n:find("fire_zone") or n:find("molotov") or
                      n:find("voxelfire") or n:find("ignite") or n:find("flamezone") or
                      n:find("firearea") or n:find("burnzone")
        local isSm = n:find("smokezone") or n:find("smoke_zone") or n:find("voxelsmoke") or
                     n:find("smokearea") or n:find("gaszone")
        if isMol and Cfg.MolotovZoneESP then
            Scanned[obj] = true; CreateZone(obj, SETTINGS.Molotov, true)
            obj.AncestryChanged:Connect(function(_, p) if p == nil then Scanned[obj] = nil end end)
        elseif isSm and Cfg.SmokeZoneESP then
            Scanned[obj] = true; CreateZone(obj, SETTINGS.Smoke, false)
            obj.AncestryChanged:Connect(function(_, p) if p == nil then Scanned[obj] = nil end end)
        end
    end
    local function ScanFolder(f)
        if not f then return end
        for _, ch in ipairs(f:GetChildren()) do
            TryZone(ch)
            for _, sub in ipairs(ch:GetChildren()) do TryZone(sub) end
        end
        f.ChildAdded:Connect(function(ch)
            task.wait(); TryZone(ch)
            ch.ChildAdded:Connect(function(sub) task.wait(); TryZone(sub) end)
        end)
    end
    task.spawn(function()
        task.wait(1)
        ScanFolder(workspace)
        for _, n in ipairs({"Debris","Effects","FX"}) do
            local f = workspace:FindFirstChild(n)
            if f then ScanFolder(f) end
        end
        workspace.ChildAdded:Connect(function(ch)
            local n = ch.Name:lower()
            if n == "debris" or n == "effects" or n == "fx" then ScanFolder(ch) end
            task.wait(); TryZone(ch)
            ch.ChildAdded:Connect(function(sub) task.wait(); TryZone(sub) end)
        end)
        while task.wait(3) do
            for _, ch in ipairs(workspace:GetChildren()) do
                TryZone(ch)
                for _, sub in ipairs(ch:GetChildren()) do TryZone(sub) end
            end
        end
    end)
end

-- =========================================================================
-- [ CAMERA — FOV / THIRD PERSON / SCOPE / CUSTOM HANDS ]
-- =========================================================================
RunService.RenderStepped:Connect(function()
    pcall(function()
        if Cfg.CustomFovToggle and Cam then Cam.FieldOfView = Cfg.FovAmount end
        if Cfg.ThirdPerson then
            local dd = math.clamp(Cfg.ThirdPersonDist, 5, 50)
            LP.CameraMode = Enum.CameraMode.Classic
            LP.CameraMaxZoomDistance = dd
            LP.CameraMinZoomDistance = dd
        end
    end)
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not Cfg.CustomHandsEnabled then return end
        for _, ch in ipairs(Cam:GetChildren()) do
            if ch:IsA("Model") then
                local sf = ch:FindFirstChild("Stats")
                if sf then
                    local d = sf:FindFirstChild("Default")
                    if d and d:IsA("Vector3Value") then
                        d.Value = Vector3.new(Cfg.HandsX, Cfg.HandsY, Cfg.HandsZ)
                    end
                end
            end
        end
    end)
end)

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
            local en = Cfg.CustomScopeCrosshair and isScoped
            cont.Visible = en
            if en then
                local c = Cfg.ScopeCrosshairColor
                lL.BackgroundColor3=c; rL.BackgroundColor3=c; tL.BackgroundColor3=c; bL.BackgroundColor3=c
                local t = Cfg.ScopeCrosshairThickness
                lL.Size=UDim2.new(0,Cfg.ScopeCrosshairLengthLR,0,t); lL.Position=UDim2.new(0,0,0,0)
                rL.Size=UDim2.new(0,Cfg.ScopeCrosshairLengthLR,0,t); rL.Position=UDim2.new(0,0,0,0)
                tL.Size=UDim2.new(0,t,0,Cfg.ScopeCrosshairLengthTB); tL.Position=UDim2.new(0,0,0,0)
                bL.Size=UDim2.new(0,t,0,Cfg.ScopeCrosshairLengthTB); bL.Position=UDim2.new(0,0,0,0)
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
        if not Cfg.RemoveScope then
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
            if Cfg.CustomScopeFov and Cam then
                local pg = LP:FindFirstChild("PlayerGui")
                if pg then
                    local sc = pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("Gameplay") and pg.MainGui.Gameplay:FindFirstChild("Middle") and pg.MainGui.Gameplay.Middle:FindFirstChild("SniperScope")
                    if sc and sc.Visible then Cam.FieldOfView = Cfg.ScopeFovValue end
                end
            end
        end)
    end)
end)

-- =========================================================================
-- [ WORLD — SKYBOX / WEATHER / LIGHTING / ATMOSPHERE / NIGHT MODE ]
-- =========================================================================
local SkyboxTable = {
    Night={Bk="rbxassetid://1514717643",Dn="rbxassetid://1514716936",Ft="rbxassetid://1514715910",Lf="rbxassetid://1514714945",Rt="rbxassetid://1514714011",Up="rbxassetid://1514713374"},
    ["Ocean Sunset"]={Bk="rbxassetid://17525686840",Dn="rbxassetid://17525678473",Ft="rbxassetid://17525684686",Lf="rbxassetid://17525680663",Rt="rbxassetid://17525682665",Up="rbxassetid://17525674545"},
    Standard={Bk="http://www.roblox.com/asset/?id=91458024",Dn="http://www.roblox.com/asset/?id=91457980",Ft="http://www.roblox.com/asset/?id=91458024",Lf="http://www.roblox.com/asset/?id=91458024",Rt="http://www.roblox.com/asset/?id=91458024",Up="http://www.roblox.com/asset/?id=91458002"},
    Minecraft={Bk="http://www.roblox.com/asset/?id=8735166756",Dn="http://www.roblox.com/asset/?id=8735166707",Ft="http://www.roblox.com/asset/?id=8735231668",Lf="http://www.roblox.com/asset/?id=8735166755",Rt="http://www.roblox.com/asset/?id=8735166751",Up="http://www.roblox.com/asset/?id=8735166729"},
    ["Deep Space"]={Bk="http://www.roblox.com/asset/?id=159248188",Dn="http://www.roblox.com/asset/?id=159248183",Ft="http://www.roblox.com/asset/?id=159248187",Lf="http://www.roblox.com/asset/?id=159248173",Rt="http://www.roblox.com/asset/?id=159248192",Up="http://www.roblox.com/asset/?id=159248176"},
    Retro={Bk="rbxasset://sky/null_plainsky512_bk.jpg",Dn="rbxasset://sky/null_plainsky512_dn.jpg",Ft="rbxasset://sky/null_plainsky512_ft.jpg",Lf="rbxasset://sky/null_plainsky512_lf.jpg",Rt="rbxasset://sky/null_plainsky512_rt.jpg",Up="rbxasset://sky/null_plainsky512_up.jpg"},
    City={Bk="http://www.roblox.com/asset/?id=9134792889",Dn="http://www.roblox.com/asset/?id=9134791975",Ft="http://www.roblox.com/asset/?id=9134793457",Lf="http://www.roblox.com/asset/?id=9134791234",Rt="http://www.roblox.com/asset/?id=9134790419",Up="http://www.roblox.com/asset/?id=9134791633"},
}
local function UpdateSkybox(name)
    local d = SkyboxTable[name]
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

local WeatherPart
local function UpdateWeather(t)
    if WeatherPart then WeatherPart:Destroy(); WeatherPart = nil end
    if t == "None" then return end
    WeatherPart = Instance.new("Part")
    WeatherPart.Name="DC_Weather"; WeatherPart.Size=Vector3.new(100,1,100)
    WeatherPart.Transparency=1; WeatherPart.Anchored=true; WeatherPart.CanCollide=false
    WeatherPart.Parent = Cam
    local se = Instance.new("ParticleEmitter", WeatherPart)
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
    if WeatherPart and Cam then
        WeatherPart.CFrame = Cam.CFrame * CFrame.new(0,30,0)
    end
end)

local DefaultLighting = {
    Ambient=PH_Lighting.Ambient, OutdoorAmbient=PH_Lighting.OutdoorAmbient,
    Brightness=PH_Lighting.Brightness, ClockTime=PH_Lighting.ClockTime,
}
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Cfg.EnableTime then PH_Lighting.ClockTime = Cfg.WorldClockTime
            else PH_Lighting.ClockTime = DefaultLighting.ClockTime end
            if Cfg.EnableBrightness then PH_Lighting.Brightness = Cfg.WorldBrightness
            else PH_Lighting.Brightness = DefaultLighting.Brightness end
            if Cfg.EnableColors then
                PH_Lighting.Ambient = Cfg.WorldAmbient
                PH_Lighting.OutdoorAmbient = Cfg.WorldOutdoorAmbient
            else
                PH_Lighting.Ambient = DefaultLighting.Ambient
                PH_Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
            end
            if Cfg.EnableSkybox then UpdateSkybox(Cfg.SkyboxPreset) end
            if Cfg.Atmosphere then
                local atm = PH_Lighting:FindFirstChildOfClass("Atmosphere")
                if not atm then atm = Instance.new("Atmosphere", PH_Lighting) end
                atm.Density = Cfg.AtmosphereDensity
                atm.Haze = Cfg.SubAtmosphereHaze
                atm.Glare = Cfg.AtmosphereGlare
            else
                local atm = PH_Lighting:FindFirstChildOfClass("Atmosphere")
                if atm then atm:Destroy() end
            end
            if Cfg.EnableColorCorrection then
                local cc = PH_Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if not cc then cc = Instance.new("ColorCorrectionEffect", PH_Lighting) end
                cc.Enabled = true
                cc.Saturation = Cfg.SaturationSlider
                cc.Contrast = Cfg.ContrastSlider
            else
                local cc = PH_Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
                if cc then cc.Enabled = false end
            end
        end)
    end
end)

-- Night Mode / World Color
local WorldSettings = {WorldColorEnabled=false, WorldColor=Color3.fromRGB(255,255,255),
                       SkyColorEnabled=false, SkyColor=Color3.fromRGB(255,255,255)}
local function IsLocalObject(obj)
    local char = LP.Character
    if char and (obj == char or obj:IsDescendantOf(char)) then return true end
    if obj:IsDescendantOf(Cam) then return true end
    if obj.Name:find("DC_") or obj.Name == "BS_RingSeg" then return true end
    return false
end
local function ColorObj(obj)
    if IsLocalObject(obj) then return end
    if obj:IsA("BasePart") then
        if not obj:GetAttribute("OrigColor") then obj:SetAttribute("OrigColor", obj.Color) end
        obj.Color = WorldSettings.WorldColor
    elseif obj:IsA("Texture") or obj:IsA("Decal") then
        if not obj:GetAttribute("OrigColor3") then obj:SetAttribute("OrigColor3", obj.Color3) end
        obj.Color3 = WorldSettings.WorldColor
    end
end
local function RestoreObj(obj)
    if obj:IsA("BasePart") then
        if obj:GetAttribute("OrigColor") then obj.Color = obj:GetAttribute("OrigColor") end
    elseif obj:IsA("Texture") or obj:IsA("Decal") then
        if obj:GetAttribute("OrigColor3") then obj.Color3 = obj:GetAttribute("OrigColor3") end
    end
end
local function RefreshWorld()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if WorldSettings.WorldColorEnabled then ColorObj(obj) else RestoreObj(obj) end
    end
end
workspace.DescendantAdded:Connect(function(obj)
    if WorldSettings.WorldColorEnabled then
        task.defer(function() if obj and obj.Parent then ColorObj(obj) end end)
    end
end)
RunService.RenderStepped:Connect(function()
    if WorldSettings.SkyColorEnabled then
        local c = WorldSettings.SkyColor
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

-- =========================================================================
-- [ MISC — AUTO BHOP / NO FALL DAMAGE ]
-- =========================================================================
local function GetMoveDir()
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
        if Cfg.AutoBhop then
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = {char}
                rp.FilterType = Enum.RaycastFilterType.Exclude
                if workspace:Raycast(root.Position, Vector3.new(0,-4,0), rp) then hum.Jump = true end
            end
            local dir = GetMoveDir()
            if dir.Magnitude > 0 then
                local spd = math.clamp(Cfg.BhopSpeed, 5, 30)
                local d = dir * spd
                local v = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(v.X+(d.X-v.X)*0.2, v.Y, v.Z+(d.Z-v.Z)*0.2)
            end
        end
    end)
end)
RunService.Heartbeat:Connect(function()
    pcall(function()
        if Cfg.NoFallDamage then
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

-- ====== [ОБРЫВ 3] ======
-- =========================================================================
-- [ GUI — 9 ВКЛАДОК ]
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

    local function toggle(parent, txt, key, cb)
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
        tg.BackgroundColor3 = Cfg[key] and Cfg.GuiColor or Color3.fromRGB(55, 55, 68)
        tg.BorderSizePixel = 0; tg.Parent = row
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = Cfg[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.Parent = tg
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob
        row.MouseButton1Click:Connect(function()
            Cfg[key] = not Cfg[key]
            Tween:Create(tg, TweenInfo.new(0.15), {
                BackgroundColor3 = Cfg[key] and Cfg.GuiColor or Color3.fromRGB(55, 55, 68)
            }):Play()
            Tween:Create(knob, TweenInfo.new(0.15), {
                Position = Cfg[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }):Play()
            if cb then cb(Cfg[key]) end
        end)
    end

    local function slider(parent, txt, key, mn, mx, step)
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
        val.BackgroundTransparency = 1; val.Text = tostring(Cfg[key])
        val.TextColor3 = Cfg.GuiColor; val.Font = Enum.Font.GothamBold
        val.TextSize = 11; val.TextXAlignment = Enum.TextXAlignment.Right; val.Parent = row
        reg(val, "textAccent")
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 5); bar.Position = UDim2.new(0, 12, 0, 28)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 62); bar.BorderSizePixel = 0; bar.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((Cfg[key] - mn) / (mx - mn), 0, 1, 0)
        fill.BackgroundColor3 = Cfg.GuiColor; fill.BorderSizePixel = 0; fill.Parent = bar
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill
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

    local function optionRow(parent, txt, key, opts, cb)
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
                if Cfg[key] == b.Val then
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
                Cfg[key] = v; refresh()
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

    -- ========== ESP ==========
    local espTab = makeTab("ESP")
    section(espTab, "ESP")
    toggle(espTab, "ESP Enabled", "ESPEnabled")
    toggle(espTab, "Team Check", "ESPTeamCheck")
    section(espTab, "Box")
    optionRow(espTab, "Box Type", "ESPBoxType", {"2D Box", "3D Box", "Corner Box", "Disabled"})
    toggle(espTab, "Fill Gradient", "ESPBoxFillGradient")
    toggle(espTab, "Fill Rotation", "ESPBoxFillRotation")
    slider(espTab, "Rotation Speed", "ESPBoxRotationSpeed", 0.1, 10, 0.5)
    colorRow(espTab, "Box Color A", function(c) Cfg.ESPBoxColorA = c end)
    colorRow(espTab, "Box Color B", function(c) Cfg.ESPBoxColorB = c end)
    colorRow(espTab, "Fill Color A", function(c) Cfg.ESPFillColorA = c end)
    colorRow(espTab, "Fill Color B", function(c) Cfg.ESPFillColorB = c end)
    section(espTab, "Инфо")
    toggle(espTab, "Name", "ESPName")
    toggle(espTab, "Health Bar", "ESPHealth")
    toggle(espTab, "Health Text", "ESPHealthText")
    toggle(espTab, "Distance", "ESPDistance")
    toggle(espTab, "Weapon", "ESPWeapon")
    toggle(espTab, "Tracer", "ESPTracer")
    toggle(espTab, "Skeleton", "ESPSkeleton")
    toggle(espTab, "Circular Target", "ESPCircularTarget")
    section(espTab, "Цвета")
    colorRow(espTab, "Name Color", function(c) Cfg.ESPNameColor = c end)
    colorRow(espTab, "Health Top", function(c) Cfg.ESPHealthTopColor = c end)
    colorRow(espTab, "Health Bottom", function(c) Cfg.ESPHealthBottomColor = c end)
    colorRow(espTab, "Tracer A", function(c) Cfg.ESPTracerColor = c end)
    colorRow(espTab, "Tracer B", function(c) Cfg.ESPTracerColorB = c end)
    colorRow(espTab, "Skeleton A", function(c) Cfg.ESPSkeletonColorA = c end)
    colorRow(espTab, "Skeleton B", function(c) Cfg.ESPSkeletonColorB = c end)
    colorRow(espTab, "Circular Target", function(c) Cfg.ESPCircularTargetColor = c end)

    -- ========== AIM ==========
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

    -- ========== EFFECTS ==========
    local effTab = makeTab("EFFECTS")
    section(effTab, "Визуальные")
    toggle(effTab, "Anti-Flashbang", "Antiflashbang")
    toggle(effTab, "Anti-Smoke", "Antismoke")

    -- ========== SKINS ==========
    local skinsTab = makeTab("SKINS")
    section(skinsTab, "Skin Changer")
    toggle(skinsTab, "Включить скины", "SkinChangerEnabled")
    section(skinsTab, "Нож")
    toggle(skinsTab, "Включить нож", "KnifeChangerEnabled")
    optionRow(skinsTab, "Модель ножа", "KnifeChangerModel", {"Karambit", "Butterfly Knife", "Flip Knife", "Gut Knife", "M9 Bayonet", "Skeleton Knife", "Stiletto Knife"})
    section(skinsTab, "Перчатки")
    toggle(skinsTab, "Включить перчатки", "GloveChangerEnabled")
    local GM = {}
    for k in pairs(SD.GloveSelections) do GM[#GM + 1] = k end
    table.sort(GM)
    if #GM > 0 then optionRow(skinsTab, "Модель перчаток", "GloveChangerModel", GM) end

    -- ========== VISUALS ==========
    local visualTab = makeTab("VISUALS")
    section(visualTab, "Тема")
    colorRow(visualTab, "Цвет меню", function(c)
        Cfg.GuiColor = c
        task.spawn(applyTheme)
        stripe.BackgroundColor3 = c
        fovStroke.Color = c
    end)

    -- ========== TRACERS ==========
    local trTab = makeTab("TRACERS")
    section(trTab, "Bullet Tracers")
    toggle(trTab, "Включить трассеры", "BulletTracers")
    toggle(trTab, "Rainbow режим", "TracerRainbow")
    optionRow(trTab, "Стиль", "TracerStyle", {"Block", "Cylinder (Obelius)"})
    slider(trTab, "Время жизни", "TracerTime", 0.1, 10, 0.5)
    colorRow(trTab, "Цвет трассера", function(c) Cfg.TracerColor = c end)
    section(trTab, "Bullet Impacts")
    toggle(trTab, "Показывать попадания", "BulletImpacts")
    colorRow(trTab, "Цвет попадания", function(c) Cfg.BulletImpactsColor = c end)
    section(trTab, "Grenade Tracers")
    toggle(trTab, "Трассеры гранат", "GrenadeTracers")
    colorRow(trTab, "Цвет гранаты", function(c) Cfg.GrenadeTracerColor = c end)
    section(trTab, "Grenade Zone ESP")
    toggle(trTab, "Smoke Zone", "SmokeZoneESP")
    colorRow(trTab, "Цвет дыма", function(c) Cfg.SmokeZoneColor = c end)
    toggle(trTab, "Molotov Zone", "MolotovZoneESP")
    colorRow(trTab, "Цвет огня", function(c) Cfg.GrenadeZoneColor = c end)
    section(trTab, "Wallbang")
    toggle(trTab, "Показывать WALLBANG", "ShowPenetration")

    -- ========== CAMERA ==========
    local camTab = makeTab("CAMERA")
    section(camTab, "FOV")
    toggle(camTab, "Свой FOV", "CustomFovToggle")
    slider(camTab, "FOV", "FovAmount", 70, 120, 1)
    section(camTab, "Third Person")
    toggle(camTab, "Вид от 3-го лица", "ThirdPerson")
    slider(camTab, "Дистанция", "ThirdPersonDist", 5, 50, 1)
    section(camTab, "Scope")
    toggle(camTab, "Свой FOV прицела", "CustomScopeFov")
    slider(camTab, "FOV прицела", "ScopeFovValue", 10, 100, 1)
    toggle(camTab, "Убрать прицел", "RemoveScope")
    toggle(camTab, "Свой крестик", "CustomScopeCrosshair")
    slider(camTab, "Толщина крестика", "ScopeCrosshairThickness", 1, 10, 1)
    slider(camTab, "Длина LR", "ScopeCrosshairLengthLR", 0, 1000, 10)
    slider(camTab, "Длина TB", "ScopeCrosshairLengthTB", 0, 1000, 10)
    colorRow(camTab, "Цвет крестика", function(c) Cfg.ScopeCrosshairColor = c end)
    section(camTab, "Custom Hands")
    toggle(camTab, "Смещение рук", "CustomHandsEnabled")
    slider(camTab, "X", "HandsX", -2, 2, 0.01)
    slider(camTab, "Y", "HandsY", -2, 2, 0.01)
    slider(camTab, "Z", "HandsZ", -2, 2, 0.01)

    -- ========== WORLD ==========
    local wTab = makeTab("WORLD")
    section(wTab, "Skybox")
    toggle(wTab, "Включить Skybox", "EnableSkybox")
    optionRow(wTab, "Пресет", "SkyboxPreset", {"Night", "Ocean Sunset", "Standard", "Minecraft", "Deep Space", "Retro", "City"})
    section(wTab, "Weather")
    optionRow(wTab, "Погода", "WeatherType", {"None", "Rain", "Snow"}, function(v) UpdateWeather(v) end)
    section(wTab, "Lighting")
    toggle(wTab, "Время", "EnableTime")
    slider(wTab, "Час", "WorldClockTime", 0, 24, 1)
    toggle(wTab, "Яркость", "EnableBrightness")
    slider(wTab, "Яркость", "WorldBrightness", 0, 10, 0.5)
    toggle(wTab, "Цвета", "EnableColors")
    colorRow(wTab, "Ambient", function(c) Cfg.WorldAmbient = c end)
    colorRow(wTab, "Outdoor", function(c) Cfg.WorldOutdoorAmbient = c end)
    section(wTab, "Atmosphere")
    toggle(wTab, "Атмосфера", "Atmosphere")
    slider(wTab, "Плотность", "AtmosphereDensity", 0, 1, 0.05)
    slider(wTab, "Haze", "SubAtmosphereHaze", 0, 10, 0.5)
    slider(wTab, "Glare", "AtmosphereGlare", 0, 10, 0.5)
    toggle(wTab, "Color Correction", "EnableColorCorrection")
    slider(wTab, "Saturation", "SaturationSlider", -1, 1, 0.1)
    slider(wTab, "Contrast", "ContrastSlider", -1, 1, 0.1)
    section(wTab, "Night Mode")
    toggle(wTab, "World Color", "WorldColorToggle", function(v)
        WorldSettings.WorldColorEnabled = v
        RefreshWorld()
    end)
    colorRow(wTab, "World Color", function(c)
        Cfg.WorldColorPicker = c
        WorldSettings.WorldColor = c
        if WorldSettings.WorldColorEnabled then RefreshWorld() end
    end)
    toggle(wTab, "Second Color", "SkyColorToggle", function(v)
        WorldSettings.SkyColorEnabled = v
    end)
    colorRow(wTab, "Second Color", function(c)
        Cfg.SkyColorPicker = c
        WorldSettings.SkyColor = c
    end)

    -- ========== MISC ==========
    local miscTab = makeTab("MISC")
    section(miscTab, "Движение")
    toggle(miscTab, "Auto Bhop", "AutoBhop")
    slider(miscTab, "Bhop Speed", "BhopSpeed", 5, 30, 1)
    toggle(miscTab, "No Fall Damage", "NoFallDamage")
    section(miscTab, "Инфо")
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, 0, 0, 70); infoLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Danny's Cheats v2\nESP(PasteHub) + Aim + Skins + Tracers + Camera + World\nLeft Alt — открыть/закрыть"
    infoLbl.TextColor3 = Color3.fromRGB(180, 180, 200); infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 10; infoLbl.TextWrapped = true; infoLbl.Parent = miscTab
    local infoC = Instance.new("UICorner"); infoC.CornerRadius = UDim.new(0, 6); infoC.Parent = infoLbl
    reg(infoLbl, "bgInput")

    -- ========== СВОРАЧИВАНИЕ ==========
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
        for instance, data in pairs(espinstances) do
            pcall(function() cleanup_instance(instance, data) end)
        end
        pcall(function() gui:Destroy() end)
    end
end

buildGUI()

print("[Danny's Cheats v2] ESP: OK")
print("[Danny's Cheats v2] Aim: " .. (Aim.Ready and "OK" or "FAIL"))
print("[Danny's Cheats v2] Skins: " .. (SD.SkinsRoot and ("OK (" .. #SD.SkinsRoot:GetChildren() .. " категорий)") or "Skins не найдены"))
print("[Danny's Cheats v2] Loaded successfully")

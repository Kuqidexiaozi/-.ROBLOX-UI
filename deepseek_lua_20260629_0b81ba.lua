-- ==================== 加载 WindUI ====================
local WindUI
do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)
    if ok then
        WindUI = result
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end

-- ==================== 创建窗口 ====================
local Window = WindUI:CreateWindow({
    Title = "Matcha ESP | WindUI",
    Folder = "matcha_esp",
    Icon = "solar:eye-bold",
    OpenButton = {
        Title = "☕ Matcha ESP",
        Enabled = true,
        Draggable = true,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"),
            Color3.fromHex("#e7ff2f")
        ),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

-- ==================== Matcha ESP 完整库 ====================
local MatchaEsp = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Esp = {}

Esp.State = {
    BoxEnabled = false,
    NameEnabled = false,
    DistanceEnabled = false,
    TracerEnabled = false,
    SkeletonEnabled = false,
    HealthBarEnabled = false,
    HealthTextEnabled = false,
    ChamsEnabled = false,
    RingEnabled = false,
}

Esp.Config = {
    BoxColor = Color3.fromRGB(103, 89, 179),
    BoxFillTransparency = 0.5,
    BoxOutlineEnabled = true,
    BoxOutlineColor = Color3.new(0, 0, 0),
    BoxGradientEnabled = false,
    BoxGradientColor1 = Color3.fromRGB(103, 89, 179),
    BoxGradientColor2 = Color3.fromRGB(204, 102, 255),
    
    TracerColor = Color3.fromRGB(103, 89, 179),
    TracerOrigin = "Bottom Screen",
    
    SkeletonColor = Color3.fromRGB(103, 89, 179),
    
    HealthBarLerpSpeed = 0.15,
    
    ChamsColor = Color3.fromRGB(103, 89, 179),
    ChamsOutlineColor = Color3.new(1, 1, 1),
    ChamsFillTransparency = 0.5,
    
    RingColor = Color3.new(1, 1, 1),
    
    MaxDistance = 1000,
}

Esp.Caches = {
    BoxCache = {},
    TracerCache = {},
    SkeletonCache = {},
    HealthCache = {},
    NameCache = {},
    DistanceCache = {},
}

local function IsValid(player)
    if not player or player == LocalPlayer then return false end
    if not player.Character then return false end
    if not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return false end
    return true
end

local function WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function GetColorFromHealth(health, maxHealth)
    local ratio = health / maxHealth
    if ratio > 0.5 then
        return Color3.new(0, 1, 2 * (1 - ratio))
    else
        return Color3.new(1, 2 * ratio, 0)
    end
end

-- ==================== Box ESP ====================
function Esp:InitiateBox()
    self.State.BoxEnabled = true
end

function Esp:UpdateBoxes()
    if not self.State.BoxEnabled then
        for _, box in pairs(self.Caches.BoxCache) do
            box.Box.Visible = false
        end
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then
            if self.Caches.BoxCache[player] then
                self.Caches.BoxCache[player].Box.Visible = false
            end
            continue
        end
        
        local root = player.Character.HumanoidRootPart
        local head = player.Character:FindFirstChild("Head") or root
        local rootPos, rootOn = WorldToScreen(root.Position)
        local headPos, headOn = WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
        
        if not rootOn or not headOn then
            if self.Caches.BoxCache[player] then
                self.Caches.BoxCache[player].Box.Visible = false
            end
            continue
        end
        
        local height = math.abs(rootPos.Y - headPos.Y)
        local width = height * 0.5
        
        if not self.Caches.BoxCache[player] then
            local box = Drawing.new("Square")
            box.Thickness = 1
            box.Filled = false
            box.Visible = true
            
            self.Caches.BoxCache[player] = {
                Box = box,
                LastHealth = 100,
            }
        end
        
        local data = self.Caches.BoxCache[player]
        data.Box.Size = Vector2.new(width, height)
        data.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
        data.Box.Color = self.Config.BoxColor
        data.Box.Visible = true
        data.Box.Filled = false
        data.Box.Thickness = 1
    end
end

-- ==================== Name ESP ====================
function Esp:InitiateName(state)
    self.State.NameEnabled = state
end

function Esp:UpdateNames()
    if not self.State.NameEnabled then
        for _, name in pairs(self.Caches.NameCache) do
            name.Text.Visible = false
        end
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then
            if self.Caches.NameCache[player] then
                self.Caches.NameCache[player].Text.Visible = false
            end
            continue
        end
        
        local root = player.Character.HumanoidRootPart
        local pos, onScreen = WorldToScreen(root.Position + Vector3.new(0, 2.5, 0))
        if not onScreen then
            if self.Caches.NameCache[player] then
                self.Caches.NameCache[player].Text.Visible = false
            end
            continue
        end
        
        if not self.Caches.NameCache[player] then
            local text = Drawing.new("Text")
            text.Size = 12
            text.Outline = true
            text.Visible = true
            
            self.Caches.NameCache[player] = {
                Text = text,
            }
        end
        
        local data = self.Caches.NameCache[player]
        data.Text.Text = player.DisplayName
        data.Text.Position = Vector2.new(pos.X, pos.Y)
        data.Text.Color = self.Config.BoxColor
        data.Text.Visible = true
    end
end

-- ==================== Distance ESP ====================
function Esp:InitiateDistance(state)
    self.State.DistanceEnabled = state
end

function Esp:UpdateDistances()
    if not self.State.DistanceEnabled then
        for _, dist in pairs(self.Caches.DistanceCache) do
            dist.Text.Visible = false
        end
        return
    end
    
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then
            if self.Caches.DistanceCache[player] then
                self.Caches.DistanceCache[player].Text.Visible = false
            end
            continue
        end
        
        local root = player.Character.HumanoidRootPart
        local pos, onScreen = WorldToScreen(root.Position + Vector3.new(0, 3, 0))
        if not onScreen then
            if self.Caches.DistanceCache[player] then
                self.Caches.DistanceCache[player].Text.Visible = false
            end
            continue
        end
        
        if not self.Caches.DistanceCache[player] then
            local text = Drawing.new("Text")
            text.Size = 10
            text.Outline = true
            text.Visible = true
            
            self.Caches.DistanceCache[player] = {
                Text = text,
            }
        end
        
        local dist = (myRoot.Position - root.Position).Magnitude
        local data = self.Caches.DistanceCache[player]
        data.Text.Text = math.floor(dist) .. "m"
        data.Text.Position = Vector2.new(pos.X, pos.Y)
        data.Text.Color = Color3.new(1, 1, 1)
        data.Text.Visible = true
    end
end

-- ==================== Tracer ESP ====================
function Esp:InitiateTracer(color, origin)
    self.State.TracerEnabled = true
    self.Config.TracerColor = color
    self.Config.TracerOrigin = origin or "Bottom Screen"
end

function Esp:UpdateTracers()
    if not self.State.TracerEnabled then
        for _, tracer in pairs(self.Caches.TracerCache) do
            tracer.Line.Visible = false
        end
        return
    end
    
    local viewport = Camera.ViewportSize
    local origin = Vector2.new(viewport.X / 2, viewport.Y)
    
    if self.Config.TracerOrigin == "Cursor" then
        origin = UserInputService:GetMouseLocation()
    elseif self.Config.TracerOrigin == "Top Screen" then
        origin = Vector2.new(viewport.X / 2, 0)
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then
            if self.Caches.TracerCache[player] then
                self.Caches.TracerCache[player].Line.Visible = false
            end
            continue
        end
        
        local root = player.Character.HumanoidRootPart
        local pos, onScreen = WorldToScreen(root.Position)
        if not onScreen then
            if self.Caches.TracerCache[player] then
                self.Caches.TracerCache[player].Line.Visible = false
            end
            continue
        end
        
        if not self.Caches.TracerCache[player] then
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Visible = true
            
            self.Caches.TracerCache[player] = {
                Line = line,
            }
        end
        
        local data = self.Caches.TracerCache[player]
        data.Line.From = origin
        data.Line.To = Vector2.new(pos.X, pos.Y)
        data.Line.Color = self.Config.TracerColor
        data.Line.Visible = true
    end
end

-- ==================== Skeleton ESP ====================
function Esp:InitiateSkeleton(color)
    self.State.SkeletonEnabled = true
    self.Config.SkeletonColor = color
end

function Esp:UpdateSkeletons()
    if not self.State.SkeletonEnabled then
        for _, skel in pairs(self.Caches.SkeletonCache) do
            for _, line in pairs(skel.Lines) do
                line.Visible = false
            end
        end
        return
    end
    
    local bones = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
    }
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then
            if self.Caches.SkeletonCache[player] then
                for _, line in pairs(self.Caches.SkeletonCache[player].Lines) do
                    line.Visible = false
                end
            end
            continue
        end
        
        if not self.Caches.SkeletonCache[player] then
            local lines = {}
            for i = 1, #bones do
                local line = Drawing.new("Line")
                line.Thickness = 1
                line.Visible = true
                table.insert(lines, line)
            end
            
            self.Caches.SkeletonCache[player] = {
                Lines = lines,
            }
        end
        
        local data = self.Caches.SkeletonCache[player]
        local char = player.Character
        
        for i, bone in pairs(bones) do
            local partA = char:FindFirstChild(bone[1])
            local partB = char:FindFirstChild(bone[2])
            local line = data.Lines[i]
            
            if partA and partB then
                local posA, onA = WorldToScreen(partA.Position)
                local posB, onB = WorldToScreen(partB.Position)
                
                if onA and onB then
                    line.From = Vector2.new(posA.X, posA.Y)
                    line.To = Vector2.new(posB.X, posB.Y)
                    line.Color = self.Config.SkeletonColor
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end

-- ==================== Health Bar ====================
function Esp:InitiateHealthBar(state)
    self.State.HealthBarEnabled = state
end

function Esp:UpdateHealthBars()
    if not self.State.HealthBarEnabled then
        for _, health in pairs(self.Caches.HealthCache) do
            health.Bar.Visible = false
        end
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then
            if self.Caches.HealthCache[player] then
                self.Caches.HealthCache[player].Bar.Visible = false
            end
            continue
        end
        
        local root = player.Character.HumanoidRootPart
        local pos, onScreen = WorldToScreen(root.Position + Vector3.new(0, 2, 0))
        if not onScreen then
            if self.Caches.HealthCache[player] then
                self.Caches.HealthCache[player].Bar.Visible = false
            end
            continue
        end
        
        local humanoid = player.Character.Humanoid
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        
        if not self.Caches.HealthCache[player] then
            local bar = Drawing.new("Square")
            bar.Thickness = 1
            bar.Filled = true
            bar.Visible = true
            
            self.Caches.HealthCache[player] = {
                Bar = bar,
                LastHealth = health,
            }
        end
        
        local data = self.Caches.HealthCache[player]
        data.Bar.Size = Vector2.new(50, 4)
        data.Bar.Position = Vector2.new(pos.X - 25, pos.Y + 5)
        data.Bar.Color = GetColorFromHealth(health, maxHealth)
        data.Bar.Visible = true
        
        if self.State.HealthTextEnabled then
            if not data.Text then
                local text = Drawing.new("Text")
                text.Size = 10
                text.Outline = true
                data.Text = text
            end
            data.Text.Text = math.floor(health) .. "/" .. math.floor(maxHealth)
            data.Text.Position = Vector2.new(pos.X, pos.Y + 12)
            data.Text.Color = Color3.new(1, 1, 1)
            data.Text.Visible = true
        elseif data.Text then
            data.Text.Visible = false
        end
    end
end

-- ==================== Chams ====================
function Esp:InitiateChams(color)
    self.State.ChamsEnabled = true
    self.Config.ChamsColor = color
end

function Esp:UpdateChams()
    if not self.State.ChamsEnabled then
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then continue end
        local char = player.Character
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.Neon
                part.Color = self.Config.ChamsColor
                part.Transparency = self.Config.ChamsFillTransparency
            end
        end
    end
end

-- ==================== Ring ESP ====================
function Esp:InitiateRing(color)
    self.State.RingEnabled = true
    self.Config.RingColor = color
end

function Esp:UpdateRings()
    if not self.State.RingEnabled then
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if not IsValid(player) then continue end
        local root = player.Character.HumanoidRootPart
        
        local ring = root:FindFirstChild("MatchaRing")
        if not ring then
            ring = Instance.new("Part")
            ring.Name = "MatchaRing"
            ring.Shape = Enum.PartType.Cylinder
            ring.Size = Vector3.new(5, 0.2, 5)
            ring.Anchored = true
            ring.CanCollide = false
            ring.Material = Enum.Material.Neon
            ring.Transparency = 0.5
            ring.Parent = root
        end
        
        ring.CFrame = root.CFrame * CFrame.new(0, -2, 0)
        ring.Color = self.Config.RingColor
    end
end

-- ==================== Set Distance ====================
function Esp:SetDistance(distance)
    self.Config.MaxDistance = distance
end

-- ==================== Main Update Loop ====================
function Esp:Initialize()
    RunService.Heartbeat:Connect(function()
        self:UpdateBoxes()
        self:UpdateNames()
        self:UpdateDistances()
        self:UpdateTracers()
        self:UpdateSkeletons()
        self:UpdateHealthBars()
        self:UpdateChams()
        self:UpdateRings()
    end)
end

-- ==================== 初始化 ESP ====================
Esp:Initialize()

-- ==================== UI 选项卡 ====================
local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "solar:eye-bold",
    IconColor = Color3.fromHex("#7775F2"),
    Border = true,
})

local EspSection = ESPTab:Section({
    Title = "ESP 设置",
})

-- 一键开关
EspSection:Toggle({
    Title = "🔄 一键启用全部 ESP",
    Value = false,
    Callback = function(v)
        Esp.State.BoxEnabled = v
        Esp.State.NameEnabled = v
        Esp.State.DistanceEnabled = v
        Esp.State.TracerEnabled = v
        Esp.State.SkeletonEnabled = v
        Esp.State.HealthBarEnabled = v
        Esp.State.HealthTextEnabled = v
        Esp.State.ChamsEnabled = v
        Esp.State.RingEnabled = v
    end,
})

EspSection:Space()

-- === Box ===
EspSection:Toggle({
    Title = "📦 方框 ESP",
    Value = false,
    Callback = function(v)
        Esp.State.BoxEnabled = v
    end,
})

EspSection:Colorpicker({
    Title = "方框颜色",
    Default = Color3.fromRGB(103, 89, 179),
    Callback = function(c)
        Esp.Config.BoxColor = c
        for _, o in pairs(Esp.Caches.BoxCache) do
            o.Box.Color = c
        end
    end,
})

EspSection:Slider({
    Title = "填充透明度",
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Step = 0.05,
    Callback = function(v)
        Esp.Config.BoxFillTransparency = v
    end,
})

EspSection:Space()

-- === Name ===
EspSection:Toggle({
    Title = "🏷️ 名字 ESP",
    Value = false,
    Callback = function(v)
        Esp:InitiateName(v)
    end,
})

EspSection:Space()

-- === Distance ===
EspSection:Toggle({
    Title = "📏 距离 ESP",
    Value = false,
    Callback = function(v)
        Esp:InitiateDistance(v)
    end,
})

EspSection:Space()

-- === Tracer ===
EspSection:Toggle({
    Title = "📌 追踪线 ESP",
    Value = false,
    Callback = function(v)
        if v then
            Esp:InitiateTracer(Color3.fromRGB(103, 89, 179), "Bottom Screen")
        else
            Esp.State.TracerEnabled = false
        end
    end,
})

EspSection:Colorpicker({
    Title = "追踪线颜色",
    Default = Color3.fromRGB(103, 89, 179),
    Callback = function(c)
        Esp.Config.TracerColor = c
    end,
})

EspSection:Dropdown({
    Title = "追踪线起点",
    Values = { "Bottom Screen", "Cursor", "Top Screen" },
    Value = "Bottom Screen",
    Callback = function(v)
        Esp.Config.TracerOrigin = v
    end,
})

EspSection:Space()

-- === Skeleton ===
EspSection:Toggle({
    Title = "🦴 骨骼 ESP",
    Value = false,
    Callback = function(v)
        if v then
            Esp:InitiateSkeleton(Color3.fromRGB(103, 89, 179))
        else
            Esp.State.SkeletonEnabled = false
        end
    end,
})

EspSection:Colorpicker({
    Title = "骨骼颜色",
    Default = Color3.fromRGB(103, 89, 179),
    Callback = function(c)
        Esp.Config.SkeletonColor = c
    end,
})

EspSection:Space()

-- === Health Bar ===
EspSection:Toggle({
    Title = "❤️ 血量条",
    Value = false,
    Callback = function(v)
        Esp:InitiateHealthBar(v)
    end,
})

EspSection:Toggle({
    Title = "🔢 血量数字",
    Value = false,
    Callback = function(v)
        Esp.State.HealthTextEnabled = v
    end,
})

EspSection:Slider({
    Title = "血量平滑",
    Value = { Min = 0.05, Max = 0.5, Default = 0.15 },
    Step = 0.01,
    Callback = function(v)
        Esp.Config.HealthBarLerpSpeed = v
    end,
})

EspSection:Space()

-- === Chams ===
EspSection:Toggle({
    Title = "✨ Chams 高亮",
    Value = false,
    Callback = function(v)
        if v then
            Esp:InitiateChams(Color3.fromRGB(103, 89, 179))
        else
            Esp.State.ChamsEnabled = false
        end
    end,
})

EspSection:Colorpicker({
    Title = "Chams 颜色",
    Default = Color3.fromRGB(103, 89, 179),
    Callback = function(c)
        Esp.Config.ChamsColor = c
    end,
})

EspSection:Colorpicker({
    Title = "Chams 轮廓色",
    Default = Color3.new(1, 1, 1),
    Callback = function(c)
        Esp.Config.ChamsOutlineColor = c
    end,
})

EspSection:Slider({
    Title = "Chams 透明度",
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Step = 0.05,
    Callback = function(v)
        Esp.Config.ChamsFillTransparency = v
    end,
})

EspSection:Space()

-- === Ring ===
EspSection:Toggle({
    Title = "⭕ 光环 ESP",
    Value = false,
    Callback = function(v)
        if v then
            Esp:InitiateRing(Color3.new(1, 1, 1))
        else
            Esp.State.RingEnabled = false
        end
    end,
})

EspSection:Colorpicker({
    Title = "光环颜色",
    Default = Color3.new(1, 1, 1),
    Callback = function(c)
        Esp.Config.RingColor = c
    end,
})

EspSection:Space()

-- === 距离限制 ===
EspSection:Slider({
    Title = "📡 ESP 最大距离",
    Value = { Min = 100, Max = 10000, Default = 1000 },
    Step = 100,
    Callback = function(v)
        Esp:SetDistance(v)
    end,
})

-- ==================== 快捷键 ====================
Window:SetToggleKey(Enum.KeyCode.G)

print("☕ Matcha ESP 已加载！按 G 键打开菜单")
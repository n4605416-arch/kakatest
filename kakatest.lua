-- gakuka FTAP - FIXED (Без тормозов, без багов)
-- Исправлено: медлительность, баг с кнопками

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

if not player then return end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flingActive = false
local antiGrabActive = true
local freezeGrabActive = false
local frozenObjects = {}
local connections = {}
local touchConnections = {}

-- ========================================
-- === ФИКС МЕДЛИТЕЛЬНОСТИ ===
-- ========================================
local function fixSlowness()
    pcall(function()
        if humanoid then
            -- ВОЗВРАЩАЕМ НОРМАЛЬНУЮ СКОРОСТЬ
            humanoid.WalkSpeed = 16 -- стандарт
            humanoid.JumpPower = 50 -- стандарт
            humanoid.AutoRotate = true
            -- ОТКЛЮЧАЕМ PlatformStand (он вызывает тормоза)
            humanoid.PlatformStand = false
            -- Включаем все состояния обратно
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        end
    end)
    
    -- ВОЗВРАЩАЕМ НОРМАЛЬНУЮ ФИЗИКУ
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 0.5, 0.5)
            end)
        end
    end
end

-- ========================================
-- === ЗАЩИТА ОТ ПОЛЁТА (БЕЗ ТОРМОЗОВ) ===
-- ========================================
local function protectSelf()
    -- ТОЛЬКО СБРАСЫВАЕМ СКОРОСТЬ ЕСЛИ ОНА СЛИШКОМ БОЛЬШАЯ
    if rootPart and rootPart.Velocity.Magnitude > 100 then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= rootPart then
            if part.Velocity.Magnitude > 100 then
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

-- ========================================
-- === ANTI-GRAB (БЕЗ ТОРМОЗОВ) ===
-- ========================================
local function enableAntiGrab()
    fixSlowness() -- ВОЗВРАЩАЕМ НОРМАЛЬНУЮ СКОРОСТЬ
    pcall(function()
        if humanoid then
            -- ТОЛЬКО ЗАПРЕЩАЕМ ГРАБ, ВСЁ ОСТАЛЬНОЕ РАЗРЕШАЕМ
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid.AutoRotate = true
            humanoid.PlatformStand = false -- ВАЖНО!
        end
    end)
    print("[Anti-Grab] ВКЛЮЧЕН")
end

-- ========================================
-- === FLING ALL ===
-- ========================================
local function startFling()
    if flingActive then return end
    flingActive = true
    fixSlowness()
    
    local conn = RunService.Heartbeat:Connect(function()
        if not flingActive then return end
        protectSelf()
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    root.Velocity = Vector3.new(
                        math.random(-500, 500),
                        math.random(100, 400),
                        math.random(-500, 500)
                    )
                    root.RotVelocity = Vector3.new(
                        math.random(-300, 300),
                        math.random(-300, 300),
                        math.random(-300, 300)
                    )
                end
            end
        end
    end)
    
    table.insert(connections, conn)
    print("[Fling] ВКЛЮЧЕН")
end

local function stopFling()
    flingActive = false
    for _, conn in ipairs(connections) do
        pcall(conn.Disconnect, conn)
    end
    connections = {}
    fixSlowness()
    print("[Fling] ВЫКЛЮЧЕН")
end

-- ========================================
-- === FREEZE GRAB ===
-- ========================================
local function freezeObject(object)
    if not object or not object:IsA("BasePart") then return end
    if frozenObjects[object] then return end
    
    pcall(function()
        local originalProps = {
            Anchored = object.Anchored,
            CanCollide = object.CanCollide,
            Locked = object.Locked,
            CustomPhysicalProperties = object.CustomPhysicalProperties,
            Transparency = object.Transparency,
            Material = object.Material,
            Color = object.Color
        }
        
        object.Anchored = true
        object.CanCollide = true
        object.Locked = true
        object.Velocity = Vector3.new(0, 0, 0)
        object.RotVelocity = Vector3.new(0, 0, 0)
        object.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        object.Transparency = 0.3
        object.Material = Enum.Material.Ice
        object.Color = Color3.fromRGB(100, 200, 255)
        
        local glow = Instance.new("SelectionBox")
        glow.Adornee = object
        glow.Color3 = Color3.fromRGB(0, 200, 255)
        glow.Transparency = 0.5
        glow.LineThickness = 0.1
        glow.Parent = object
        
        frozenObjects[object] = {
            Properties = originalProps,
            Glow = glow
        }
    end)
end

local function unfreezeObject(object)
    if not object or not frozenObjects[object] then return end
    
    pcall(function()
        local data = frozenObjects[object]
        local props = data.Properties
        object.Anchored = props.Anchored or false
        object.CanCollide = props.CanCollide or true
        object.Locked = props.Locked or false
        object.CustomPhysicalProperties = props.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 0.5, 0.5)
        object.Transparency = props.Transparency or 0
        object.Material = props.Material or Enum.Material.Plastic
        object.Color = props.Color or Color3.fromRGB(255, 255, 255)
        
        if data.Glow then
            data.Glow:Destroy()
        end
        frozenObjects[object] = nil
    end)
end

local function clearFrozen()
    for obj, _ in pairs(frozenObjects) do
        unfreezeObject(obj)
    end
    frozenObjects = {}
end

local function setupFreezeGrab()
    if not character then return end
    for _, conn in ipairs(touchConnections) do
        pcall(conn.Disconnect, conn)
    end
    touchConnections = {}
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local conn = part.Touched:Connect(function(otherPart)
                if not freezeGrabActive then return end
                if not character or not character.Parent then return end
                
                local otherCharacter = otherPart:FindFirstAncestorOfClass("Model")
                if not otherCharacter or otherCharacter == character then return end
                if otherCharacter:FindFirstChild("Humanoid") then return end
                
                local partToFreeze = otherPart
                if partToFreeze and partToFreeze:IsA("BasePart") then
                    freezeObject(partToFreeze)
                end
            end)
            table.insert(touchConnections, conn)
        end
    end
end

-- ========================================
-- === GUI ===
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "gakukaGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 320)
frame.Position = UDim2.new(0.5, -160, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(200, 50, 200)
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "💀 gakuka FTAP"
title.TextColor3 = Color3.fromRGB(255, 50, 200)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

-- Статус
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.9, 0, 0, 25)
status.Position = UDim2.new(0.05, 0, 0.18, 0)
status.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
status.BackgroundTransparency = 0.5
status.Text = "✅ ГОТОВ"
status.TextColor3 = Color3.fromRGB(0, 255, 100)
status.Font = Enum.Font.GothamSemibold
status.TextSize = 13
status.Parent = frame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = status

-- ===== КНОПКИ =====
local function createBtn(text, y, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 38)
    btn.Position = UDim2.new(0.075, 0, y, 0)
    btn.BackgroundColor3 = color or Color3.fromRGB(200, 40, 40)
    btn.BackgroundTransparency = 0.3
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.BorderSizePixel = 2
    btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- 1. FLING ALL
local flingBtn = createBtn("💥 FLING ALL [ВЫКЛ]", 0.26, Color3.fromRGB(200, 40, 40), function()
    if flingActive then
        stopFling()
        flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        status.Text = "✅ FLING ВЫКЛЮЧЕН"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        if freezeGrabActive then
            freezeGrabActive = false
            clearFrozen()
            freezeBtn.Text = "❄️ FREEZE GRAB [ВЫКЛ]"
            freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        end
        startFling()
        flingBtn.Text = "💥 FLING ALL [ВКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
        status.Text = "💥 FLING АКТИВЕН!"
        status.TextColor3 = Color3.fromRGB(0, 255, 100)
    end
end)

-- 2. FREEZE GRAB
local freezeBtn = createBtn("❄️ FREEZE GRAB [ВЫКЛ]", 0.40, Color3.fromRGB(200, 40, 40), function()
    freezeGrabActive = not freezeGrabActive
    if freezeGrabActive then
        if flingActive then
            stopFling()
            flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
            flingBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        end
        setupFreezeGrab()
        freezeBtn.Text = "❄️ FREEZE GRAB [ВКЛ]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        status.Text = "❄️ FREEZE GRAB АКТИВЕН!"
        status.TextColor3 = Color3.fromRGB(0, 200, 255)
    else
        clearFrozen()
        freezeBtn.Text = "❄️ FREEZE GRAB [ВЫКЛ]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        status.Text = "✅ FREEZE GRAB ВЫКЛЮЧЕН"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- 3. ANTI-GRAB
local antiBtn = createBtn("🛡️ ANTI-GRAB [ВКЛ]", 0.54, Color3.fromRGB(0, 180, 0), function()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then
        enableAntiGrab()
        antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        status.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН"
        status.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        antiBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        status.Text = "🛡️ ANTI-GRAB ВЫКЛЮЧЕН"
        status.TextColor3 = Color3.fromRGB(255, 150, 0)
    end
end)

-- 4. CLEAR FROZEN
local clearBtn = createBtn("🧊 РАЗМОРОЗИТЬ ВСЁ", 0.68, Color3.fromRGB(200, 150, 0), function()
    local count = 0
    for _ in pairs(frozenObjects) do count = count + 1 end
    clearFrozen()
    status.Text = "🧊 Разморожено: " .. count .. " предметов"
    status.TextColor3 = Color3.fromRGB(255, 200, 0)
end)

-- 5. STOP ALL
local stopBtn = createBtn("⛔ ОСТАНОВИТЬ ВСЁ", 0.80, Color3.fromRGB(150, 0, 30), function()
    stopFling()
    flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
    flingBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    
    freezeGrabActive = false
    clearFrozen()
    freezeBtn.Text = "❄️ FREEZE GRAB [ВЫКЛ]"
    freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    
    fixSlowness()
    status.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
end)

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    stopFling()
    clearFrozen()
    fixSlowness()
    screenGui:Destroy()
end)

-- ========================================
-- === ИНИЦИАЛИЗАЦИЯ ===
-- ========================================
fixSlowness()
enableAntiGrab()

-- Защита от полёта (мягкая, без тормозов)
RunService.Heartbeat:Connect(function()
    if character and character.Parent then
        protectSelf()
        -- ВОЗВРАЩАЕМ СКОРОСТЬ ЕСЛИ ОНА СБИТА
        if humanoid and humanoid.WalkSpeed < 15 then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
    end
end)

-- Респавн
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    fixSlowness()
    if antiGrabActive then enableAntiGrab() end
    if flingActive then
        stopFling()
        startFling()
    end
    if freezeGrabActive then
        setupFreezeGrab()
    end
end)

print("====================================")
print("  💀 gakuka FTAP - FIXED")
print("  ✅ ТЫ НЕ ЛЕТАЕШЬ")
print("  ✅ ТЫ НЕ ТОРМОЗИШЬ")
print("  =================================")
print("  1. FLING ALL - все летают")
print("  2. FREEZE GRAB - морозь предметы")
print("  3. ANTI-GRAB - защита")
print("====================================")

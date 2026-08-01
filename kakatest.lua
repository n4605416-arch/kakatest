-- gakuka FTAP - v1.3 alpha beta super super mega beta
-- ROBLOX EGOR + СВОРАЧИВАНИЕ + ВСЁ РАБОТАЕТ

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

if not player then return end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ===== СОСТОЯНИЯ =====
local flingActive = false
local antiGrabActive = true
local freezeGrabActive = false
local speedModeActive = false
local frozenObjects = {}
local connections = {}
local touchConnections = {}
local screenGui = nil
local mainFrame = nil
local collapsed = false

-- ===== КНОПКИ =====
local flingBtn, freezeBtn, antiBtn, speedBtn, status, toggleBtn

-- ========================================
-- === ФИКС СКОРОСТИ ===
-- ========================================
local function fixMovement()
    pcall(function()
        if humanoid then
            if speedModeActive then
                humanoid.WalkSpeed = 70
            else
                humanoid.WalkSpeed = 16
            end
            humanoid.AutoRotate = true
            humanoid.PlatformStand = false
            
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        end
    end)
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 0.5, 0.5)
            end)
        end
    end
end

-- ========================================
-- === ЗАЩИТА ОТ ПОЛЁТА ===
-- ========================================
local function protectSelf()
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
-- === ANTI-GRAB ===
-- ========================================
local function enableAntiGrab()
    fixMovement()
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid.AutoRotate = true
            humanoid.PlatformStand = false
        end
    end)
end

-- ========================================
-- === FLING ALL ===
-- ========================================
local function startFling()
    if flingActive then return end
    flingActive = true
    fixMovement()
    
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
end

local function stopFling()
    flingActive = false
    for _, conn in ipairs(connections) do
        pcall(conn.Disconnect, conn)
    end
    connections = {}
    fixMovement()
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
-- === SPEED MODE (ROBLOX EGOR) ===
-- ========================================
local function toggleSpeedMode()
    speedModeActive = not speedModeActive
    if speedModeActive then
        if humanoid then
            humanoid.WalkSpeed = 70
        end
        status.Text = "🏃 ROBLOX EGOR ВКЛЮЧЕН! (скорость 70)"
        status.TextColor3 = Color3.fromRGB(255, 200, 0)
        speedBtn.Text = "🏃 ROBLOX EGOR [ВКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    else
        if humanoid then
            humanoid.WalkSpeed = 16
        end
        status.Text = "✅ ROBLOX EGOR ВЫКЛЮЧЕН"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    fixMovement()
end

-- ========================================
-- === ОСТАНОВКА ВСЕГО ===
-- ========================================
local function stopAll()
    stopFling()
    freezeGrabActive = false
    clearFrozen()
    for _, conn in ipairs(touchConnections) do
        pcall(conn.Disconnect, conn)
    end
    touchConnections = {}
    if speedModeActive then
        speedModeActive = false
        if humanoid then humanoid.WalkSpeed = 16 end
        speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    fixMovement()
end

-- ========================================
-- === ОБНОВЛЕНИЕ КНОПОК ===
-- ========================================
local function updateButtons()
    if flingActive then
        flingBtn.Text = "💥 FLING ALL [ВКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    else
        flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    
    if freezeGrabActive then
        freezeBtn.Text = "❄️ FREEZE GRAB [ВКЛ]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    else
        freezeBtn.Text = "❄️ FREEZE GRAB [ВЫКЛ]"
        freezeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    
    if antiGrabActive then
        antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    else
        antiBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    
    if speedModeActive then
        speedBtn.Text = "🏃 ROBLOX EGOR [ВКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    else
        speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
end

-- ========================================
-- === GUI ===
-- ========================================
local function createGUI()
    if screenGui then 
        screenGui:Destroy()
        screenGui = nil
    end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 180)
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 2
    titleBar.BorderColor3 = Color3.fromRGB(80, 80, 180)
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "💀 gakuka FTAP"
    titleText.TextColor3 = Color3.fromRGB(200, 50, 200)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local verText = Instance.new("TextLabel")
    verText.Size = UDim2.new(1, -100, 0, 16)
    verText.Position = UDim2.new(0, 12, 0, 26)
    verText.BackgroundTransparency = 1
    verText.Text = "v1.3 alpha beta super super mega beta"
    verText.TextColor3 = Color3.fromRGB(255, 200, 100)
    verText.Font = Enum.Font.Gotham
    verText.TextSize = 10
    verText.TextXAlignment = Enum.TextXAlignment.Left
    verText.Parent = titleBar
    
    -- СВОРАЧИВАНИЕ
    toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 32, 0, 32)
    toggleBtn.Position = UDim2.new(1, -72, 0, 7)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    toggleBtn.BackgroundTransparency = 0.2
    toggleBtn.Text = "−"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 22
    toggleBtn.BorderSizePixel = 1
    toggleBtn.BorderColor3 = Color3.fromRGB(0, 150, 200)
    toggleBtn.Parent = titleBar
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        if collapsed then
            mainFrame.Size = UDim2.new(0, 400, 0, 45)
            toggleBtn.Text = "+"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            for _, child in ipairs(mainFrame:GetChildren()) do
                if child ~= titleBar and child ~= toggleBtn then
                    child.Visible = false
                end
            end
            titleText.Text = "💀 gakuka FTAP [СВЁРНУТО]"
            titleText.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            mainFrame.Size = UDim2.new(0, 400, 0, 420)
            toggleBtn.Text = "−"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
            for _, child in ipairs(mainFrame:GetChildren()) do
                child.Visible = true
            end
            titleText.Text = "💀 gakuka FTAP"
            titleText.TextColor3 = Color3.fromRGB(200, 50, 200)
        end
    end)
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -38, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.BorderSizePixel = 1
    closeBtn.BorderColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        stopAll()
        if screenGui then
            screenGui:Destroy()
            screenGui = nil
        end
        if openBtn then
            openBtn.Visible = true
        end
    end)
    
    -- Статус
    status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.9, 0, 0, 28)
    status.Position = UDim2.new(0.05, 0, 0.13, 0)
    status.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    status.BackgroundTransparency = 0.5
    status.Text = "✅ ГОТОВ | ТЫ НЕ ЛЕТАЕШЬ"
    status.TextColor3 = Color3.fromRGB(0, 255, 100)
    status.Font = Enum.Font.GothamSemibold
    status.TextSize = 13
    status.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = status
    
    -- ===== КНОПКИ =====
    local function createBtn(text, y, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.85, 0, 0, 38)
        btn.Position = UDim2.new(0.075, 0, y, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 80)
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BorderSizePixel = 2
        btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
        btn.Parent = mainFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    local yPos = 0.18
    
    flingBtn = createBtn("💥 FLING ALL [ВЫКЛ]", yPos, Color3.fromRGB(180, 40, 40), function()
        if flingActive then
            stopFling()
            status.Text = "✅ FLING ВЫКЛЮЧЕН"
            status.TextColor3 = Color3.fromRGB(200, 200, 200)
        else
            if freezeGrabActive then
                freezeGrabActive = false
                clearFrozen()
            end
            startFling()
            status.Text = "💥 FLING АКТИВЕН! (ты не летаешь)"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
        end
        updateButtons()
    end)
    
    yPos = yPos + 0.11
    
    freezeBtn = createBtn("❄️ FREEZE GRAB [ВЫКЛ]", yPos, Color3.fromRGB(180, 40, 40), function()
        freezeGrabActive = not freezeGrabActive
        if freezeGrabActive then
            if flingActive then stopFling() end
            setupFreezeGrab()
            status.Text = "❄️ FREEZE GRAB АКТИВЕН!"
            status.TextColor3 = Color3.fromRGB(0, 200, 255)
        else
            clearFrozen()
            status.Text = "✅ FREEZE GRAB ВЫКЛЮЧЕН"
            status.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        updateButtons()
    end)
    
    yPos = yPos + 0.11
    
    antiBtn = createBtn("🛡️ ANTI-GRAB [ВКЛ]", yPos, Color3.fromRGB(0, 180, 0), function()
        antiGrabActive = not antiGrabActive
        if antiGrabActive then
            enableAntiGrab()
            status.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            status.Text = "🛡️ ANTI-GRAB ВЫКЛЮЧЕН"
            status.TextColor3 = Color3.fromRGB(255, 150, 0)
        end
        updateButtons()
    end)
    
    yPos = yPos + 0.11
    
    speedBtn = createBtn("🏃 ROBLOX EGOR [ВЫКЛ]", yPos, Color3.fromRGB(180, 40, 40), function()
        toggleSpeedMode()
        updateButtons()
    end)
    
    yPos = yPos + 0.11
    
    local clearBtn = createBtn("🧊 РАЗМОРОЗИТЬ ВСЁ", yPos, Color3.fromRGB(200, 150, 0), function()
        local count = 0
        for _ in pairs(frozenObjects) do count = count + 1 end
        clearFrozen()
        status.Text = "🧊 Разморожено: " .. count .. " предметов"
        status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end)
    
    yPos = yPos + 0.11
    
    local stopBtn = createBtn("⛔ ОСТАНОВИТЬ ВСЁ", yPos, Color3.fromRGB(150, 0, 30), function()
        stopAll()
        updateButtons()
        status.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
    end)
    
    updateButtons()
    return screenGui
end

-- ========================================
-- === КНОПКА ОТКРЫТИЯ ===
-- ========================================
local openBtn = nil

local function createOpenButton()
    if openBtn then 
        openBtn:Destroy()
        openBtn = nil
    end
    
    openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 70, 0, 70)
    openBtn.Position = UDim2.new(0.85, 0, 0.85, 0)
    openBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 200)
    openBtn.BackgroundTransparency = 0.15
    openBtn.Text = "💀"
    openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    openBtn.Font = Enum.Font.GothamBold
    openBtn.TextSize = 32
    openBtn.BorderSizePixel = 2
    openBtn.BorderColor3 = Color3.fromRGB(200, 50, 200)
    openBtn.Parent = player:WaitForChild("PlayerGui")
    openBtn.Visible = false
    
    local openCorner = Instance.new("UICorner")
    openCorner.CornerRadius = UDim.new(1, 0)
    openCorner.Parent = openBtn
    
    openBtn.MouseButton1Click:Connect(function()
        if not screenGui then
            createGUI()
            openBtn.Visible = false
        end
    end)
end

-- ========================================
-- === ИНИЦИАЛИЗАЦИЯ ===
-- ========================================
fixMovement()
enableAntiGrab()
createGUI()
createOpenButton()

-- ПОСТОЯННЫЙ КОНТРОЛЬ СКОРОСТИ
RunService.Heartbeat:Connect(function()
    if character and character.Parent then
        protectSelf()
        if humanoid then
            if speedModeActive then
                if humanoid.WalkSpeed ~= 70 then
                    humanoid.WalkSpeed = 70
                end
            else
                if humanoid.WalkSpeed ~= 16 then
                    humanoid.WalkSpeed = 16
                end
            end
        end
    end
end)

-- РЕСПАВН
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    fixMovement()
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
print("  💀 gakuka FTAP")
print("  v1.3 alpha beta super super mega beta")
print("  =================================")
print("  ✅ ROBLOX EGOR - скорость 70")
print("  ✅ СВОРАЧИВАНИЕ - скрывает кнопки")
print("  ✅ ТЫ НЕ ЛЕТАЕШЬ")
print("  =================================")
print("  1. FLING ALL - все летают")
print("  2. FREEZE GRAB - морозь предметы")
print("  3. ANTI-GRAB - защита")
print("  4. ROBLOX EGOR - скорость 70!")
print("====================================")

-- gakuka FTAP - FINAL v1.3 (РЕАЛЬНЫЙ ANTI-GRAB ИЗ FTAP)
-- AntiGrab через PartOwner + ROBLOX EGOR работает

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

if not player then return end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ===== СОСТОЯНИЯ =====
local flingActive = false
local antiGrabActive = true
local speedModeActive = false
local anchorGrabActive = false
local frozenObjects = {}
local screenGui = nil
local mainFrame = nil
local collapsed = false

-- ===== КНОПКИ =====
local flingBtn, antiBtn, speedBtn, anchorBtn, statusText, toggleBtn, openBtn

-- ========================================
-- === REAL ANTI-GRAB (ИЗ FTAP) ===
-- ========================================
local antiGrabConnection = nil

local function startRealAntiGrab()
    if antiGrabConnection then return end
    
    antiGrabConnection = RunService.Heartbeat:Connect(function()
        if not antiGrabActive then return end
        if not character or not character.Parent then return end
        
        -- Проверяем Head на наличие PartOwner (это значит, что нас взяли в FTAP)
        local head = character:FindFirstChild("Head")
        if head then
            local partOwner = head:FindFirstChild("PartOwner")
            if partOwner then
                -- НАС ВЗЯЛИ! Принудительно выходим из захвата
                pcall(function()
                    -- 1. Отключаем захват через Struggle
                    local struggle = ReplicatedStorage:FindFirstChild("Struggle")
                    if struggle then
                        struggle:FireServer()
                    end
                    
                    -- 2. Останавливаем всю скорость
                    local stopAllVelocity = ReplicatedStorage:FindFirstChild("GameCorrectionEvents") and ReplicatedStorage.GameCorrectionEvents:FindFirstChild("StopAllVelocity")
                    if stopAllVelocity then
                        stopAllVelocity:FireServer()
                    end
                    
                    -- 3. Anchored все части тела на мгновение
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Anchored = true
                        end
                    end
                    
                    -- 4. Ждём пока нас отпустят
                    local heldValue = player:FindFirstChild("IsHeld")
                    if heldValue then
                        while heldValue.Value do
                            task.wait()
                        end
                    else
                        task.wait(0.1)
                    end
                    
                    -- 5. Снимаем Anchored
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Anchored = false
                        end
                    end
                    
                    -- 6. Сбрасываем скорость
                    if rootPart then
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end)
            end
        end
    end)
end

local function stopRealAntiGrab()
    if antiGrabConnection then
        antiGrabConnection:Disconnect()
        antiGrabConnection = nil
    end
end

-- ========================================
-- === ROBLOX EGOR ===
-- ========================================
local function setSpeed()
    if not humanoid then return end
    if speedModeActive then
        humanoid.WalkSpeed = 70
    else
        humanoid.WalkSpeed = 16
    end
    humanoid.JumpPower = 50
    humanoid.AutoRotate = true
    humanoid.PlatformStand = false
end

-- ========================================
-- === ANCHOR GRAB ===
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
        object.Transparency = 0.2
        object.Material = Enum.Material.Ice
        object.Color = Color3.fromRGB(80, 180, 255)
        
        local glow = Instance.new("SelectionBox")
        glow.Adornee = object
        glow.Color3 = Color3.fromRGB(0, 150, 255)
        glow.Transparency = 0.3
        glow.LineThickness = 0.15
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

local function clearAllFrozen()
    for obj, _ in pairs(frozenObjects) do
        unfreezeObject(obj)
    end
    frozenObjects = {}
end

-- ========================================
-- === FLING ALL ===
-- ========================================
local flingConn = nil

local function startFling()
    if flingActive then return end
    flingActive = true
    if flingBtn then
        flingBtn.Text = "💥 FLING ALL [ВКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    end
    if statusText then
        statusText.Text = "💥 FLING АКТИВЕН!"
        statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    end
    
    if flingConn then flingConn:Disconnect() end
    flingConn = RunService.Heartbeat:Connect(function()
        if not flingActive then return end
        
        -- ЗАЩИТА СЕБЯ
        if rootPart and rootPart.Velocity.Magnitude > 100 then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
        setSpeed()
        
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
                end
            end
        end
    end)
end

local function stopFling()
    flingActive = false
    if flingConn then
        flingConn:Disconnect()
        flingConn = nil
    end
    if flingBtn then
        flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    if statusText then
        statusText.Text = "✅ FLING ВЫКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

-- ========================================
-- === TOGGLE FUNCTIONS ===
-- ========================================
local function toggleSpeed()
    speedModeActive = not speedModeActive
    setSpeed()
    if speedModeActive then
        if speedBtn then
            speedBtn.Text = "🏃 ROBLOX EGOR [ВКЛ]"
            speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        end
        if statusText then
            statusText.Text = "🏃 ROBLOX EGOR ВКЛ! (скорость 70)"
            statusText.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    else
        if speedBtn then
            speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
            speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
        if statusText then
            statusText.Text = "✅ ROBLOX EGOR ВЫКЛ"
            statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

local function toggleAntiGrab()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then
        startRealAntiGrab()
        if antiBtn then
            antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
            antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        end
        if statusText then
            statusText.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН (FTAP)"
            statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
        end
    else
        stopRealAntiGrab()
        if antiBtn then
            antiBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
            antiBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
        if statusText then
            statusText.Text = "🛡️ ANTI-GRAB ВЫКЛЮЧЕН"
            statusText.TextColor3 = Color3.fromRGB(255, 150, 0)
        end
    end
end

local function toggleAnchorGrab()
    anchorGrabActive = not anchorGrabActive
    if anchorGrabActive then
        if anchorBtn then
            anchorBtn.Text = "⚓ ANCHOR GRAB [ВКЛ]"
            anchorBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        end
        if statusText then
            statusText.Text = "⚓ ANCHOR GRAB ВКЛЮЧЕН!"
            statusText.TextColor3 = Color3.fromRGB(0, 200, 255)
        end
    else
        clearAllFrozen()
        if anchorBtn then
            anchorBtn.Text = "⚓ ANCHOR GRAB [ВЫКЛ]"
            anchorBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
        if statusText then
            statusText.Text = "✅ ANCHOR GRAB ВЫКЛЮЧЕН"
            statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

-- ========================================
-- === ОСТАНОВКА ВСЕГО ===
-- ========================================
local function stopAll()
    stopFling()
    stopRealAntiGrab()
    if speedModeActive then
        speedModeActive = false
        setSpeed()
        if speedBtn then
            speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
            speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
    end
    if anchorGrabActive then
        anchorGrabActive = false
        clearAllFrozen()
        if anchorBtn then
            anchorBtn.Text = "⚓ ANCHOR GRAB [ВЫКЛ]"
            anchorBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
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
    mainFrame.Size = UDim2.new(0, 350, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -160)
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
    verText.Text = "v1.3 | REAL ANTI-GRAB FTAP"
    verText.TextColor3 = Color3.fromRGB(0, 200, 255)
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
            mainFrame.Size = UDim2.new(0, 350, 0, 45)
            toggleBtn.Text = "+"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            titleText.Text = "💀 gakuka [СВЁРНУТО]"
            titleText.TextColor3 = Color3.fromRGB(255, 200, 100)
            for _, child in ipairs(mainFrame:GetChildren()) do
                if child ~= titleBar and child ~= toggleBtn then
                    child.Visible = false
                end
            end
        else
            mainFrame.Size = UDim2.new(0, 350, 0, 320)
            toggleBtn.Text = "−"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
            titleText.Text = "💀 gakuka FTAP"
            titleText.TextColor3 = Color3.fromRGB(200, 50, 200)
            for _, child in ipairs(mainFrame:GetChildren()) do
                child.Visible = true
            end
        end
    end)
    
    -- ЗАКРЫТИЕ
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
        if openBtn then openBtn.Visible = true end
    end)
    
    -- СТАТУС
    statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(0.9, 0, 0, 25)
    statusText.Position = UDim2.new(0.05, 0, 0.16, 0)
    statusText.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    statusText.BackgroundTransparency = 0.5
    statusText.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН"
    statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusText.Font = Enum.Font.GothamSemibold
    statusText.TextSize = 12
    statusText.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusText
    
    -- ===== КНОПКИ =====
    local function createBtn(text, y, color, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.85, 0, 0, 33)
        btn.Position = UDim2.new(0.075, 0, y, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 80)
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BorderSizePixel = 2
        btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
        btn.Parent = mainFrame
        
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn
        
        btn.MouseButton1Click:Connect(cb)
        return btn
    end
    
    local y = 0.22
    
    flingBtn = createBtn("💥 FLING ALL [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        if flingActive then stopFling() else startFling() end
    end)
    y = y + 0.10
    
    antiBtn = createBtn("🛡️ ANTI-GRAB [ВКЛ]", y, Color3.fromRGB(0, 180, 0), toggleAntiGrab)
    y = y + 0.10
    
    speedBtn = createBtn("🏃 ROBLOX EGOR [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), toggleSpeed)
    y = y + 0.10
    
    anchorBtn = createBtn("⚓ ANCHOR GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), toggleAnchorGrab)
    y = y + 0.10
    
    local stopBtn = createBtn("⛔ ОСТАНОВИТЬ ВСЁ", y, Color3.fromRGB(150, 0, 30), function()
        stopAll()
        if statusText then
            statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
            statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    return screenGui
end

-- ========================================
-- === КНОПКА ОТКРЫТИЯ ===
-- ========================================
local function createOpenButton()
    if openBtn then
        openBtn:Destroy()
        openBtn = nil
    end
    
    openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 60, 0, 60)
    openBtn.Position = UDim2.new(0.85, 0, 0.85, 0)
    openBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 200)
    openBtn.BackgroundTransparency = 0.15
    openBtn.Text = "💀"
    openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    openBtn.Font = Enum.Font.GothamBold
    openBtn.TextSize = 30
    openBtn.BorderSizePixel = 2
    openBtn.BorderColor3 = Color3.fromRGB(200, 50, 200)
    openBtn.Parent = player:WaitForChild("PlayerGui")
    openBtn.Visible = false
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = openBtn
    
    openBtn.MouseButton1Click:Connect(function()
        if not screenGui then
            createGUI()
            openBtn.Visible = false
            if flingActive and flingBtn then
                flingBtn.Text = "💥 FLING ALL [ВКЛ]"
                flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
            end
            if antiGrabActive and antiBtn then
                antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
                antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            end
            if speedModeActive and speedBtn then
                speedBtn.Text = "🏃 ROBLOX EGOR [ВКЛ]"
                speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            end
            if anchorGrabActive and anchorBtn then
                anchorBtn.Text = "⚓ ANCHOR GRAB [ВКЛ]"
                anchorBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
            end
        end
    end)
end

-- ========================================
-- === ПОСТОЯННЫЙ КОНТРОЛЬ ===
-- ========================================
local function tick()
    if not character or not character.Parent then return end
    
    -- ЗАЩИТА ОТ ПОЛЁТА
    if rootPart and rootPart.Velocity.Magnitude > 100 then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    setSpeed()
end

-- ========================================
-- === ИНИЦИАЛИЗАЦИЯ ===
-- ========================================
setSpeed()
startRealAntiGrab()
createGUI()
createOpenButton()

RunService.Heartbeat:Connect(tick)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    setSpeed()
    if antiGrabActive then startRealAntiGrab() end
    if flingActive then
        stopFling()
        startFling()
    end
end)

print("====================================")
print("  💀 gakuka FTAP - REAL ANTI-GRAB")
print("  =================================")
print("  🛡️ ANTI-GRAB - PartOwner защита!")
print("  ✅ ROBLOX EGOR - скорость 70")
print("  ⚓ ANCHOR GRAB - заморозка предметов")
print("  ✅ ТЫ НЕ ЛЕТАЕШЬ")
print("====================================")

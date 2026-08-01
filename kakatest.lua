-- gakuka FTAP - SIMPLE v1.3
-- Простое меню, Anti-Grab работает, скорость работает, ходьба нормальная

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
local screenGui = nil
local mainFrame = nil

-- ===== КНОПКИ =====
local flingBtn, antiBtn, speedBtn, statusText

-- ========================================
-- === ANTI-GRAB (ИЗ FTAP) ===
-- ========================================
local antiGrabConnection = nil

local function startAntiGrab()
    if antiGrabConnection then return end
    
    antiGrabConnection = RunService.Heartbeat:Connect(function()
        if not antiGrabActive then return end
        if not character or not character.Parent then return end
        
        local head = character:FindFirstChild("Head")
        if head then
            local partOwner = head:FindFirstChild("PartOwner")
            if partOwner then
                pcall(function()
                    -- Struggle:FireServer() - вырываемся [citation:9]
                    local struggle = ReplicatedStorage:FindFirstChild("CharacterEvents")
                    if struggle then
                        local struggleEvent = struggle:FindFirstChild("Struggle")
                        if struggleEvent then struggleEvent:FireServer() end
                    end
                    
                    -- StopAllVelocity - сбрасываем скорость [citation:9]
                    local correction = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
                    if correction then
                        local stopVelocity = correction:FindFirstChild("StopAllVelocity")
                        if stopVelocity then stopVelocity:FireServer() end
                    end
                    
                    -- Anchored все части тела [citation:9]
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Anchored = true
                        end
                    end
                    
                    -- Ждём пока отпустят [citation:9]
                    local heldValue = player:FindFirstChild("IsHeld")
                    if heldValue then
                        while heldValue.Value do task.wait() end
                    else
                        task.wait(0.1)
                    end
                    
                    -- Снимаем Anchored [citation:9]
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Anchored = false
                        end
                    end
                    
                    if rootPart then
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end)
            end
        end
    end)
end

local function stopAntiGrab()
    if antiGrabConnection then
        antiGrabConnection:Disconnect()
        antiGrabConnection = nil
    end
end

-- ========================================
-- === ROBLOX EGOR (СКОРОСТЬ) ===
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
-- === FLING ALL ===
-- ========================================
local flingConn = nil

local function startFling()
    if flingActive then return end
    flingActive = true
    flingBtn.Text = "💥 FLING ALL [ВКЛ]"
    flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    statusText.Text = "💥 FLING АКТИВЕН!"
    statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    
    if flingConn then flingConn:Disconnect() end
    flingConn = RunService.Heartbeat:Connect(function()
        if not flingActive then return end
        -- ЗАЩИТА СЕБЯ
        if rootPart and rootPart.Velocity.Magnitude > 100 then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
        setSpeed()
        -- ФЛИНГ ДРУГИХ
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
    flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
    flingBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    statusText.Text = "✅ FLING ВЫКЛЮЧЕН"
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
end

-- ========================================
-- === TOGGLE ===
-- ========================================
local function toggleSpeed()
    speedModeActive = not speedModeActive
    setSpeed()
    if speedModeActive then
        speedBtn.Text = "🏃 ROBLOX EGOR [ВКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        statusText.Text = "🏃 ROBLOX EGOR ВКЛ! (скорость 70)"
        statusText.TextColor3 = Color3.fromRGB(255, 200, 0)
    else
        speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusText.Text = "✅ ROBLOX EGOR ВЫКЛ"
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

local function toggleAntiGrab()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then
        startAntiGrab()
        antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        statusText.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        stopAntiGrab()
        antiBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusText.Text = "🛡️ ANTI-GRAB ВЫКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(255, 150, 0)
    end
end

local function stopAll()
    stopFling()
    stopAntiGrab()
    if speedModeActive then
        speedModeActive = false
        setSpeed()
        speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
    statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
end

-- ========================================
-- === GUI (ПРОСТОЕ КАК РАНЬШЕ) ===
-- ========================================
local function createGUI()
    if screenGui then screenGui:Destroy() end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -140)
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
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 2
    titleBar.BorderColor3 = Color3.fromRGB(80, 80, 180)
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "💀 gakuka FTAP"
    titleText.TextColor3 = Color3.fromRGB(200, 50, 200)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Center
    titleText.Parent = titleBar
    
    -- Закрытие (кнопка X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
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
    end)
    
    -- Статус
    statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(0.9, 0, 0, 25)
    statusText.Position = UDim2.new(0.05, 0, 0.17, 0)
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
        btn.Size = UDim2.new(0.85, 0, 0, 35)
        btn.Position = UDim2.new(0.075, 0, y, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 80)
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BorderSizePixel = 2
        btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
        btn.Parent = mainFrame
        
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn
        
        btn.MouseButton1Click:Connect(cb)
        return btn
    end
    
    local y = 0.23
    
    flingBtn = createBtn("💥 FLING ALL [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        if flingActive then stopFling() else startFling() end
    end)
    y = y + 0.11
    
    antiBtn = createBtn("🛡️ ANTI-GRAB [ВКЛ]", y, Color3.fromRGB(0, 180, 0), toggleAntiGrab)
    y = y + 0.11
    
    speedBtn = createBtn("🏃 ROBLOX EGOR [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), toggleSpeed)
    y = y + 0.11
    
    local stopBtn = createBtn("⛔ ОСТАНОВИТЬ ВСЁ", y, Color3.fromRGB(150, 0, 30), function()
        stopAll()
        statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end)
    
    return screenGui
end

-- ========================================
-- === ПОСТОЯННЫЙ КОНТРОЛЬ ===
-- ========================================
local function tick()
    if not character or not character.Parent then return end
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
startAntiGrab()
createGUI()

RunService.Heartbeat:Connect(tick)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    setSpeed()
    if antiGrabActive then startAntiGrab() end
    if flingActive then
        stopFling()
        startFling()
    end
end)

print("====================================")
print("  💀 gakuka FTAP - SIMPLE v1.3")
print("  =================================")
print("  🛡️ ANTI-GRAB - РАБОТАЕТ")
print("  ✅ ROBLOX EGOR - скорость 70")
print("  💥 FLING ALL - все летают")
print("  =================================")
print("  ✅ ХОДЬБА НОРМАЛЬНАЯ")
print("  ✅ МОЖНО БРАТЬ ПРЕДМЕТЫ")
print("====================================")

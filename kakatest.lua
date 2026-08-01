-- Ryzen Fling That v5.0 (МОБИЛЬНАЯ ВЕРСИЯ)
-- Без горячих клавиш, только кнопки
-- Полностью рабочий для Delta Mobile / Hydrogen / Arceus

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then return end

-- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flingActive = false
local antiGrabActive = true
local targetPlayer = nil
local flingConnections = {}
local guiVisible = true
local screenGui = nil
local mainFrame = nil

-- === СОЗДАНИЕ GUI ===
local function createGUI()
    if screenGui then 
        screenGui:Destroy() 
    end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RyzenFlingGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    -- ГЛАВНОЕ ОКНО
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(60, 60, 150)
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- ЗАГОЛОВОК
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 2
    titleBar.BorderColor3 = Color3.fromRGB(60, 60, 150)
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "⚡ RYZEN FLING"
    titleText.TextColor3 = Color3.fromRGB(0, 200, 255)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 20
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- КНОПКА СВЕРНУТЬ/РАЗВЕРНУТЬ (для телефона)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 35, 0, 35)
    toggleBtn.Position = UDim2.new(1, -80, 0, 5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    toggleBtn.Text = "−"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 24
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = titleBar
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        if guiVisible then
            mainFrame.Size = UDim2.new(0, 400, 0, 520)
            toggleBtn.Text = "−"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        else
            mainFrame.Size = UDim2.new(0, 400, 0, 45)
            toggleBtn.Text = "+"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        end
    end)
    
    -- КНОПКА ЗАКРЫТИЯ (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- СТАТУС
    local statusBar = Instance.new("TextLabel")
    statusBar.Size = UDim2.new(0.9, 0, 0, 28)
    statusBar.Position = UDim2.new(0.05, 0, 0.12, 0)
    statusBar.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    statusBar.BackgroundTransparency = 0.5
    statusBar.Text = "✅ СТАТУС: ОЖИДАНИЕ"
    statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusBar.Font = Enum.Font.GothamSemibold
    statusBar.TextSize = 14
    statusBar.TextXAlignment = Enum.TextXAlignment.Center
    statusBar.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusBar
    
    -- === КНОПКИ ===
    local yPos = 0.22
    
    -- 1. FLING THAT
    local flingThatBtn = Instance.new("TextButton")
    flingThatBtn.Size = UDim2.new(0.85, 0, 0, 45)
    flingThatBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    flingThatBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    flingThatBtn.BackgroundTransparency = 0.3
    flingThatBtn.Text = "🎯 FLING THAT [ВЫКЛ]"
    flingThatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flingThatBtn.Font = Enum.Font.GothamBold
    flingThatBtn.TextSize = 17
    flingThatBtn.BorderSizePixel = 2
    flingThatBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
    flingThatBtn.Parent = mainFrame
    
    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 8)
    btnCorner1.Parent = flingThatBtn
    
    yPos = yPos + 0.13
    
    -- 2. FLING PEOPLE
    local flingPeopleBtn = Instance.new("TextButton")
    flingPeopleBtn.Size = UDim2.new(0.85, 0, 0, 45)
    flingPeopleBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    flingPeopleBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    flingPeopleBtn.BackgroundTransparency = 0.3
    flingPeopleBtn.Text = "👥 FLING PEOPLE [ВЫКЛ]"
    flingPeopleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flingPeopleBtn.Font = Enum.Font.GothamBold
    flingPeopleBtn.TextSize = 17
    flingPeopleBtn.BorderSizePixel = 2
    flingPeopleBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
    flingPeopleBtn.Parent = mainFrame
    
    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 8)
    btnCorner2.Parent = flingPeopleBtn
    
    yPos = yPos + 0.13
    
    -- 3. ANTI-GRAB (ЗЕЛЁНЫЙ = ВКЛ)
    local antiGrabBtn = Instance.new("TextButton")
    antiGrabBtn.Size = UDim2.new(0.85, 0, 0, 45)
    antiGrabBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    antiGrabBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    antiGrabBtn.BackgroundTransparency = 0.3
    antiGrabBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
    antiGrabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiGrabBtn.Font = Enum.Font.GothamBold
    antiGrabBtn.TextSize = 17
    antiGrabBtn.BorderSizePixel = 2
    antiGrabBtn.BorderColor3 = Color3.fromRGB(0, 200, 0)
    antiGrabBtn.Parent = mainFrame
    
    local btnCorner3 = Instance.new("UICorner")
    btnCorner3.CornerRadius = UDim.new(0, 8)
    btnCorner3.Parent = antiGrabBtn
    
    yPos = yPos + 0.13
    
    -- 4. STOP ALL
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0.85, 0, 0, 42)
    stopBtn.Position = UDim2.new(0.075, 0, yPos + 0.02, 0)
    stopBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 30)
    stopBtn.BackgroundTransparency = 0.2
    stopBtn.Text = "⛔ ОСТАНОВИТЬ ВСЁ"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 18
    stopBtn.BorderSizePixel = 2
    stopBtn.BorderColor3 = Color3.fromRGB(200, 0, 50)
    stopBtn.Parent = mainFrame
    
    local btnCorner4 = Instance.new("UICorner")
    btnCorner4.CornerRadius = UDim.new(0, 8)
    btnCorner4.Parent = stopBtn
    
    yPos = yPos + 0.13
    
    -- СПИСОК ИГРОКОВ
    local listLabel = Instance.new("TextLabel")
    listLabel.Size = UDim2.new(0.85, 0, 0, 25)
    listLabel.Position = UDim2.new(0.075, 0, yPos + 0.03, 0)
    listLabel.BackgroundTransparency = 1
    listLabel.Text = "🎯 ВЫБЕРИ ЦЕЛЬ (нажми на имя):"
    listLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
    listLabel.Font = Enum.Font.GothamSemibold
    listLabel.TextSize = 13
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.Parent = mainFrame
    
    yPos = yPos + 0.09
    
    local playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Size = UDim2.new(0.85, 0, 0, 80)
    playerListFrame.Position = UDim2.new(0.075, 0, yPos, 0)
    playerListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
    playerListFrame.BackgroundTransparency = 0.5
    playerListFrame.BorderSizePixel = 2
    playerListFrame.BorderColor3 = Color3.fromRGB(60, 60, 150)
    playerListFrame.Parent = mainFrame
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerListFrame.ScrollBarThickness = 6
    playerListFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = playerListFrame
    
    -- === ЛОГИКА ===
    local function updateButtons()
        -- Fling That
        if flingActive and targetPlayer then
            flingThatBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
            flingThatBtn.BorderColor3 = Color3.fromRGB(0, 255, 80)
            flingThatBtn.Text = "🎯 FLING THAT [ВКЛ]"
        else
            flingThatBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            flingThatBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
            flingThatBtn.Text = "🎯 FLING THAT [ВЫКЛ]"
        end
        
        -- Fling People
        if flingActive and not targetPlayer then
            flingPeopleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
            flingPeopleBtn.BorderColor3 = Color3.fromRGB(0, 255, 80)
            flingPeopleBtn.Text = "👥 FLING PEOPLE [ВКЛ]"
        else
            flingPeopleBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            flingPeopleBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
            flingPeopleBtn.Text = "👥 FLING PEOPLE [ВЫКЛ]"
        end
        
        -- Anti-Grab
        if antiGrabActive then
            antiGrabBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            antiGrabBtn.BorderColor3 = Color3.fromRGB(0, 255, 0)
            antiGrabBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
        else
            antiGrabBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            antiGrabBtn.BorderColor3 = Color3.fromRGB(200, 0, 0)
            antiGrabBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
        end
    end
    
    -- FLING THAT
    flingThatBtn.MouseButton1Click:Connect(function()
        if not targetPlayer then
            statusBar.Text = "⚠️ СНАЧАЛА ВЫБЕРИ ЦЕЛЬ!"
            statusBar.TextColor3 = Color3.fromRGB(255, 200, 0)
            return
        end
        
        if flingActive and targetPlayer then
            stopFling()
            statusBar.Text = "✅ FLING THAT ОСТАНОВЛЕН"
            statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
            updateButtons()
            return
        end
        
        if flingActive then stopFling() end
        startFling(targetPlayer)
        statusBar.Text = "✅ FLING THAT: " .. targetPlayer.Name
        statusBar.TextColor3 = Color3.fromRGB(0, 255, 100)
        updateButtons()
    end)
    
    -- FLING PEOPLE
    flingPeopleBtn.MouseButton1Click:Connect(function()
        if flingActive and not targetPlayer then
            stopFling()
            statusBar.Text = "✅ FLING PEOPLE ОСТАНОВЛЕН"
            statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
            updateButtons()
            return
        end
        
        if flingActive then stopFling() end
        targetPlayer = nil
        startFling(nil)
        statusBar.Text = "✅ FLING PEOPLE: ВСЕ ИГРОКИ"
        statusBar.TextColor3 = Color3.fromRGB(0, 255, 100)
        updateButtons()
    end)
    
    -- ANTI-GRAB
    antiGrabBtn.MouseButton1Click:Connect(function()
        antiGrabActive = not antiGrabActive
        if antiGrabActive then
            enableAntiGrab()
            statusBar.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН"
            statusBar.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            disableAntiGrab()
            statusBar.Text = "🛡️ ANTI-GRAB ВЫКЛЮЧЕН"
            statusBar.TextColor3 = Color3.fromRGB(255, 150, 0)
        end
        updateButtons()
    end)
    
    -- STOP ALL
    stopBtn.MouseButton1Click:Connect(function()
        stopFling()
        statusBar.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        statusBar.TextColor3 = Color3.fromRGB(255, 100, 100)
        updateButtons()
    end)
    
    -- === ОБНОВЛЕНИЕ СПИСКА ИГРОКОВ ===
    local function updatePlayerList()
        for _, child in ipairs(playerListFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local yOffset = 5
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -10, 0, 28)
                btn.Position = UDim2.new(0, 5, 0, yOffset)
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
                btn.BackgroundTransparency = 0.3
                btn.Text = "👤 " .. plr.Name
                btn.TextColor3 = Color3.fromRGB(220, 220, 255)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.BorderSizePixel = 1
                btn.BorderColor3 = Color3.fromRGB(60, 60, 120)
                btn.Parent = playerListFrame
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 4)
                btnCorner.Parent = btn
                
                btn.MouseButton1Click:Connect(function()
                    targetPlayer = plr
                    statusBar.Text = "✅ ЦЕЛЬ: " .. plr.Name
                    statusBar.TextColor3 = Color3.fromRGB(100, 200, 255)
                    for _, b in ipairs(playerListFrame:GetChildren()) do
                        if b:IsA("TextButton") then
                            b.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
                        end
                    end
                    btn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
                    updateButtons()
                end)
                
                yOffset = yOffset + 33
            end
        end
        
        playerListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
    end
    
    updatePlayerList()
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)
    
    updateButtons()
    return screenGui
end

-- === ФУНКЦИИ ANTI-GRAB ===
function enableAntiGrab()
    if not character then return end
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end
        end
    end)
end

function disableAntiGrab()
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 0.5, 0.5)
            end
        end
    end)
end

-- === ФУНКЦИИ ФЛИНГА ===
function startFling(target)
    if flingActive then stopFling() end
    flingActive = true
    
    local function flingLoop()
        if not flingActive or not character or not character.Parent then
            flingActive = false
            return
        end
        
        local targets = {}
        if target then
            local targetChar = target.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                targets = {targetChar}
            end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player then
                    local char = plr.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        table.insert(targets, char)
                    end
                end
            end
        end
        
        for _, char in ipairs(targets) do
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local power = math.random(350, 650)
                local dir = Vector3.new(
                    math.random(-100, 100),
                    math.random(80, 250),
                    math.random(-100, 100)
                ).Unit
                root.Velocity = dir * power
                root.RotVelocity = Vector3.new(
                    math.random(-300, 300),
                    math.random(-300, 300),
                    math.random(-300, 300)
                )
                
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    hum:TakeDamage(math.random(10, 30))
                end
            end
        end
        
        if antiGrabActive then enableAntiGrab() end
    end
    
    local conn = RunService.Heartbeat:Connect(flingLoop)
    table.insert(flingConnections, conn)
end

function stopFling()
    flingActive = false
    for _, conn in ipairs(flingConnections) do
        pcall(conn.Disconnect, conn)
    end
    flingConnections = {}
    
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

-- === РЕСПАВН ===
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    if antiGrabActive then enableAntiGrab() end
    if flingActive then
        stopFling()
        startFling(targetPlayer)
    end
end)

-- === ЗАПУСК ===
createGUI()
enableAntiGrab()
print("✅ RYZEN FLING ЗАГРУЖЕН!")
print("📱 Мобильная версия")
print("🔄 Кнопка '−' сворачивает окно")
print("✅ Anti-Grab включен по умолчанию")

game:BindToClose(function()
    stopFling()
end)

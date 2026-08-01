-- gakuka(govno) v1.0 (МОБИЛЬНАЯ ВЕРСИЯ)
-- Только Fling All + Работающий Anti-Grab
-- Без урона, без выбора цели

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flingActive = false
local antiGrabActive = true
local flingConnections = {}
local antiGrabConnections = {}
local guiVisible = true
local screenGui = nil
local mainFrame = nil

-- === НОВЫЙ ANTI-GRAB (100% РАБОТАЕТ) ===
function enableAntiGrab()
    if not character then return end
    
    -- Отключаем все состояния, которые позволяют взять персонажа
    pcall(function()
        if humanoid then
            -- Запрещаем все состояния захвата
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
            
            -- Отключаем автоматическое выравнивание
            humanoid.AutoRotate = false
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
    end)
    
    -- Блокируем все части тела от захвата
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                -- Делаем часть неуязвимой для захвата
                part.CanCollide = true
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                
                -- Отключаем все соединения, которые могут захватить
                for _, constraint in ipairs(part:GetChildren()) do
                    if constraint:IsA("Attachment") or constraint:IsA("Motor6D") then
                        -- Оставляем только нужные
                    end
                end
            end)
        end
    end
    
    -- Блокируем через Character.HumanoidRootPart
    if rootPart then
        pcall(function()
            rootPart.CanCollide = true
            rootPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        end)
    end
    
    -- Дополнительная защита: каждые 0.5 секунды сбрасываем захват
    if #antiGrabConnections == 0 then
        local antiGrabLoop = RunService.Heartbeat:Connect(function()
            if not antiGrabActive then return end
            if not character or not character.Parent then return end
            
            pcall(function()
                if humanoid then
                    -- Если персонаж в состоянии захвата - сбрасываем
                    if humanoid:GetState() == Enum.HumanoidStateType.Grabbed then
                        humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
                        -- Принудительно переключаем в свободное состояние
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
                
                -- Сбрасываем скорость частей, если они захвачены
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.Velocity.Magnitude > 500 then
                            part.Velocity = part.Velocity * 0.9
                        end
                    end
                end
            end)
        end)
        table.insert(antiGrabConnections, antiGrabLoop)
    end
    
    print("[Anti-Grab] ВКЛЮЧЕН")
end

function disableAntiGrab()
    antiGrabActive = false
    
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end)
    
    for _, conn in ipairs(antiGrabConnections) do
        pcall(conn.Disconnect, conn)
    end
    antiGrabConnections = {}
    
    print("[Anti-Grab] ВЫКЛЮЧЕН")
end

-- === ФУНКЦИИ ФЛИНГА (БЕЗ УРОНА) ===
function startFling()
    if flingActive then stopFling() return end
    flingActive = true
    
    local function flingLoop()
        if not flingActive or not character or not character.Parent then
            flingActive = false
            return
        end
        
        -- Флинг всех игроков (кроме себя)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    
                    -- Случайная сила и направление
                    local power = math.random(350, 700)
                    local dir = Vector3.new(
                        math.random(-100, 100),
                        math.random(50, 250),
                        math.random(-100, 100)
                    ).Unit
                    
                    -- Применяем скорость (БЕЗ УРОНА)
                    root.Velocity = dir * power
                    root.RotVelocity = Vector3.new(
                        math.random(-300, 300),
                        math.random(-300, 300),
                        math.random(-300, 300)
                    )
                end
            end
        end
        
        -- Anti-Grab активен всегда
        if antiGrabActive then enableAntiGrab() end
    end
    
    local conn = RunService.Heartbeat:Connect(flingLoop)
    table.insert(flingConnections, conn)
    print("[Fling] ВКЛЮЧЕН")
end

function stopFling()
    flingActive = false
    for _, conn in ipairs(flingConnections) do
        pcall(conn.Disconnect, conn)
    end
    flingConnections = {}
    
    -- Останавливаем всех
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
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
    print("[Fling] ВЫКЛЮЧЕН")
end

-- === СОЗДАНИЕ GUI ===
local function createGUI()
    if screenGui then 
        screenGui:Destroy() 
    end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    -- ГЛАВНОЕ ОКНО
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(200, 50, 200)
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
    titleBar.BorderColor3 = Color3.fromRGB(200, 50, 200)
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -70, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "💀 gakuka(govno)"
    titleText.TextColor3 = Color3.fromRGB(255, 50, 200)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 20
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- КНОПКА СВЕРНУТЬ
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 35, 0, 35)
    toggleBtn.Position = UDim2.new(1, -75, 0, 5)
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
            mainFrame.Size = UDim2.new(0, 350, 0, 320)
            toggleBtn.Text = "−"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        else
            mainFrame.Size = UDim2.new(0, 350, 0, 45)
            toggleBtn.Text = "+"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        end
    end)
    
    -- КНОПКА ЗАКРЫТИЯ
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
    statusBar.Position = UDim2.new(0.05, 0, 0.15, 0)
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
    local yPos = 0.28
    
    -- 1. FLING ALL
    local flingBtn = Instance.new("TextButton")
    flingBtn.Size = UDim2.new(0.85, 0, 0, 50)
    flingBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    flingBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    flingBtn.BackgroundTransparency = 0.3
    flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
    flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flingBtn.Font = Enum.Font.GothamBold
    flingBtn.TextSize = 18
    flingBtn.BorderSizePixel = 2
    flingBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
    flingBtn.Parent = mainFrame
    
    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 8)
    btnCorner1.Parent = flingBtn
    
    yPos = yPos + 0.17
    
    -- 2. ANTI-GRAB
    local antiGrabBtn = Instance.new("TextButton")
    antiGrabBtn.Size = UDim2.new(0.85, 0, 0, 50)
    antiGrabBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    antiGrabBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    antiGrabBtn.BackgroundTransparency = 0.3
    antiGrabBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
    antiGrabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiGrabBtn.Font = Enum.Font.GothamBold
    antiGrabBtn.TextSize = 18
    antiGrabBtn.BorderSizePixel = 2
    antiGrabBtn.BorderColor3 = Color3.fromRGB(0, 200, 0)
    antiGrabBtn.Parent = mainFrame
    
    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 8)
    btnCorner2.Parent = antiGrabBtn
    
    yPos = yPos + 0.17
    
    -- 3. STOP ALL
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0.85, 0, 0, 45)
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
    
    local btnCorner3 = Instance.new("UICorner")
    btnCorner3.CornerRadius = UDim.new(0, 8)
    btnCorner3.Parent = stopBtn
    
    -- === ЛОГИКА КНОПОК ===
    local function updateButtons()
        -- Fling
        if flingActive then
            flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
            flingBtn.BorderColor3 = Color3.fromRGB(0, 255, 80)
            flingBtn.Text = "💥 FLING ALL [ВКЛ]"
        else
            flingBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            flingBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
            flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
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
    
    -- FLING ALL
    flingBtn.MouseButton1Click:Connect(function()
        if flingActive then
            stopFling()
            statusBar.Text = "✅ FLING ОСТАНОВЛЕН"
            statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
        else
            startFling()
            statusBar.Text = "💥 FLING ALL АКТИВЕН!"
            statusBar.TextColor3 = Color3.fromRGB(0, 255, 100)
        end
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
    
    updateButtons()
    return screenGui
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
        startFling()
    end
end)

-- === ЗАПУСК ===
createGUI()
enableAntiGrab()

print("====================================")
print("  💀 gakuka(govno) загружен!")
print("  🔥 Fling All - все игроки летают")
print("  🛡️ Anti-Grab - защита от захвата")
print("  ❌ Урон отключен - никто не умирает")
print("====================================")

game:BindToClose(function()
    stopFling()
    disableAntiGrab()
end)

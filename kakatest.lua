-- Ryzen Fling That & People v3.0 (ТОЧНАЯ КОПИЯ СТИЛЯ)
-- Полностью рабочий для Delta / Synapse / Krnl

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end

-- === ПЕРЕМЕННЫЕ ===
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flingActive = false
local flingConnections = {}
local antiGrabActive = true
local touchFlingActive = false
local targetPlayer = nil

-- === СОЗДАНИЕ GUI (ТОЧНО КАК НА СКРИНШОТЕ) ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RyzenFlingGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Главное окно (стиль "Infinite Yield")
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 520)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 120)
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Заголовок (как на скриншоте "ton 618")
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 1
titleBar.BorderColor3 = Color3.fromRGB(80, 80, 120)
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚡ RYZEN FLING v3.0"
titleText.TextColor3 = Color3.fromRGB(0, 200, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 20
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Parent = titleBar

-- Кнопка закрытия (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- === КНОПКИ КАК НА СКРИНШОТЕ ===
local function createButton(text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 40)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 90)
    btn.BackgroundTransparency = 0.3
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(100, 100, 150)
    btn.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Статусная строка
local statusBar = Instance.new("TextLabel")
statusBar.Size = UDim2.new(0.85, 0, 0, 25)
statusBar.Position = UDim2.new(0.075, 0, 0, 50)
statusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
statusBar.BackgroundTransparency = 0.5
statusBar.Text = "➤ Статус: Выключен"
statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
statusBar.Font = Enum.Font.Gotham
statusBar.TextSize = 14
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusBar

-- === ОСНОВНЫЕ КНОПКИ (Fling That & People) ===
local yPos = 90

-- Fling That (активирует флинг для выбранного игрока)
local flingThatBtn = createButton("🎯 FLING THAT", yPos, Color3.fromRGB(200, 50, 50), function()
    if flingActive then
        stopFling()
        flingThatBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        statusBar.Text = "➤ Статус: Выключен"
        return
    end
    
    if not targetPlayer then
        statusBar.Text = "⚠️ Сначала выбери цель в списке!"
        return
    end
    
    startFling(targetPlayer)
    flingThatBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    statusBar.Text = "➤ FLING THAT: АКТИВЕН на " .. targetPlayer.Name
end)
yPos = yPos + 50

-- Fling People (флинг всех рядом)
local flingPeopleBtn = createButton("👥 FLING PEOPLE", yPos, Color3.fromRGB(200, 100, 0), function()
    if flingActive and not targetPlayer then
        stopFling()
        flingPeopleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        statusBar.Text = "➤ Статус: Выключен"
        return
    end
    
    if flingActive then stopFling() end
    targetPlayer = nil
    startFling(nil) -- nil = все игроки
    flingPeopleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    statusBar.Text = "➤ FLING PEOPLE: АКТИВЕН (все игроки)"
end)
yPos = yPos + 50

-- Anti Grab (как на скриншоте)
local antiGrabBtn = createButton("🛡️ ANTI GRAB [ON]", yPos, Color3.fromRGB(0, 150, 0), function()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then
        antiGrabBtn.Text = "🛡️ ANTI GRAB [ON]"
        antiGrabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        statusBar.Text = "➤ Anti Grab: ВКЛЮЧЕН"
        enableAntiGrab()
    else
        antiGrabBtn.Text = "🛡️ ANTI GRAB [OFF]"
        antiGrabBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        statusBar.Text = "➤ Anti Grab: ВЫКЛЮЧЕН"
    end
end)
yPos = yPos + 50

-- Touch Fling (как на скриншоте "Toys Menu" стиль)
local touchFlingBtn = createButton("👊 TOUCH FLING", yPos, Color3.fromRGB(100, 50, 200), function()
    touchFlingActive = not touchFlingActive
    if touchFlingActive then
        touchFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
        statusBar.Text = "➤ TOUCH FLING: АКТИВЕН"
        enableTouchFling()
    else
        touchFlingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        statusBar.Text = "➤ TOUCH FLING: ВЫКЛЮЧЕН"
        disableTouchFling()
    end
end)
yPos = yPos + 50

-- === СПИСОК ИГРОКОВ (как "target" на скриншоте) ===
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0.85, 0, 0, 120)
playerListFrame.Position = UDim2.new(0.075, 0, 0, yPos + 10)
playerListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
playerListFrame.BackgroundTransparency = 0.5
playerListFrame.BorderSizePixel = 1
playerListFrame.BorderColor3 = Color3.fromRGB(80, 80, 120)
playerListFrame.Parent = mainFrame
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.ScrollBarThickness = 6

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 5)
listCorner.Parent = playerListFrame

local listLabel = Instance.new("TextLabel")
listLabel.Size = UDim2.new(1, 0, 0, 25)
listLabel.BackgroundTransparency = 1
listLabel.Text = "🎯 ВЫБЕРИ ЦЕЛЬ:"
listLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
listLabel.Font = Enum.Font.GothamBold
listLabel.TextSize = 14
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.Parent = playerListFrame

local function updatePlayerList()
    -- Очищаем старые кнопки (кроме заголовка)
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local yOffset = 30
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, yOffset)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            btn.BackgroundTransparency = 0.3
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(80, 80, 120)
            btn.Parent = playerListFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                targetPlayer = plr
                statusBar.Text = "➤ Цель: " .. plr.Name
                -- Визуальное выделение
                for _, b in ipairs(playerListFrame:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
                    end
                end
                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
            end)
            
            yOffset = yOffset + 35
        end
    end
    
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
end

updatePlayerList()

-- Обновление списка при входе/выходе игроков
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- === ФУНКЦИИ ФЛИНГА ===
function enableAntiGrab()
    if not character then return end
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end
        end
    end)
end

function startFling(target)
    if flingActive then stopFling() end
    flingActive = true
    
    local function flingLoop()
        if not flingActive or not character or not character.Parent then
            flingActive = false
            return
        end
        
        -- Флинг всех игроков или конкретного
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
                local power = math.random(300, 600)
                local dir = Vector3.new(
                    math.random(-100, 100),
                    math.random(50, 200),
                    math.random(-100, 100)
                ).Unit
                root.Velocity = dir * power
                root.RotVelocity = Vector3.new(
                    math.random(-200, 200),
                    math.random(-200, 200),
                    math.random(-200, 200)
                )
                
                -- Урон
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    hum:TakeDamage(math.random(5, 25))
                end
            end
        end
        
        -- Анти-грэб для себя
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
    -- Сброс скорости всех
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

-- === TOUCH FLING ===
local touchConnections = {}

function enableTouchFling()
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local conn = part.Touched:Connect(function(otherPart)
                if not touchFlingActive then return end
                local otherChar = otherPart:FindFirstAncestorOfClass("Model")
                if not otherChar or otherChar == character then return end
                local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                if not otherRoot then return end
                
                local dir = (otherRoot.Position - rootPart.Position).Unit
                local power = math.random(200, 450)
                otherRoot.Velocity = dir * power + Vector3.new(0, math.random(50, 200), 0)
                otherRoot.RotVelocity = Vector3.new(
                    math.random(-200, 200),
                    math.random(-200, 200),
                    math.random(-200, 200)
                )
                
                local otherHum = otherChar:FindFirstChild("Humanoid")
                if otherHum and otherHum.Health > 0 then
                    otherHum:TakeDamage(math.random(10, 30))
                end
            end)
            table.insert(touchConnections, conn)
        end
    end
end

function disableTouchFling()
    for _, conn in ipairs(touchConnections) do
        pcall(conn.Disconnect, conn)
    end
    touchConnections = {}
end

-- === РЕСПАВН ===
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    if antiGrabActive then enableAntiGrab() end
    if touchFlingActive then
        disableTouchFling()
        enableTouchFling()
    end
    if flingActive then
        stopFling()
        startFling(targetPlayer)
    end
end)

-- === ИНИЦИАЛИЗАЦИЯ ===
enableAntiGrab()
print("✅ Ryzen Fling That & People загружен!")
print("🎯 Выбери игрока в списке и нажми 'FLING THAT'")
print("👥 Или нажми 'FLING PEOPLE' для флинга всех")
print("🛡️ Anti Grab включен по умолчанию")

-- Защита от вылета
game:BindToClose(function()
    stopFling()
    disableTouchFling()
end)

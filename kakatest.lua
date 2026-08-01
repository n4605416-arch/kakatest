-- gakuka(govno) v1.0 alpha beta beta super beta
-- Специально для Fling Things and People
-- БЕЗ ПОЛЁТА! Только проверенные функции
-- https://www.roblox.com/games/6961824067

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Состояния режимов
local flingActive = false
local grabFTAPActive = false
local freezeGrabActive = false
local antiGrabActive = true

-- Хранилища
local flingConnections = {}
local frozenObjects = {}
local screenGui = nil
local mainFrame = nil
local guiVisible = true

-- ============================================
-- === 1. FLING ALL (только другие игроки) ===
-- ============================================
local function startFling()
    if flingActive then return end
    flingActive = true
    
    local function flingLoop()
        if not flingActive or not character or not character.Parent then
            flingActive = false
            return
        end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    local power = math.random(400, 800)
                    local dir = Vector3.new(
                        math.random(-100, 100),
                        math.random(80, 300),
                        math.random(-100, 100)
                    ).Unit
                    root.Velocity = dir * power
                    root.RotVelocity = Vector3.new(
                        math.random(-400, 400),
                        math.random(-400, 400),
                        math.random(-400, 400)
                    )
                end
            end
        end
    end
    
    local conn = RunService.Heartbeat:Connect(flingLoop)
    table.insert(flingConnections, conn)
    print("[Fling] ВКЛЮЧЕН")
end

local function stopFling()
    flingActive = false
    for _, conn in ipairs(flingConnections) do
        pcall(conn.Disconnect, conn)
    end
    flingConnections = {}
    
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

-- ============================================
-- === 2. GRAB FTAP (кидание игроков) ===
-- ============================================
local function onGrabbed(otherPart)
    if not grabFTAPActive then return end
    if not character or not character.Parent then return end
    
    local otherCharacter = otherPart:FindFirstAncestorOfClass("Model")
    if not otherCharacter or otherCharacter == character then return end
    
    local otherHumanoid = otherCharacter:FindFirstChild("Humanoid")
    local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
    if not otherHumanoid or not otherRoot then return end
    
    if otherHumanoid:GetState() ~= Enum.HumanoidStateType.Grabbed then return end
    
    -- СУПЕР КИДОК
    local power = math.random(600, 1500)
    local direction = Vector3.new(
        math.random(-150, 150),
        math.random(150, 500),
        math.random(-150, 150)
    ).Unit
    
    otherRoot.Velocity = direction * power
    otherRoot.RotVelocity = Vector3.new(
        math.random(-600, 600),
        math.random(-600, 600),
        math.random(-600, 600)
    )
    
    pcall(function()
        otherHumanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
        task.wait(0.1)
        otherHumanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, true)
    end)
end

local function setupGrabFTAP()
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(onGrabbed)
        end
    end
end

-- ============================================
-- === 3. FREEZE GRAB (заморозка предметов) ===
-- ============================================
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

local function startFreezeGrab()
    if not character then return end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") or tool:IsA("BasePart") then
            if tool:FindFirstChild("Handle") then
                local handle = tool.Handle
                if handle and handle:IsA("BasePart") and not frozenObjects[handle] then
                    freezeObject(handle)
                end
            else
                if tool:IsA("BasePart") and not frozenObjects[tool] then
                    freezeObject(tool)
                end
            end
        end
    end
end

-- ============================================
-- === 4. ANTI-GRAB (защита от захвата) ===
-- ============================================
local antiGrabConnections = {}

local function enableAntiGrab()
    if not character then return end
    
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            humanoid.AutoRotate = false
        end
    end)
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = true
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end)
        end
    end
    
    if rootPart then
        pcall(function()
            rootPart.CanCollide = true
            rootPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        end)
    end
    
    if #antiGrabConnections == 0 then
        local loop = RunService.Heartbeat:Connect(function()
            if not antiGrabActive then return end
            if not character or not character.Parent then return end
            pcall(function()
                if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Grabbed then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
                if rootPart and rootPart.Velocity.Magnitude > 5 then
                    rootPart.Velocity = rootPart.Velocity * 0.95
                end
            end)
        end)
        table.insert(antiGrabConnections, loop)
    end
    
    print("[Anti-Grab] ВКЛЮЧЕН")
end

local function disableAntiGrab()
    antiGrabActive = false
    
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Grabbed, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end)
    
    for _, conn in ipairs(antiGrabConnections) do
        pcall(conn.Disconnect, conn)
    end
    antiGrabConnections = {}
    print("[Anti-Grab] ВЫКЛЮЧЕН")
end

-- ============================================
-- === ОБЩИЕ ФУНКЦИИ ===
-- ============================================
local function stopAll()
    stopFling()
    grabFTAPActive = false
    freezeGrabActive = false
    clearFrozen()
    print("[Все] ОСТАНОВЛЕНО")
end

-- ============================================
-- === GUI МЕНЮ ===
-- ============================================
local function createGUI()
    if screenGui then screenGui:Destroy() end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -225)
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
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
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
    titleText.Text = "💀 gakuka FTAP"
    titleText.TextColor3 = Color3.fromRGB(255, 50, 200)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local verText = Instance.new("TextLabel")
    verText.Size = UDim2.new(1, -70, 0, 20)
    verText.Position = UDim2.new(0, 10, 0, 26)
    verText.BackgroundTransparency = 1
    verText.Text = "v1.0 alpha beta beta super beta"
    verText.TextColor3 = Color3.fromRGB(200, 100, 200)
    verText.Font = Enum.Font.Gotham
    verText.TextSize = 11
    verText.TextXAlignment = Enum.TextXAlignment.Left
    verText.Parent = titleBar
    
    -- Свернуть
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 35, 0, 35)
    toggleBtn.Position = UDim2.new(1, -75, 0, 8)
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
            mainFrame.Size = UDim2.new(0, 400, 0, 450)
            toggleBtn.Text = "−"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        else
            mainFrame.Size = UDim2.new(0, 400, 0, 50)
            toggleBtn.Text = "+"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        end
    end)
    
    -- Закрыть
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 8)
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
        stopAll()
        screenGui:Destroy()
    end)
    
    -- Статус
    local statusBar = Instance.new("TextLabel")
    statusBar.Size = UDim2.new(0.9, 0, 0, 28)
    statusBar.Position = UDim2.new(0.05, 0, 0.14, 0)
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
    
    -- ===== КНОПКИ =====
    local yPos = 0.20
    
    -- 1. FLING ALL
    local flingBtn = Instance.new("TextButton")
    flingBtn.Size = UDim2.new(0.85, 0, 0, 42)
    flingBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    flingBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    flingBtn.BackgroundTransparency = 0.3
    flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
    flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flingBtn.Font = Enum.Font.GothamBold
    flingBtn.TextSize = 16
    flingBtn.BorderSizePixel = 2
    flingBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
    flingBtn.Parent = mainFrame
    
    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 8)
    btnCorner1.Parent = flingBtn
    
    yPos = yPos + 0.12
    
    -- 2. GRAB FTAP
    local grabBtn = Instance.new("TextButton")
    grabBtn.Size = UDim2.new(0.85, 0, 0, 42)
    grabBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    grabBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    grabBtn.BackgroundTransparency = 0.3
    grabBtn.Text = "🤜 GRAB FTAP [ВЫКЛ]"
    grabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    grabBtn.Font = Enum.Font.GothamBold
    grabBtn.TextSize = 16
    grabBtn.BorderSizePixel = 2
    grabBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
    grabBtn.Parent = mainFrame
    
    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 8)
    btnCorner2.Parent = grabBtn
    
    yPos = yPos + 0.12
    
    -- 3. FREEZE GRAB
    local freezeBtn = Instance.new("TextButton")
    freezeBtn.Size = UDim2.new(0.85, 0, 0, 42)
    freezeBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    freezeBtn.BackgroundTransparency = 0.3
    freezeBtn.Text = "❄️ FREEZE GRAB [ВЫКЛ]"
    freezeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    freezeBtn.Font = Enum.Font.GothamBold
    freezeBtn.TextSize = 16
    freezeBtn.BorderSizePixel = 2
    freezeBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
    freezeBtn.Parent = mainFrame
    
    local btnCorner3 = Instance.new("UICorner")
    btnCorner3.CornerRadius = UDim.new(0, 8)
    btnCorner3.Parent = freezeBtn
    
    yPos = yPos + 0.12
    
    -- 4. ANTI-GRAB
    local antiBtn = Instance.new("TextButton")
    antiBtn.Size = UDim2.new(0.85, 0, 0, 42)
    antiBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    antiBtn.BackgroundTransparency = 0.3
    antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
    antiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiBtn.Font = Enum.Font.GothamBold
    antiBtn.TextSize = 16
    antiBtn.BorderSizePixel = 2
    antiBtn.BorderColor3 = Color3.fromRGB(0, 200, 0)
    antiBtn.Parent = mainFrame
    
    local btnCorner4 = Instance.new("UICorner")
    btnCorner4.CornerRadius = UDim.new(0, 8)
    btnCorner4.Parent = antiBtn
    
    yPos = yPos + 0.12
    
    -- 5. CLEAR FROZEN
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0.85, 0, 0, 35)
    clearBtn.Position = UDim2.new(0.075, 0, yPos, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    clearBtn.BackgroundTransparency = 0.3
    clearBtn.Text = "🧊 РАЗМОРОЗИТЬ ВСЁ"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 15
    clearBtn.BorderSizePixel = 2
    clearBtn.BorderColor3 = Color3.fromRGB(200, 150, 0)
    clearBtn.Parent = mainFrame
    
    local btnCorner5 = Instance.new("UICorner")
    btnCorner5.CornerRadius = UDim.new(0, 8)
    btnCorner5.Parent = clearBtn
    
    yPos = yPos + 0.10
    
    -- 6. STOP ALL
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0.85, 0, 0, 40)
    stopBtn.Position = UDim2.new(0.075, 0, yPos + 0.01, 0)
    stopBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 30)
    stopBtn.BackgroundTransparency = 0.2
    stopBtn.Text = "⛔ ОСТАНОВИТЬ ВСЁ"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 17
    stopBtn.BorderSizePixel = 2
    stopBtn.BorderColor3 = Color3.fromRGB(200, 0, 50)
    stopBtn.Parent = mainFrame
    
    local btnCorner6 = Instance.new("UICorner")
    btnCorner6.CornerRadius = UDim.new(0, 8)
    btnCorner6.Parent = stopBtn
    
    -- ===== ЛОГИКА КНОПОК =====
    local function updateButtons()
        if flingActive then
            flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
            flingBtn.BorderColor3 = Color3.fromRGB(0, 255, 80)
            flingBtn.Text = "💥 FLING ALL [ВКЛ]"
        else
            flingBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            flingBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
            flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
        end
        
        if grabFTAPActive then
            grabBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
            grabBtn.BorderColor3 = Color3.fromRGB(0, 255, 80)
            grabBtn.Text = "🤜 GRAB FTAP [ВКЛ]"
        else
            grabBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            grabBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
            grabBtn.Text = "🤜 GRAB FTAP [ВЫКЛ]"
        end
        
        if freezeGrabActive then
            freezeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
            freezeBtn.BorderColor3 = Color3.fromRGB(0, 255, 255)
            freezeBtn.Text = "❄️ FREEZE GRAB [ВКЛ]"
        else
            freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            freezeBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
            freezeBtn.Text = "❄️ FREEZE GRAB [ВЫКЛ]"
        end
        
        if antiGrabActive then
            antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            antiBtn.BorderColor3 = Color3.fromRGB(0, 255, 0)
            antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
        else
            antiBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            antiBtn.BorderColor3 = Color3.fromRGB(200, 0, 0)
            antiBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
        end
    end
    
    -- FLING ALL
    flingBtn.MouseButton1Click:Connect(function()
        if flingActive then
            stopFling()
            statusBar.Text = "✅ FLING ALL ВЫКЛЮЧЕН"
            statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
        else
            if grabFTAPActive then grabFTAPActive = false end
            if freezeGrabActive then 
                freezeGrabActive = false
                clearFrozen()
            end
            startFling()
            statusBar.Text = "💥 FLING ALL АКТИВЕН! (ты не летаешь)"
            statusBar.TextColor3 = Color3.fromRGB(0, 255, 100)
        end
        updateButtons()
    end)
    
    -- GRAB FTAP
    grabBtn.MouseButton1Click:Connect(function()
        grabFTAPActive = not grabFTAPActive
        if grabFTAPActive then
            if flingActive then stopFling() end
            if freezeGrabActive then 
                freezeGrabActive = false
                clearFrozen()
            end
            setupGrabFTAP()
            statusBar.Text = "🤜 GRAB FTAP АКТИВЕН! (бери игроков)"
            statusBar.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            statusBar.Text = "✅ GRAB FTAP ВЫКЛЮЧЕН"
            statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        updateButtons()
    end)
    
    -- FREEZE GRAB
    freezeBtn.MouseButton1Click:Connect(function()
        freezeGrabActive = not freezeGrabActive
        if freezeGrabActive then
            if flingActive then stopFling() end
            if grabFTAPActive then grabFTAPActive = false end
            statusBar.Text = "❄️ FREEZE GRAB АКТИВЕН! (бери предметы)"
            statusBar.TextColor3 = Color3.fromRGB(0, 200, 255)
            startFreezeGrab()
        else
            clearFrozen()
            statusBar.Text = "✅ FREEZE GRAB ВЫКЛЮЧЕН"
            statusBar.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        updateButtons()
    end)
    
    -- ANTI-GRAB
    antiBtn.MouseButton1Click:Connect(function()
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
    
    -- CLEAR FROZEN
    clearBtn.MouseButton1Click:Connect(function()
        local count = 0
        for _ in pairs(frozenObjects) do count = count + 1 end
        clearFrozen()
        statusBar.Text = "🧊 Разморожено: " .. count .. " предметов"
        statusBar.TextColor3 = Color3.fromRGB(255, 200, 0)
    end)
    
    -- STOP ALL
    stopBtn.MouseButton1Click:Connect(function()
        stopAll()
        statusBar.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        statusBar.TextColor3 = Color3.fromRGB(255, 100, 100)
        updateButtons()
    end)
    
    updateButtons()
    return screenGui
end

-- ============================================
-- === РЕСПАВН ===
-- ============================================
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
    if grabFTAPActive then setupGrabFTAP() end
    if freezeGrabActive then startFreezeGrab() end
end)

-- ============================================
-- === ЗАПУСК ===
-- ============================================
createGUI()
enableAntiGrab()

print("============================================")
print("  💀 gakuka(govno) FTAP")
print("  v1.0 alpha beta beta super beta")
print("  ==========================================")
print("  1. FLING ALL - все летают (кроме тебя)")
print("  2. GRAB FTAP - кидай игроков при взятии")
print("  3. FREEZE GRAB - морозь предметы при взятии")
print("  4. ANTI-GRAB - защита от захвата")
print("  ==========================================")
print("  ❌ ТЫ НЕ ЛЕТАЕШЬ НИ В ОДНОМ РЕЖИМЕ")
print("  🎮 Игра: Fling Things and People")
print("============================================")

game:BindToClose(function()
    stopAll()
    disableAntiGrab()
end)

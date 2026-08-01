-- ========================================
-- === ANTI-GRAB (БЕЗ БЛОКИРОВКИ ДВИЖЕНИЯ) ===
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
                    -- 1. ВЫРЫВАЕМСЯ ЧЕРЕЗ СТАНДАРТНУЮ МЕХАНИКУ FTAP
                    local struggle = ReplicatedStorage:FindFirstChild("CharacterEvents")
                    if struggle then
                        local struggleEvent = struggle:FindFirstChild("Struggle")
                        if struggleEvent then struggleEvent:FireServer() end
                    end
                    
                    -- 2. ОСТАНАВЛИВАЕМ ВСЮ СКОРОСТЬ (ЧТОБЫ НЕ УЛЕТЕТЬ)
                    local correction = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
                    if correction then
                        local stopVelocity = correction:FindFirstChild("StopAllVelocity")
                        if stopVelocity then stopVelocity:FireServer() end
                    end
                    
                    -- 3. СБРАСЫВАЕМ СКОРОСТЬ СЕБЯ (ЕСЛИ НУЖНО)
                    if rootPart then
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.RotVelocity = Vector3.new(0, 0, 0)
                    end
                    
                    -- 4. ПРИНУДИТЕЛЬНО ПЕРЕКЛЮЧАЕМ СОСТОЯНИЕ НА RUNNING (ЧТОБЫ НЕ ВИСЕТЬ В GRABBED)
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    
                    -- 5. УДАЛЯЕМ PART OWNER (ЧТОБЫ НЕ ЗАЦИКЛИТЬСЯ)
                    partOwner:Destroy()
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

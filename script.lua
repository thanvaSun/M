-- Rayfield UI Library Loader
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services & Variables
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- Config File Name
local configFileName = "ThanvaScriptConfig.json"

-- States & Configurations
local aimlockEnabled = false
local autoWarpEnabled = false
local shiftLockActive = false
local selectedTargetOption = "[คนใกล้ที่สุด / Closest]"

local walkSpeedValue = 16
local walkSpeedEnabled = false
local jumpPowerValue = 50
local jumpPowerEnabled = false
local infiniteJumpEnabled = false
local noclipEnabled = false
local invisibleEnabled = false

local flyEnabled = false
local flySpeedValue = 50
local flyBv, flyBg

-- References for UI Toggles & Buttons Table
local aimlockUIToggle, shiftLockUIToggle, speedUIToggle, jumpUIToggle, infJumpUIToggle, flyUIToggle, noclipUIToggle, invisUIToggle
local showAimlockToggle, showShiftLockToggle, showLeaveToggle, showCopyToggle, showSpeedToggle, showJumpToggle, showInfJumpToggle, showFlyToggle, showNoclipToggle, showInvisToggle

local buttonsTable = {}

-- HELPER: CREATE DRAGGABLE MOBILE SHORTCUT BUTTON
local function createMobileButton(name, text, defaultPos, onClick)
    if playerGui:FindFirstChild(name .. "Gui") then
        playerGui[name .. "Gui"]:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = name .. "Gui"
    sg.ResetOnSpawn = false
    sg.Enabled = false
    sg.Parent = playerGui

    local btn = Instance.new("TextButton")
    btn.Name = name .. "Button"
    btn.Size = UDim2.new(0, 46, 0, 46)
    btn.Position = defaultPos
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Parent = sg

    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(180, 180, 180)
    stroke.Thickness = 2

    local dragging = false
    local dragStart, startPos
    local startInputPos = Vector2.new(0, 0)
    local dragDistance = 0

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            startInputPos = Vector2.new(input.Position.X, input.Position.Y)
            dragDistance = 0
        end
    end)

    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            dragDistance = (Vector2.new(input.Position.X, input.Position.Y) - startInputPos).Magnitude
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if dragDistance < 10 then
                onClick(btn, stroke)
            end
        end
    end)

    buttonsTable[name] = { sg = sg, btn = btn, stroke = stroke, defaultPos = defaultPos }
    return sg, btn, stroke
end

-- CREATE ALL MOBILE SHORTCUT BUTTONS
local aimlockGui, aimlockBtn, aimlockStroke = createMobileButton("AimlockBtn", "👁️", UDim2.new(0.85, -25, 0.20, 0), function(btn, stroke)
    aimlockEnabled = not aimlockEnabled
    if aimlockUIToggle then aimlockUIToggle:Set(aimlockEnabled) end
    btn.BackgroundColor3 = aimlockEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)
end)

local shiftGui, shiftBtn, shiftStroke = createMobileButton("ShiftLockBtn", "🎯", UDim2.new(0.85, -25, 0.28, 0), function(btn, stroke)
    shiftLockActive = not shiftLockActive
    if shiftLockUIToggle then shiftLockUIToggle:Set(shiftLockActive) end
    if shiftLockActive then
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    else
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.AutoRotate = true
        end
    end
end)
shiftBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local leaveClickCount = 0
local lastLeaveClick = 0
local leaveGui, leaveBtn, leaveStroke = createMobileButton("LeaveBtn", "🚪", UDim2.new(0.85, -25, 0.36, 0), function(btn, stroke)
    local now = tick()
    if now - lastLeaveClick > 10 then leaveClickCount = 0 end
    lastLeaveClick = now
    leaveClickCount = leaveClickCount + 1

    if leaveClickCount < 3 then
        btn.Text = "(" .. leaveClickCount .. "/3)"
        Rayfield:Notify({
            Title = "🚪 ออกจากแมพ",
            Content = "กดอีก " .. (3 - leaveClickCount) .. " ครั้งเพื่อออกจากแมพ (รีเซ็ตใน 10 วิ)",
            Duration = 1.5,
            Image = 4483362458,
        })
        task.delay(10, function()
            if tick() - lastLeaveClick >= 10 then
                leaveClickCount = 0
                btn.Text = "🚪"
            end
        end)
    else
        player:Kick("ออกจากแมพเรียบร้อยแล้ว")
    end
end)
leaveBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)

local copyTargetOutfitAndBody

local copyGui, copyBtn, copyStroke = createMobileButton("CopyOutfitBtn", "👕", UDim2.new(0.85, -25, 0.44, 0), function(btn, stroke)
    if copyTargetOutfitAndBody then copyTargetOutfitAndBody() end
end)

local speedGui, speedBtn, speedStroke = createMobileButton("SpeedBtn", "⚡", UDim2.new(0.85, -25, 0.52, 0), function(btn, stroke)
    walkSpeedEnabled = not walkSpeedEnabled
    if speedUIToggle then speedUIToggle:Set(walkSpeedEnabled) end
    btn.BackgroundColor3 = walkSpeedEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)
    if not walkSpeedEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = 16
    end
end)

local jumpGui, jumpBtn, jumpStroke = createMobileButton("JumpBtn", "🦘", UDim2.new(0.85, -25, 0.60, 0), function(btn, stroke)
    jumpPowerEnabled = not jumpPowerEnabled
    if jumpUIToggle then jumpUIToggle:Set(jumpPowerEnabled) end
    btn.BackgroundColor3 = jumpPowerEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)
    if not jumpPowerEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.UseJumpPower = true
        player.Character.Humanoid.JumpPower = 50
    end
end)

local infJumpGui, infJumpBtn, infJumpStroke = createMobileButton("InfJumpBtn", "♾️", UDim2.new(0.85, -25, 0.68, 0), function(btn, stroke)
    infiniteJumpEnabled = not infiniteJumpEnabled
    if infJumpUIToggle then infJumpUIToggle:Set(infiniteJumpEnabled) end
    btn.BackgroundColor3 = infiniteJumpEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)
end)

local function updateFlyState(state)
    flyEnabled = state
    if flyUIToggle and flyUIToggle.CurrentValue ~= flyEnabled then flyUIToggle:Set(flyEnabled) end
    flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)

    if flyEnabled then
        local myChar = player.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local hrp = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = true end

            if hrp:FindFirstChild("FlyBV") then hrp.FlyBV:Destroy() end
            if hrp:FindFirstChild("FlyBG") then hrp.FlyBG:Destroy() end

            flyBv = Instance.new("BodyVelocity")
            flyBv.Name = "FlyBV"
            flyBv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBv.Velocity = Vector3.zero
            flyBv.Parent = hrp

            flyBg = Instance.new("BodyGyro")
            flyBg.Name = "FlyBG"
            flyBg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBg.P = 9e4
            flyBg.CFrame = hrp.CFrame
            flyBg.Parent = hrp
        end
    else
        if flyBv then flyBv:Destroy() flyBv = nil end
        if flyBg then flyBg:Destroy() flyBg = nil end
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            if hrp:FindFirstChild("FlyBV") then hrp.FlyBV:Destroy() end
            if hrp:FindFirstChild("FlyBG") then hrp.FlyBG:Destroy() end
        end
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.PlatformStand = false
        end
    end
end

local flyGui, flyBtn, flyStroke = createMobileButton("FlyBtn", "✈️", UDim2.new(0.85, -25, 0.76, 0), function(btn, stroke)
    updateFlyState(not flyEnabled)
end)

local noclipGui, noclipBtn, noclipStroke = createMobileButton("NoclipBtn", "🧱", UDim2.new(0.15, 0, 0.55, 0), function(btn, stroke)
    noclipEnabled = not noclipEnabled
    if noclipUIToggle then noclipUIToggle:Set(noclipEnabled) end
    btn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)
end)

local invisGui, invisBtn, invisStroke = createMobileButton("InvisBtn", "👻", UDim2.new(0.15, 0, 0.63, 0), function(btn, stroke)
    invisibleEnabled = not invisibleEnabled
    if invisUIToggle then invisUIToggle:Set(invisibleEnabled) end
    btn.BackgroundColor3 = invisibleEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)

    if player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                if invisibleEnabled then
                    part.Transparency = 1
                else
                    if part.Name ~= "HumanoidRootPart" then
                        part.Transparency = 0
                    end
                end
            end
        end
    end
end)

-- RAYFIELD WINDOW SETUP
local Window = Rayfield:CreateWindow({
   Name = "Rayfield Interface",
   LoadingTitle = "กำลังโหลด...",
   LoadingSubtitle = "ระบบล็อคเป้า & เคลื่อนที่ & บิน & FPS",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

-- TAB 1: COMBAT & TARGET
local MainTab = Window:CreateTab("Combat & Target", 4483362458)

local targetLabel = MainTab:CreateLabel("🎯 เป้าหมาย: ไม่พบผู้เล่นใกล้เคียง")

local function getPlayerNames()
    local list = {"[คนใกล้ที่สุด / Closest]"}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(list, plr.DisplayName .. " (@" .. plr.Name .. ")")
        end
    end
    return list
end

local PlayerDropdown = MainTab:CreateDropdown({
   Name = "เลือกคนที่จะล็อค / วาร์ป / ก๊อปชุด",
   Options = getPlayerNames(),
   CurrentOption = {"[คนใกล้ที่สุด / Closest]"},
   MultipleOptions = false,
   Flag = "TargetDropdown",
   Callback = function(Option)
       if type(Option) == "table" then
           selectedTargetOption = Option[1] or "[คนใกล้ที่สุด / Closest]"
       else
           selectedTargetOption = Option
       end
   end,
})

MainTab:CreateButton({
   Name = "🔄 อัปเดตรายชื่อคนในเซิร์ฟ",
   Callback = function()
       PlayerDropdown:Refresh(getPlayerNames())
   end,
})

aimlockUIToggle = MainTab:CreateToggle({
   Name = "Aimlock (ล็อคกล้องหาเป้าหมาย)",
   CurrentValue = false,
   Flag = "AimlockToggle",
   Callback = function(Value)
       aimlockEnabled = Value
       aimlockBtn.BackgroundColor3 = aimlockEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)
   end,
})

showAimlockToggle = MainTab:CreateToggle({
   Name = "แสดงปุ่มลัด Aimlock บนหน้าจอ (👁️)",
   CurrentValue = false,
   Flag = "ShowAimlockBtnToggle",
   Callback = function(Value)
       aimlockGui.Enabled = Value
   end,
})

shiftLockUIToggle = MainTab:CreateToggle({
   Name = "Shift Lock (เปิด/ปิด ชิฟต์ล็อค)",
   CurrentValue = false,
   Flag = "ShiftLockToggle",
   Callback = function(Value)
       shiftLockActive = Value
       if shiftLockActive then
           shiftBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
       else
           shiftBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
           if player.Character and player.Character:FindFirstChild("Humanoid") then
               player.Character.Humanoid.AutoRotate = true
           end
       end
   end,
})

showShiftLockToggle = MainTab:CreateToggle({
   Name = "แสดงปุ่มลัด Shift Lock บนหน้าจอ (🎯)",
   CurrentValue = false,
   Flag = "ShowShiftLockBtnToggle",
   Callback = function(Value)
       shiftGui.Enabled = Value
   end,
})

showLeaveToggle = MainTab:CreateToggle({
   Name = "แสดงปุ่มลัดออกจากแมพ บนหน้าจอ (🚪)",
   CurrentValue = false,
   Flag = "ShowLeaveBtnToggle",
   Callback = function(Value)
       leaveGui.Enabled = Value
   end,
})

local function getCurrentTargetChar()
    if selectedTargetOption == "[คนใกล้ที่สุด / Closest]" or not selectedTargetOption then
        local closest = nil
        local shortestDist = math.huge
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil, 0 end
        local myPos = player.Character.HumanoidRootPart.Position

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                if plr.Character.Humanoid.Health > 0 then
                    local dist = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = plr.Character
                    end
                end
            end
        end
        return closest, shortestDist
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            local fullName = plr.DisplayName .. " (@" .. plr.Name .. ")"
            if fullName == selectedTargetOption or plr.Name == selectedTargetOption then
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                    local dist = 0
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        dist = (plr.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    end
                    return plr.Character, dist
                end
            end
        end
    end
    return nil, 0
end

copyTargetOutfitAndBody = function()
    local targetChar, _ = getCurrentTargetChar()
    if not targetChar then
        Rayfield:Notify({
            Title = "Copy Outfit",
            Content = "ไม่พบเป้าหมายที่เลือก!",
            Duration = 2,
            Image = 4483362458,
        })
        return
    end

    local targetPlr = Players:GetPlayerFromCharacter(targetChar)
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("Humanoid") then return end

    for _, item in ipairs(myChar:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
            item:Destroy()
        end
    end

    local myHead = myChar:FindFirstChild("Head")
    if myHead then
        for _, dec in ipairs(myHead:GetChildren()) do
            if dec:IsA("Decal") then dec:Destroy() end
        end
    end

    local appliedSuccess = false

    if targetPlr then
        pcall(function()
            local humDesc = Players:GetHumanoidDescriptionFromUserId(targetPlr.UserId)
            if humDesc then
                myChar.Humanoid:ApplyDescription(humDesc)
                appliedSuccess = true
            end
        end)
    end

    if not appliedSuccess then
        for _, item in ipairs(targetChar:GetChildren()) do
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
                local clone = item:Clone()
                clone.Parent = myChar
            elseif item:IsA("Accessory") or item:IsA("Hat") then
                local accClone = item:Clone()
                for _, sc in ipairs(accClone:GetDescendants()) do
                    if sc:IsA("LuaSourceContainer") then sc:Destroy() end
                end
                myChar.Humanoid:AddAccessory(accClone)
            end
        end

        local targetHead = targetChar:FindFirstChild("Head")
        if targetHead and myHead then
            for _, dec in ipairs(targetHead:GetChildren()) do
                if dec:IsA("Decal") then
                    local newDec = dec:Clone()
                    newDec.Parent = myHead
                end
            end
        end
    end

    Rayfield:Notify({
        Title = "Copy Outfit",
        Content = "ก๊อปปี้ชุดและทรงผมเป้าหมายเรียบร้อยแล้ว!",
        Duration = 2,
        Image = 4483362458,
    })
end

MainTab:CreateButton({
   Name = "👕 ก๊อปปี้ชุดและทรงผมเป้าหมาย (Copy Full Outfit)",
   Callback = function()
       copyTargetOutfitAndBody()
   end,
})

showCopyToggle = MainTab:CreateToggle({
   Name = "แสดงปุ่มลัด ก๊อปปี้ชุด บนหน้าจอ (👕)",
   CurrentValue = false,
   Flag = "ShowCopyBtnToggle",
   Callback = function(Value)
       copyGui.Enabled = Value
   end,
})

MainTab:CreateButton({
   Name = "Warp to Target (วาร์ปไปหาเป้าหมาย 1 ครั้ง)",
   Callback = function()
       local target = getCurrentTargetChar()
       if target and target:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
           player.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
       else
           Rayfield:Notify({
               Title = "Warp Target",
               Content = "ไม่พบเป้าหมายที่เลือก!",
               Duration = 2,
               Image = 4483362458,
           })
       end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Warp / Stick (วาร์ปสิงติดหลังออโต้)",
   CurrentValue = false,
   Flag = "AutoWarpToggle",
   Callback = function(Value)
       autoWarpEnabled = Value
   end,
})

MainTab:CreateButton({
   Name = "🚪 ออกจากแมพทันที (Leave Game)",
   Callback = function()
       player:Kick("ออกจากแมพเรียบร้อยแล้ว")
   end,
})

-- TAB 2: MOVEMENT & UTILITY
local MoveTab = Window:CreateTab("Movement & Player", 4483362458)

speedUIToggle = MoveTab:CreateToggle({
   Name = "เปิดใช้งาน วิ่งเร็ว (WalkSpeed)",
   CurrentValue = false,
   Flag = "SpeedToggle",
   Callback = function(Value)
       walkSpeedEnabled = Value
       speedBtn.BackgroundColor3 = walkSpeedEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(30, 30, 40)
       if not Value and player.Character and player.Character:FindFirstChild("Humanoid") then
           player.Character.Humanoid.WalkSpeed = 16
       end
   end,
})

MoveTab:CreateSlider({
   Name = "ปรับความเร็วการวิ่ง (WalkSpeed)",
   Range = {16, 500},
   Increment = 1,
   Suffix = " Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
       walkSpeedValue = Value
   end,
})

showSpeedToggle = MoveTab:CreateToggle({
   Name = "แสดงปุ่มลัด วิ่งเร็ว บนหน้าจอ (⚡)",
   CurrentValue = false

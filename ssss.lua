-- =================================================================
-- MY CUSTOM BLOX FRUITS HUB (Fixed Hitbox & Weapon Equip)
-- =================================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Blox Fruits | Custom Working Hub",
   LoadingTitle = "Đang khởi tạo Script...",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = { Enabled = false }
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

_G.AutoFarm = false
_G.PlayerESP = false
_G.FruitESP = false
_G.NpcESP = false

local ESP_Holder = {Players = {}, Fruits = {}, NPCs = {}}

-- 1. Hàm Bay Mượt
local function TweenTo(targetCFrame, speed)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - targetCFrame.Position).Magnitude
    local info = TweenInfo.new(distance / (speed or 300), Enum.EasingStyle.Linear)
    local tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart, info, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- 2. Tự Động Đánh Ngầm (Đã Fix lỗi bật/tắt Melee liên tục)
local function AutoAttack()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end

        -- Chỉ trang bị nếu tay đang RỖNG (chưa cầm món gì)
        if not character:FindFirstChildOfClass("Tool") then
            local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if tool then
                character.Humanoid:EquipTool(tool)
            end
        end

        -- Nhấp chuột đánh liên tục
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(50, 50))
    end)
end

-- Chống AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)

-- 3. ESP Core
local function CreateESP(object, text, color, folder)
    if not object or not (object:FindFirstChild("HumanoidRootPart") or object:IsA("BasePart")) then return end
    local targetPart = object:FindFirstChild("HumanoidRootPart") or object
    if targetPart:FindFirstChild("CustomESP") then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = "CustomESP"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.StudsOffset = Vector2.new(0, 3, 0)
    bill.Adornee = targetPart
    bill.Parent = targetPart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = bill

    table.insert(folder, bill)
end

local function ClearESP(folder)
    for _, item in pairs(folder) do
        if item and item.Parent then item:Destroy() end
    end
    table.clear(folder)
end

-- 4. Vòng Lặp Auto Farm (Đã nâng độ cao an toàn)
spawn(function()
    while task.wait(0.1) do
        if _G.AutoFarm then
            pcall(function()
                local level = LocalPlayer.Data.Level.Value
                local questName, questLvl, mobName, questCFrame

                if level >= 1 and level < 10 then
                    questName, questLvl, mobName = "BanditQuest1", 1, "Bandit"
                    questCFrame = CFrame.new(1059, 16, 1549)
                elseif level >= 10 and level < 15 then
                    questName, questLvl, mobName = "JungleQuest", 1, "Monkey"
                    questCFrame = CFrame.new(-1598, 36, 153)
                elseif level >= 15 and level < 30 then
                    questName, questLvl, mobName = "JungleQuest", 2, "Gorilla"
                    questCFrame = CFrame.new(-1598, 36, 153)
                else
                    questName, questLvl, mobName = "PirateQuest", 1, "Pirate"
                    questCFrame = CFrame.new(-1140, 4, 3828)
                end

                if not LocalPlayer.PlayerGui.Main.Quest.Visible then
                    TweenTo(questCFrame, 300)
                    if (LocalPlayer.Character.HumanoidRootPart.Position - questCFrame.Position).Magnitude < 15 then
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", questName, questLvl)
                    end
                else
                    local enemy = Workspace.Enemies:FindFirstChild(mobName)
                    if enemy and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                        -- Giữ khoảng cách cao 11 studs phía trên đầu quái để quái không đánh tới
                        LocalPlayer.Character.HumanoidRootPart.CFrame = enemy.HumanoidRootPart.CFrame * CFrame.new(0, 11, 0)
                        AutoAttack()
                    else
                        TweenTo(questCFrame * CFrame.new(0, 25, 0), 300)
                    end
                end
            end)
        end
    end
end)

-- 5. Vòng Lặp ESP
spawn(function()
    while task.wait(1) do
        if _G.PlayerESP then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    CreateESP(plr.Character, plr.Name, Color3.fromRGB(255, 50, 50), ESP_Holder.Players)
                end
            end
        end

        if _G.FruitESP then
            for _, item in pairs(Workspace:GetChildren()) do
                if item:IsA("Tool") or string.find(item.Name, "Fruit") then
                    CreateESP(item, item.Name, Color3.fromRGB(255, 215, 0), ESP_Holder.Fruits)
                end
            end
        end

        if _G.NpcESP then
            for _, npc in pairs(Workspace:GetChildren()) do
                if npc:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(npc) and not Workspace.Enemies:FindFirstChild(npc.Name) then
                    CreateESP(npc, npc.Name, Color3.fromRGB(50, 255, 50), ESP_Holder.NPCs)
                end
            end
        end
    end
end)

-- 6. Giao Diện Menu Rayfield
local FarmTab = Window:CreateTab("Auto Farm", 4483345998)
FarmTab:CreateToggle({
   Name = "Bật Auto Farm & Auto Đánh",
   CurrentValue = false,
   Callback = function(Value)
       _G.AutoFarm = Value
   end,
})

local VisualTab = Window:CreateTab("ESP System", 4483345998)
VisualTab:CreateToggle({
   Name = "ESP Người Chơi",
   CurrentValue = false,
   Callback = function(Value)
       _G.PlayerESP = Value
       if not Value then ClearESP(ESP_Holder.Players) end
   end,
})

VisualTab:CreateToggle({
   Name = "ESP Trái Ác Quỷ",
   CurrentValue = false,
   Callback = function(Value)
       _G.FruitESP = Value
       if not Value then ClearESP(ESP_Holder.Fruits) end
   end,
})

VisualTab:CreateToggle({
   Name = "ESP NPC",
   CurrentValue = false,
   Callback = function(Value)
       _G.NpcESP = Value
       if not Value then ClearESP(ESP_Holder.NPCs) end
   end,
})

Rayfield:Notify({
   Title = "Thành công!",
   Content = "Menu đã cập nhật khoảng cách an toàn và sửa lỗi đánh.",
   Duration = 4
})

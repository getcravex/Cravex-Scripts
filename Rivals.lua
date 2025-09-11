local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Rivals - Cravex Hub",
   Icon = 0,
   LoadingTitle = "Rivals",
   LoadingSubtitle = "Cravex Hub",
   ShowText = "Rivals - Cravex Hub",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "CravexHub",
      FileName = "Rivals"
   },
   Discord = {
      Enabled = false,
      Invite = "NPzzhqTMvq",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

local function toggleTableAttribute(attribute, value)
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal, attribute) then
            gcVal[attribute] = value
        end
    end
end

local RagebotTab = Window:CreateTab("Ragebot", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

local targetPlayer = nil
local isAutoShooting = false
local autoShootConnection = nil
local cameraConnection = nil
local knockCheck = true
local teamCheck = false
local isRagebotEnabled = false
local selectedHitpart = "Head" -- Default hitpart
local applyCooldownEnabled = false
local applySpreadEnabled = false
local applyRecoilEnabled = false
local recoilCompensation = 100 -- Default 100% (full recoil)
local spreadMultiplier = 100 -- Default 100% (full spread)
local fireRateChanger = 100 -- Default 100% (full cooldown)

local function isLobbyVisible()
    return player.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
end

local function isPlayerKnocked(p)
    if p.Character and p.Character:FindFirstChild("Humanoid") then
        local humanoid = p.Character.Humanoid
        return humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead
    end
    return true
end

local function isSameTeam(p)
    return p.Team == player.Team and player.Team ~= nil
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild(selectedHitpart) then
            local hitpart = p.Character[selectedHitpart]
            local hitpartPosition, onScreen = camera:WorldToViewportPoint(hitpart.Position)

            if onScreen then
                if (not knockCheck or not isPlayerKnocked(p)) and
                   (not teamCheck or not isSameTeam(p)) then
                    local screenPosition = Vector2.new(hitpartPosition.X, hitpartPosition.Y)
                    local distance = (screenPosition - mousePosition).Magnitude

                    if distance < shortestDistance then
                        closestPlayer = p
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function lockCameraToHitpart()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild(selectedHitpart) then
        local hitpart = targetPlayer.Character[selectedHitpart]
        local cameraPosition = camera.CFrame.Position
        camera.CFrame = CFrame.new(cameraPosition, hitpart.Position)
    end
end

local function autoShoot()
    if autoShootConnection then
        autoShootConnection:Disconnect()
    end
    autoShootConnection = RunService.Heartbeat:Connect(function()
        if isAutoShooting and not isLobbyVisible() and targetPlayer then
            mouse1click()
        elseif not targetPlayer then
            isAutoShooting = false
            if autoShootConnection then
                autoShootConnection:Disconnect()
            end
        end
    end)
end

local function startRagebot()
    if not isRagebotEnabled then return end
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = RunService.Heartbeat:Connect(function()
        if not isLobbyVisible() then
            targetPlayer = getClosestPlayerToMouse()
            if targetPlayer then
                lockCameraToHitpart()
                if not isAutoShooting then
                    isAutoShooting = true
                    autoShoot()
                end
            else
                isAutoShooting = false
            end
        else
            isAutoShooting = false
            targetPlayer = nil
        end
    end)
end

local RagebotToggle = RagebotTab:CreateToggle({
   Name = "Ragebot",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
      isRagebotEnabled = Value
      if not Value then
         isAutoShooting = false
         if cameraConnection then
            cameraConnection:Disconnect()
         end
         if autoShootConnection then
            autoShootConnection:Disconnect()
         end
         targetPlayer = nil
      end
   end,
})

local RagebotKeybind = RagebotTab:CreateKeybind({
   Name = "Hold Ragebot",
   CurrentKeybind = "Q",
   HoldToInteract = true,
   Flag = "RagebotKeybind",
   Callback = function(isHeld)
      if isHeld and isRagebotEnabled then
         startRagebot()
      else
         isAutoShooting = false
         if cameraConnection then
            cameraConnection:Disconnect()
         end
         if autoShootConnection then
            autoShootConnection:Disconnect()
         end
         targetPlayer = nil
      end
   end,
})

local HitpartDropdown = RagebotTab:CreateDropdown({
   Name = "Hitpart",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "HitpartDropdown",
   Callback = function(Options)
      selectedHitpart = Options[1]
   end,
})

local KnockCheckToggle = RagebotTab:CreateToggle({
   Name = "Knock Check",
   CurrentValue = true,
   Flag = "KnockCheck",
   Callback = function(Value)
      knockCheck = Value
   end,
})

local TeamCheckToggle = RagebotTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Flag = "TeamCheck",
   Callback = function(Value)
      teamCheck = Value
   end,
})

-- Gun Mods Section
local GunModsSection = MiscTab:CreateSection("Gun Mods")

local ApplyCooldownToggle = MiscTab:CreateToggle({
   Name = "Apply Cooldown",
   CurrentValue = false,
   Flag = "ApplyCooldownToggle",
   Callback = function(Value)
      applyCooldownEnabled = Value
      if Value then
         toggleTableAttribute("ShootCooldown", fireRateChanger / 100)
      end
   end,
})

local ApplySpreadToggle = MiscTab:CreateToggle({
   Name = "Apply Spread",
   CurrentValue = false,
   Flag = "ApplySpreadToggle",
   Callback = function(Value)
      applySpreadEnabled = Value
      if Value then
         toggleTableAttribute("ShootSpread", spreadMultiplier / 100)
      end
   end,
})

local ApplyRecoilToggle = MiscTab:CreateToggle({
   Name = "Apply Recoil",
   CurrentValue = false,
   Flag = "ApplyRecoilToggle",
   Callback = function(Value)
      applyRecoilEnabled = Value
      if Value then
         toggleTableAttribute("ShootRecoil", recoilCompensation / 100)
      end
   end,
})

local RecoilCompensationSlider = MiscTab:CreateSlider({
   Name = "Recoil Compensation",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 100,
   Flag = "RecoilCompensationSlider",
   Callback = function(Value)
      recoilCompensation = Value
      if applyRecoilEnabled then
         toggleTableAttribute("ShootRecoil", Value / 100)
      end
   end,
})

local SpreadMultiplierSlider = MiscTab:CreateSlider({
   Name = "Spread Multiplier",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 100,
   Flag = "SpreadMultiplierSlider",
   Callback = function(Value)
      spreadMultiplier = Value
      if applySpreadEnabled then
         toggleTableAttribute("ShootSpread", Value / 100)
      end
   end,
})

local FireRateChangerSlider = MiscTab:CreateSlider({
   Name = "Fire Rate Changer",
   Range = {0, 30},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 100,
   Flag = "FireRateChangerSlider",
   Callback = function(Value)
      fireRateChanger = Value
      if applyCooldownEnabled then
         toggleTableAttribute("ShootCooldown", Value / 100)
      end
   end,
})

warn("Cravex Hub for Rivals loaded!")

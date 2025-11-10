local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game.Workspace
local Camera=Workspace.CurrentCamera
local LocalPlayer=Players.LocalPlayer
local characterFolder=Workspace:WaitForChild("characters")
local ignoreFolder=Workspace:FindFirstChild("ignore")
local PARTS={"head","humanoid_root_part","left_arm_vis","left_leg_vis","right_arm_vis","right_leg_vis","torso"}
local CHAMS_COLOR=Color3.fromRGB(255,255,255)
local FILL_COLOR=Color3.fromRGB(255,255,255)
local FILL_TRANSPARENCY=0.7
local OUTLINE_TRANSPARENCY=0
local MAX_DISTANCE=1000
local LABEL_COLOR=Color3.fromRGB(255,255,255)
local LABEL_OUTLINE_COLOR=Color3.fromRGB(0,0,0)
local chams={}
local labels={}
local function isValidRig(model)
	if model.Parent~=characterFolder then return false end
	if ignoreFolder and model:IsDescendantOf(ignoreFolder) then return false end
	for _,name in ipairs(PARTS)do
		if not model:FindFirstChild(name)then return false end
	end
	return true
end
local function createCham(part)
	if not part or chams[part]then return end
	local h=Instance.new("Highlight")
	h.Name="ESP_Chams"
	h.FillColor=FILL_COLOR
	h.OutlineColor=CHAMS_COLOR
	h.FillTransparency=FILL_TRANSPARENCY
	h.OutlineTransparency=OUTLINE_TRANSPARENCY
	h.Adornee=part
	h.Parent=part
	chams[part]=h
end
local function createLabel(model)
	if labels[model]then return end
	local l=Drawing.new("Text")
	l.Size=16
	l.Font=2
	l.Color=LABEL_COLOR
	l.Outline=true
	l.OutlineColor=LABEL_OUTLINE_COLOR
	l.Center=true
	l.Visible=false
	labels[model]=l
end
local function removeCham(part)
	local h=chams[part]
	if h then h:Destroy()end
	chams[part]=nil
end
local function removeLabel(model)
	local l=labels[model]
	if l then l:Remove()end
	labels[model]=nil
end
RunService.RenderStepped:Connect(function()
	local camPos=Camera.CFrame.Position
	for part in pairs(chams)do
		if not part or not part.Parent then
			removeCham(part)
		end
	end
	for model in pairs(labels)do
		if not model or not model.Parent or not model:FindFirstChild("humanoid_root_part")then
			removeLabel(model)
		end
	end
	for _,char in pairs(characterFolder:GetChildren())do
		if char:IsA("Model")and isValidRig(char)and char~=LocalPlayer.Character then
			local hrp=char:FindFirstChild("humanoid_root_part")
			local head=char:FindFirstChild("head")
			if hrp and head then
				for _,name in ipairs(PARTS)do
					local part=char:FindFirstChild(name)
					if part and part:IsA("BasePart")then
						createCham(part)
					end
				end
				local dist=(camPos-hrp.Position).Magnitude
				if dist<=MAX_DISTANCE then
					createLabel(char)
					local pos,onScreen=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,3,0))
					if onScreen then
						labels[char].Text=math.floor(dist).."m"
						labels[char].Position=Vector2.new(pos.X,pos.Y)
						labels[char].Visible=true
					else
						labels[char].Visible=false
					end
				else
					labels[char].Visible=false
				end
			end
		end
	end
end)
LocalPlayer.CharacterAdded:Connect(function()
	for part in pairs(chams)do removeCham(part)end
	for model in pairs(labels)do removeLabel(model)end
end)

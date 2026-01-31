--[[
	- Author : Mawin_CK
	- Date : 2025
	- NOTE : 
	This is hardcoded shit
	Please don't adapt this for your game.
	recommending refactoring it
]]

-- NOTE : AWP_LOCALONLYTEST IS FOR TESTING IN CLIENT SIDED ONLY

-- Services
local RS = game:GetService("RunService")
local Rep = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RepFirst = game:GetService("ReplicatedFirst")

-- Modules
local AWP_System = Rep:WaitForChild("AWP_System")
local InputModules = AWP_System:WaitForChild("InputModules")
local Libraries = AWP_System:WaitForChild("Libraries")
local Configs = AWP_System:WaitForChild("Configs")

-- Requires
local Jolt = require(Libraries:WaitForChild("Jolt"))
local InputService = require(InputModules:WaitForChild("InputService"))
local InputTypes = require(InputModules:WaitForChild("InputTypes"))

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Mouse : Mouse = player:GetMouse()

local Camera = workspace.CurrentCamera

local MouseConnection: RBXScriptConnection = nil

local PlayerGui = player.PlayerGui
local ScopeGUI = PlayerGui:WaitForChild("ScopeGUI")

-- CONSTANTS
local DEFAULT_FOV = 70
local DEFAULT_ZOOM_DISTANCE = player.CameraMaxZoomDistance

local DEFAULT_SEN = 1.5
local AIM_SEN = 0.05

-- Configs
local ZoomLevel = DEFAULT_FOV / 15
local ZoomTime = 0.15

-- Init

local AimCFG : InputTypes.InputConfig = {
	IsMobile = false,
	Trigger = Enum.UserInputType.MouseButton2
}

local ZoomIn: Tween = TS:Create(Camera, TweenInfo.new(ZoomTime, Enum.EasingStyle.Bounce), {FieldOfView = ZoomLevel})
local ZoomOut: Tween = TS:Create(Camera, TweenInfo.new(ZoomTime), {FieldOfView = DEFAULT_FOV})

-- Assets
local Assets = AWP_System:WaitForChild("Assets")
local SFXs = Assets:WaitForChild("SFXs")

local ScopeSFX = SFXs:WaitForChild("ScopeSFX")

-- Events
local ProjectileEvent = Jolt.Client("ProjectileEvent")

-- Connections

character.ChildAdded:Connect(function(child: Instance)
	if child.Name == "AWP" and child:IsA("Tool") then
		for _, part: BasePart in child:GetChildren() do
			if part.CanCollide then
				part.CanCollide = false
			end
		end

		UIS.MouseIconEnabled = false

		-- Worst code I've written. But I don't care lmao
		local Handle = child:WaitForChild("Handle")
		local Muzzle = child:WaitForChild("Muzzle")
		local VFXs = Muzzle:WaitForChild("VFXs")

		MouseConnection = Mouse.Button1Down:Connect(function()
			if child:GetAttribute("CanShoot") == false then return end
			local Origin = Muzzle.Position
			local direction = (Mouse.Hit.Position - Origin).Unit

			--PlaySFX(FireSFX, Muzzle)
			ProjectileEvent:FireUnreliable(Origin, direction)
			ZoomOut:Play()
			ScopeGUI.Enabled = false
			UIS.MouseDeltaSensitivity = DEFAULT_SEN

			player.CameraMaxZoomDistance = DEFAULT_ZOOM_DISTANCE
			
		end)

		AimCFG.OnInputBegan = function()
			if child:GetAttribute("CanShoot") == false then return end
			ScopeSFX:Play()
			ZoomIn:Play()
			ScopeGUI.Enabled = true
			UIS.MouseDeltaSensitivity = AIM_SEN
			player.CameraMaxZoomDistance = 0.5
		end

		AimCFG.OnInputEnded = function()
			if child:GetAttribute("CanShoot") == false then return end
			ScopeSFX:Play()
			ZoomOut:Play()
			ScopeGUI.Enabled = false
			UIS.MouseDeltaSensitivity = DEFAULT_SEN
			player.CameraMaxZoomDistance = DEFAULT_ZOOM_DISTANCE
		end

		InputService.Bind("Aim", AimCFG)
	end
end)

character.ChildRemoved:Connect(function(child: Instance)
	if child.Name == "AWP" and child:IsA("Tool") then
		if MouseConnection then
			MouseConnection:Disconnect()
			MouseConnection = nil
		end

		ZoomOut:Play()
		ScopeGUI.Enabled = false
		UIS.MouseDeltaSensitivity = DEFAULT_SEN
		player.CameraMaxZoomDistance = DEFAULT_ZOOM_DISTANCE

		UIS.MouseIconEnabled = true
		InputService.UnBind("Aim")
	end
end)
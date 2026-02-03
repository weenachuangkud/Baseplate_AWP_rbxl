--[[
	- Author : Mawin_CK
	- Date : 2025
	- NOTE : 
	This is hard-coded shit
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
local SpringModule = require(Libraries:WaitForChild("Spring"))

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

local ReloadCFG : InputTypes.InputConfig = {
	IsMobile = false,
	Trigger = Enum.KeyCode.R
}

local ZoomIn: Tween = TS:Create(Camera, TweenInfo.new(ZoomTime, Enum.EasingStyle.Bounce), {FieldOfView = ZoomLevel})
local ZoomOut: Tween = TS:Create(Camera, TweenInfo.new(ZoomTime), {FieldOfView = DEFAULT_FOV})

-- Assets
local Assets = AWP_System:WaitForChild("Assets")
local SFXs = Assets:WaitForChild("SFXs")

local ScopeSFX = SFXs:WaitForChild("ScopeSFX")

-- Events
local ProjectileEvent = Jolt.Client("ProjectileEvent")
local ReloadEvent = Jolt.Client("ReloadEvent")

-- CameraRecoil
local Spring = SpringModule.new(Vector2.zero, 0.45, 10)
local last = Vector2.zero

local Recoil_debounce = false
local Recoil_cooldown = 1.25

local function CameraRecoil(x, y)
	if Recoil_debounce then return end
	Recoil_debounce = true
	
	Spring:Impulse(Vector2.new(
		math.rad(x),
		math.rad(y)
	))
	
	task.delay(Recoil_cooldown, function()
		Recoil_debounce = false
	end)
end


-- Connections

character.ChildAdded:Connect(function(child: Instance)
	if child.Name == "AWP" and child:IsA("Tool") then
		for _, part: BasePart in child:GetChildren() do
			if not part:IsA("BasePart") then continue end
			if part.CanCollide then
				part.CanCollide = false
			end
		end
		
		local WeaponData = child:WaitForChild("WeaponData")
	
		UIS.MouseIconEnabled = false

		-- Worst code I've written. But I don't care lmao
		local Handle = child:WaitForChild("Handle")
		local Muzzle = child:WaitForChild("Muzzle")
		local VFXs = Muzzle:WaitForChild("VFXs")

		MouseConnection = Mouse.Button1Down:Connect(function()
			local state = WeaponData:GetAttribute("State")
			if state == "BOLT_CYCLING" then return end
			
			local Origin = Muzzle.Position
			local direction = (Mouse.Hit.Position - Origin).Unit

			--PlaySFX(FireSFX, Muzzle)
			ProjectileEvent:FireUnreliable(Origin, direction)
			
			if WeaponData:GetAttribute("CurrentAmmo") <= 0 then return end
			
			ZoomOut:Play()
			ScopeGUI.Enabled = false
			UIS.MouseDeltaSensitivity = DEFAULT_SEN

			player.CameraMaxZoomDistance = DEFAULT_ZOOM_DISTANCE
			
			-- What 9+10?
			
			CameraRecoil(math.random(-0.2, 0.2), 21)
		end)

		AimCFG.OnInputBegan = function()
			local state = WeaponData:GetAttribute("State")
			if state == "BOLT_CYCLING" or state == "RELOADING" then return end
			
			ScopeSFX:Play()
			ZoomIn:Play()
			ScopeGUI.Enabled = true
			UIS.MouseDeltaSensitivity = AIM_SEN
			player.CameraMaxZoomDistance = 0.5
		end

		AimCFG.OnInputEnded = function()
			local state = WeaponData:GetAttribute("State")
			if state == "BOLT_CYCLING" or state == "RELOADING" then return end
			
			ScopeSFX:Play()
			ZoomOut:Play()
			ScopeGUI.Enabled = false
			UIS.MouseDeltaSensitivity = DEFAULT_SEN
			player.CameraMaxZoomDistance = DEFAULT_ZOOM_DISTANCE
		end
		
		ReloadCFG.OnInputBegan = function()
			local state = WeaponData:GetAttribute("State")
			if state == "BOLT_CYCLING" or state == "RELOADING" then return end
			
			ReloadEvent:Fire()
			ZoomOut:Play()
			ScopeGUI.Enabled = false
			UIS.MouseDeltaSensitivity = DEFAULT_SEN

			player.CameraMaxZoomDistance = DEFAULT_ZOOM_DISTANCE
		end
		
		RS:BindToRenderStep("CameraRecoil", Enum.RenderPriority.Camera.Value, function()
			local current = Spring.Position
			local delta = current - last
			last = current

			Camera.CFrame = Camera.CFrame
				* CFrame.Angles(
					delta.Y, -- pitch
					delta.X, -- yaw
					0
				)
		end)

		InputService.Bind("Aim", AimCFG)
		InputService.Bind("Reload", ReloadCFG)
	end
end)

character.ChildRemoved:Connect(function(child: Instance)
	if child.Name == "AWP" and child:IsA("Tool") then
		if MouseConnection then
			MouseConnection:Disconnect()
			MouseConnection = nil
		end
		
		RS:UnbindFromRenderStep("CameraRecoil")

		ZoomOut:Play()
		ScopeGUI.Enabled = false
		UIS.MouseDeltaSensitivity = DEFAULT_SEN
		player.CameraMaxZoomDistance = DEFAULT_ZOOM_DISTANCE

		UIS.MouseIconEnabled = true
		InputService.UnBind("Aim")
		InputService.UnBind("Reload")
	end
end)

--[[
	- Author : Mawin CK
	- Date : 2025
]]

-- Services
local Rep = game:GetService("ReplicatedStorage")
local RepFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

-- Modules
local AWP_System = Rep:WaitForChild("AWP_System")
local Libraries = AWP_System:WaitForChild("Libraries")

-- Requires
local Jolt = require(Libraries:WaitForChild("Jolt"))
local FastCast2 = require(Libraries:WaitForChild("FastCast2"))
local Configs = AWP_System:WaitForChild("Configs")

-- Variables
local player = Players.LocalPlayer 
local character = player.Character or player.CharacterAdded:Wait()

local Assets = AWP_System:WaitForChild("Assets")
local SFXs = Assets:WaitForChild("SFXs")
local FireSFX = SFXs:WaitForChild("FireSound")
local BoltSFX = SFXs:WaitForChild("BoltSFX")

-- Events
local ProjectileEvent = Jolt.Client("ProjectileEvent")

-- FastCast
local Caster = FastCast2.new()
Caster:Init(
	4,
	RepFirst,
	"AWP_CasterVMs",
	RepFirst,
	"AWP_VMContainer",
	"AWP_VM"
)

local behavior = require(Configs:WaitForChild("BulletBehavior"))
behavior.VisualizeCasts = true

local CastParams = RaycastParams.new()
CastParams.IgnoreWater = true
CastParams.FilterType = Enum.RaycastFilterType.Exclude
CastParams.FilterDescendantsInstances = {character}

behavior.RaycastParams = CastParams

local SPEED = 850

-- Local functions
local function PlaySFX(SFX: Sound, Parent: Instance?, DestroyOnEnd: boolean)
	local SFX = SFX:Clone()
	SFX.Parent = Parent
	SFX:Play()

	if DestroyOnEnd then
		SFX.Ended:Once(function()
			SFX:Destroy()
		end)
	end

	return SFX
end

-- Connections

ProjectileEvent:Connect(function(
	Firedplayer : Player, 
	origin : Vector3, 
	direction : Vector3
)
	local targetCharacter = Firedplayer.Character
	if not targetCharacter then return end
	local AWP_Tool = targetCharacter:FindFirstChild("AWP")
	-- Shit code
	if AWP_Tool then
		local Muzzle = AWP_Tool:WaitForChild("Muzzle")
		local Handle = AWP_Tool:WaitForChild("Handle")
		PlaySFX(FireSFX, Muzzle, true)
		local VFXs = Muzzle:WaitForChild("VFXs")

		for i, v in VFXs:GetChildren() do
			if v:IsA("ParticleEmitter") then
				v:Emit(50)
			end
			if v:IsA("Attachment") then
				for i, v2 in v:GetChildren() do
					if v2:IsA("ParticleEmitter") then
						v2:Emit(50)
					end	
				end
			end
		end

		local WeaponData = AWP_Tool:FindFirstChild("WeaponData")
		if not WeaponData then
			return
		end
		
		WeaponData:SetAttribute("State", "BOLT_CYCLING")
		task.spawn(function()
			local Boltps = PlaySFX(BoltSFX, Handle)
			Boltps.Ended:Wait()
			Boltps:Destroy()
			WeaponData:SetAttribute("State", "IDLE")
		end)
	end

	Caster:RaycastFire(origin, direction, SPEED, behavior)
end)

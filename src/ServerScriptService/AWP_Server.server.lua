--[[
	- Author : Mawin_CK
	- Date : 2025
	- NOTE : 
	This is hard-coded shit
	Please don't adapt this for your game.
	recommending refactoring it
]]

-- Services
local Rep = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("RunService")

-- Modules
local AWP_System = Rep:WaitForChild("AWP_System")
local Libraries = AWP_System:WaitForChild("Libraries")
local FastCast2 = Libraries:WaitForChild("FastCast2")
local Configs = AWP_System:WaitForChild("Configs")

-- Requires
local Jolt = require(Libraries:WaitForChild("Jolt"))
local FastCastM = require(FastCast2)
local FastCastTypes = require(FastCast2:WaitForChild("TypeDefinitions"))
local behavior = require(Configs:WaitForChild("BulletBehavior"))
local RagdollService = require(Libraries:WaitForChild("RagdollService"))

-- Assets
local Assets = AWP_System:WaitForChild("Assets")
local SFXs = Assets:WaitForChild("SFXs")

local HeadShotSFX = SFXs:WaitForChild("Headshot - CS:GO")
local EmptyClip = SFXs:WaitForChild("Empty clip")
local ReloadSFX = SFXs:WaitForChild("ReloadSound")

-- Events
local ProjectileEvent = Jolt.Server("ProjectileEvent")
local ReloadEvent = Jolt.Server("ReloadEvent")

-- CastParams
local CastParams = RaycastParams.new()
CastParams.FilterType = Enum.RaycastFilterType.Exclude
CastParams.FilterDescendantsInstances = {}
CastParams.IgnoreWater = true

-- FastCast
local Caster = FastCastM.new()
Caster:Init(
	4,
	SSS,
	"AWP_CasterVMs",
	SSS,
	"AWP_VMContainer",
	"AWP_VM"
)

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

local IsStudio = RS:IsStudio()
local function StudioWarn(msg: string)
	if IsStudio then
		warn(msg)
	end
end

-- Connections

Caster.RayHit:Connect(function(cast : FastCastTypes.ActiveCast, raycastResult : RaycastResult)
	local humanoid = raycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local HitHead = raycastResult.Instance.Name == "Head"
		
		local character = humanoid.Parent
		local rootPart: BasePart = character:FindFirstChild("HumanoidRootPart")
		PlaySFX(HeadShotSFX, rootPart, true)
		humanoid:TakeDamage(HitHead and 100 or 500)
		
		if not RagdollService.IsRagdolled(character) then
			RagdollService.Ragdoll(character)
		end
		
		local direction = cast.StateInfo.Trajectories[#cast.StateInfo.Trajectories].InitialVelocity.Unit
		if HitHead then
			rootPart:ApplyImpulse(direction * 120 * rootPart.AssemblyMass)
		else
			rootPart:ApplyImpulse(direction * 50 * rootPart.AssemblyMass)
		end
	end
end)

-- Variables
local db = {}

local DEFAULT_FIRERATE = 1.5

-- CONSTANTS
local SPEED = 850

-- Connections
ProjectileEvent:Connect(function(player: Player, origin: Vector3, direction: Vector3)
	--print("Received")
	-- Fire
	local targetCharacter = player.Character
	if not targetCharacter then return end  -- No character, ignore

	local AWP_Tool = targetCharacter:FindFirstChild("AWP")
	if not AWP_Tool then return end 
	
	local WeaponData = AWP_Tool:FindFirstChild("WeaponData")
	
	if not WeaponData then
		StudioWarn("No WeaponData")
	end
	
	local state = WeaponData:GetAttribute("State")

	if state == "RELOADING" and WeaponData:GetAttribute("CanCancelReload") then
		WeaponData:SetAttribute("State", "IDLE")
	else
		if state ~= "IDLE" then
			return
		end
	end
	
	local firerate = WeaponData:GetAttribute("Firerate") or DEFAULT_FIRERATE  -- Now treating as cooldown in seconds
	
	-- Debounce check
	local lastFireTime = db[player] or 0
	local currentTime = os.clock()
	if currentTime - lastFireTime < (1/firerate) then
		return 
	end
	
	local CurrentAmmo = WeaponData:GetAttribute("CurrentAmmo")
	
	if CurrentAmmo <= 0 then 
		local Handle = AWP_Tool:FindFirstChild("Handle")
		PlaySFX(EmptyClip, Handle, true)
		return 
	end
	
	local MaxAmmo = WeaponData:GetAttribute("MaxAmmo")
	if CurrentAmmo > MaxAmmo then
		WeaponData:SetAttribute("CurrentAmmo", MaxAmmo)
		CurrentAmmo = MaxAmmo
	end
	
	CastParams.FilterDescendantsInstances = {targetCharacter}
	behavior.RaycastParams = CastParams
	Caster:RaycastFire(origin, direction, SPEED, behavior)
	ProjectileEvent:FireAllUnreliable(player, origin, direction)
	
	WeaponData:SetAttribute("CurrentAmmo", CurrentAmmo - 1)
	
	db[player] = os.clock()
end)

ReloadEvent:Connect(function(player: Player)
	local targetCharacter = player.Character
	if not targetCharacter then return end
	
	
	local AWP_Tool = targetCharacter:FindFirstChild("AWP")
	if not AWP_Tool then return end  
	
	
	local WeaponData = AWP_Tool:FindFirstChild("WeaponData")
	
	if not WeaponData then
		StudioWarn("No WeaponData")
	end
	
	local state = WeaponData:GetAttribute("State")
	
	if state == "RELOADING" then
		return
	end
	
	local ReserveAmmo = WeaponData:GetAttribute("ReserveAmmo")
	
	if ReserveAmmo <= 0 then
		return
	end
	
	local MaxAmmo = WeaponData:GetAttribute("MaxAmmo")
	local CurrentAmmo = WeaponData:GetAttribute("CurrentAmmo")
	
	if CurrentAmmo >= MaxAmmo then
		return
	end
	
	WeaponData:SetAttribute("State", "RELOADING")
	WeaponData:SetAttribute("CanCancelReload", true)
	local ReloadSound = PlaySFX(ReloadSFX, AWP_Tool:FindFirstChild("Handle"))
	

	local conn
	conn = WeaponData:GetAttributeChangedSignal("State"):Connect(function()
		if WeaponData:GetAttribute("State") ~= "RELOADING" then
			if ReloadSound then
				ReloadSound:Stop()
				ReloadSound:Destroy()
				ReloadSound = nil
			end
			WeaponData:SetAttribute("CanCancelReload", false)
			conn:Disconnect()
		end
	end)
	
	ReloadSound.Ended:Once(function()
		-- If reload was canceled, do nothing
		if WeaponData:GetAttribute("State") ~= "RELOADING" then
			return
		end

		CurrentAmmo = WeaponData:GetAttribute("CurrentAmmo")
		ReserveAmmo = WeaponData:GetAttribute("ReserveAmmo")

		local AmmoNeeded = MaxAmmo - CurrentAmmo
		local AmmoTaken = math.min(AmmoNeeded, ReserveAmmo)

		WeaponData:SetAttribute("CurrentAmmo", CurrentAmmo + AmmoTaken)
		WeaponData:SetAttribute("ReserveAmmo", ReserveAmmo - AmmoTaken)

		WeaponData:SetAttribute("State", "IDLE")

		ReloadSound:Destroy()
		ReloadSound = nil
		
		WeaponData:SetAttribute("CanCancelReload", false)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	if db[player] then
		db[player] = nil
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		RagdollService.SetupRagdoll(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		if humanoid then
			humanoid.Died:Connect(function()
				RagdollService.Ragdoll(character)
			end)
		end
		
		player.CharacterAppearanceLoaded:Once(function()
			for _, part in character:GetChildren() do
				if part:IsA("Accessory") then
					local hnd: BasePart = part:FindFirstChild("Handle")
					if not hnd then continue end
					hnd.CanQuery = false
				end
			end
		end)
		
	end)
end)

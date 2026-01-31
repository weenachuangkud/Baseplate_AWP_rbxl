--[[
	Author : Mawin CK
	Date   : 2025-03-11
	Desc   : Binds InputConfigs to ContextActionService (desktop + mobile)
]]

-- Service
local Rep = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")

-- Modules
local AWP_System = Rep:WaitForChild("AWP_System")
local InputMods = AWP_System:WaitForChild("InputModules")

-- Requires
local InputTypes = require(InputMods:WaitForChild("InputTypes"))


-- Connections
local Actives : {[string] : {
	["OnInputBegan"] : RBXScriptConnection?,
	["OnInputEnded"] : RBXScriptConnection?	
}} = {}

-- Export Types
export type InputService = {
	Bind : (actionName : string, cfg : InputTypes.InputConfig, IsMobile: boolean?) -> (),
	UnBind : (actionName : string, IsMobile: boolean?) -> (),
	UnBindAll : (IsMobile: boolean?) -> ()
}

-- Module

local InputService = {}

-- Bind a single named action
function InputService.Bind(
	name: string,
	cfg: InputTypes.InputConfig,
	IsMobile: boolean?
)
	assert(cfg, "InputConfig is nil")
	-- Mobile GUI button (optional)
	if IsMobile and cfg.MobileButton then
		local button : ImageButton | TextButton = cfg.MobileButton
		if not button then warn("No MobileButton for : ", name) return end
		if Actives[name] then warn("Already Bind this actionName") return end
		Actives[name] = {
			OnInputBegan = cfg.OnInputBegan and button.InputBegan:Connect(cfg.OnInputBegan),
			OnInputEnded = cfg.OnInputEnded and button.InputEnded:Connect(cfg.OnInputEnded)
		}
		return
	end

	-- Desktop / Keyboard / Gamepad binding
	local triggers = cfg.Trigger

	local function handleAction(
		actionName: string,
		inputState: Enum.UserInputState,
		inputObject: InputObject
	): Enum.ContextActionResult
		if inputState == Enum.UserInputState.Begin then
			if cfg.OnInputBegan then
				cfg.OnInputBegan(inputObject)
			end
		elseif inputState == Enum.UserInputState.End then
			if cfg.OnInputEnded then
				cfg.OnInputEnded(inputObject)
			end
		end

		return cfg.Sink and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
	end

	if typeof(triggers) == "table" then 
		triggers = table.unpack(triggers)
	end
	CAS:BindAction(name, handleAction, false, triggers)
end

function InputService.UnBind(Name : string, IsMobile : boolean?)
	if IsMobile then
		if Actives[Name] then
			-- My eyes are bleeding seeing these warnings
			if Actives[Name].OnInputBegan then
				Actives[Name].OnInputBegan:Disconnect()
				Actives[Name].OnInputBegan = nil
			end
			if Actives[Name].OnInputEnded then
				Actives[Name].OnInputEnded:Disconnect()
				Actives[Name].OnInputEnded = nil
			end
		else
			warn(Name .. " Does not exist")
		end
		return
	end
	local isExist = CAS:GetBoundActionInfo(Name)
	if isExist then
		CAS:UnbindAction(Name)
	else
		warn(Name .. " Does not exist")
	end
end

function InputService.IsBinded(Name : string)
	return Actives[Name] ~= nil
end


function InputService.UnBindAll(IsMobile: boolean?)
	if IsMobile then
		for keyName, active in Actives do
			InputService.UnBind(keyName)
		end
	end
	CAS:UnbindAllActions()
end

return InputService
--[[
	- Author : Mawin CK
	- Date : 11/03/2025
]]

--!strict

type VaildInputs = Enum.UserInputType | Enum.KeyCode

export type InputConfig = {
	Trigger : {VaildInputs} | VaildInputs,
	OnInputBegan : ((InputObject) -> ())?,
	OnInputEnded : ((InputObject) -> ())?,
	MobileButton : (TextButton | ImageButton)?,
	Sink : boolean?
}

export type InputConfigs = {
	IsMobile : boolean,
	[string] : InputConfig
}

return {}
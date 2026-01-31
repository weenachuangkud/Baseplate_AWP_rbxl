-- Services
local Rep = game:GetService("ReplicatedStorage")

-- Modules
local AWP_System = Rep:WaitForChild("AWP_System")
local Libraries = AWP_System:WaitForChild("Libraries")
local FastCast2 = Libraries:WaitForChild("FastCast2")

-- Requires
local FastCast = require(FastCast2)

-- Behavior
local behavior = FastCast.newBehavior()
behavior.MaxDistance = 3000
behavior.HighFidelityBehavior = 1
behavior.Acceleration = Vector3.new(0, -workspace.Gravity/65.82, 0)
behavior.SimulateAfterPhysic = true
behavior.UseLengthChanged = false

return behavior
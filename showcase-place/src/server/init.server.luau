-- :: I don't know if you guys need comments here for applying, but I did commented main module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Properties = require(ReplicatedStorage.Shared.Properties)

local ServerScriptService = game:GetService("ServerScriptService")
local ServerNetwork = require(ServerScriptService.Server.ServerNetwork)

local spawned: {Instance} = {}
local current: string = nil

ServerNetwork.CreatePart.On(function(player: Player, data: {[string]: any})
	local part = Instance.new("Part")
	part.Position = player.Character
		and (player.Character:GetPivot().Position + Vector3.new(0, 6, 0))
		or Vector3.new(0, 5, 0)

	part.Size = data.Size
	part.Color = data.Color
	part.Material = data.Material
	part.Transparency = data.Transparency
	part.CastShadow = data.CastShadow
	part.Anchored = data.Anchored
	
	local name = `Part_{#spawned + 1}`
	part.Parent = workspace
	part.Name = name

	table.insert(spawned, part)
	current = name
end)

ServerNetwork.GetProperties.On(function(player: Player)
	-- :: actually this can be performed with Instances, but I'm too lazy to do it
	-- :: doing event returning BECAUSE FOR SOME REASON BLINK ISN'T WORKING ON CLIENT!!
	if current then
		local find: Instance? = workspace:FindFirstChild(current)
		local result, err = Properties:GetProperties(find :: any)
		ServerNetwork.ReturnProperties.Fire(player, result, err)
	else
		local message = "Spawn part before parsing properties"
		ServerNetwork.ReturnProperties.Fire(player, message, nil)
	end
end)
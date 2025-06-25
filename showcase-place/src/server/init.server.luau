-- :: I don't know if you guys need comments here for applying, but I did commented main module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Properties = require(ReplicatedStorage.Shared.Properties)

local ServerScriptService = game:GetService("ServerScriptService")
local ServerNetwork = require(ServerScriptService.Server.ServerNetwork)

local spawned: {Instance} = {}
ServerNetwork.CreatePart.On(function(player: Player, data: {[string]: any}): (string)
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
	return name
end)

ServerNetwork.GetProperties.On(function(_player: Player, class: string): ({[string]: any}, any)
	-- :: actually this can be performed with Instances, but I'm too lazy to do it
	local find: Instance? = workspace:FindFirstChild(class)
	return Properties:GetProperties(find :: any)
end)
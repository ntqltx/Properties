-- :: I don't know if you guys need comments here for applying, but I did commented main module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientNetwork = require(ReplicatedStorage.Shared.ClientNetwork)
local Iris = require(ReplicatedStorage.Shared.Iris)
Iris.Init()

local sizeState = Iris.State(Vector3.new(4, 4, 4))
local colorState = Iris.State(Color3.fromRGB(255, 255, 255))
local materialState = Iris.State(Enum.Material.Plastic)
local transparencyState = Iris.State(0)
local castShadowState = Iris.State(true)
local anchoredState = Iris.State(false)

local new_output: any = {}
local function spawnPart()
	local data = {
        Size = sizeState:get(), Color = colorState:get(),
        Material = materialState:get(), Transparency = transparencyState:get(),
        CastShadow = castShadowState:get(), Anchored = anchoredState:get()
    }
    ClientNetwork.CreatePart.Fire(data)
end

-- :: doing event returning BECAUSE FOR SOME REASON BLINK ISN'T WORKING ON CLIENT!!
ClientNetwork.ReturnProperties.On(function(result: any, err: any)
	new_output = if not err then result else err
end)

Iris:Connect(function()
	local editorSize = Iris.State(Vector2.new(407, 700))
	local editorPos = Iris.State(Vector2.new(36, 0))

	Iris.Window(
		{"Editor", false, false, false, true, true, false, false},
		{size = editorSize, position = editorPos, isOpened = true}
	)
	do
		Iris.Tree({"Properties"}, {isUncollapsed = true})
		do
			Iris.Combo({"Material"}, {index = materialState})
			do
				for _, material: EnumItem in Enum.Material:GetEnumItems() do
					Iris.Selectable({
						material.Name, material.Name
					}, {index = materialState})
				end
			end
			Iris.End()

			Iris.InputColor3({"Color"}, {color = colorState})
			Iris.InputVector3({"Size"}, {number = sizeState})
			Iris.SliderNum({"Transparency", 0.1, 0, 1}, {number = transparencyState})

			Iris.SameLine()
			do
				Iris.Checkbox({"CastShadow"}, {isChecked = castShadowState})
				Iris.Checkbox({"Anchored"}, {isChecked = anchoredState})
			end
			Iris.End()
		end
		Iris.End()
		
		Iris.SameLine()
		do
			local spawn = Iris.Button({"Spawn"})
			if spawn.hovered() then
				if spawn.clicked() then
					spawnPart()
				end
				Iris.Tooltip({"Spawns part with custom properties"})
			end
	
			local parse = Iris.Button({"Parse"})
			if parse.hovered() then
				if parse.clicked() then
					new_output = "Parsing... It could take some time"
					ClientNetwork.GetProperties.Fire()
				end
				Iris.Tooltip({"Parses last created part properties"})
			end

			local hint = Iris.Text({"(?)", false, Color3.fromRGB(150, 150, 150)})
			if hint.hovered() then
				Iris.Tooltip({"When you spawning new part, it's creating it in the server via Blink Networking\nand then you can parse last part you spawned, to get all props/values from it\n(You can resize the window)"})
			end
		end
		Iris.End()

		Iris.Separator()
		Iris.Tree({"Output"}, {isUncollapsed = true})
		do
			if typeof(new_output) == "table" then
				for prop, value in pairs(new_output) do
				   Iris.Text({`{prop}: {value}`})
			   end
			else
				Iris.Text({`{new_output}`})
			end
		end
		Iris.End()
	end
	Iris.End()
end)
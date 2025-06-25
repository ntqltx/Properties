--[[
    Module code re-builder, written by @fl0mdev, updated by @ntqltx
        - How to use: 
        1. Initialize lune: "lune setup"
        2. Initialize .rbxl file: "rojo build -o game.rbxl"
        2. Change path to yours module (line 20)
        3. Run code: "lune run {your_lune_folder}/ModuleBuild"
]]

--# selene: allow(incorrect_standard_library_use)

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local placeFile = fs.readFile("place.rbxl")
local game = roblox.deserializePlace(placeFile)

-- :: Modify this path to yours module path
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PATH = ReplicatedStorage.Shared.Iris
local STARTING_PATH = ``

local function recursiveBuildCode(instance, route: string)
    if #instance:GetChildren() > 0 then
        route = `{route}{instance.Name}/`
        fs.writeDir(route)

        if instance:IsA("ModuleScript") then
            fs.writeFile(`{route}init.luau`, instance.Source)
        end

        for _, new in instance:GetChildren() do
            recursiveBuildCode(new, route)
        end
        return
    end

    if not instance:IsA("ModuleScript") then
        return
    end

    fs.writeFile(`{route}{instance.Name}.luau`, instance.Source)
end
 
recursiveBuildCode(PATH, STARTING_PATH)
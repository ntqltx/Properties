# Properties: Module - Easy way to get class properties!
by @alex | Version 1.0.0 (Still in development)

---

## Overview
A lightweight module that provides access to getting properties of Instance, or specific class name. 
In the future, there would be a lot more useful functions.

---

## How It Works

1. On game start, fetches the latest API dump from Roblox servers using proxy
2. Parses JSON, and builds new structure with classes and properties only
3. Caches the result data for the future calls

## Usage Example

```lua
local instance = Instance.new("Part")
local properties, err = Properties:GetProperties(instance)

if not properties then
    warn("Failed to get properties: " .. err)
else
    -- Fetching all property names
    local props = {}
    for name in pairs(properties) do
        table.insert(props, name)
    end

    -- Output: "Part properties: Name, Parent, Material, ..."
    print("Part properties: " .. table.concat(props, ", "))
end
```

---

## API Reference

### `Properties:GetProperties(class: Instance | string) -> (table, string?)`
Retrieves all properties and current values of an instance or class

**Parameters:**
- `class`: Instance or class name

**Returns:**
1. Table of property pairs
2. Error message (if any)

**Example:**
```lua
local properties = Properties:GetProperties(workspace.Part)
print(properties) -- Output: { ["Transparency"] = 0, ... }
```

---

### `Properties:HasProperty(class: Instance | string, property: string) -> (boolean, string?)`
Checks if a property exists on an instance or class

**Parameters:**
- `class`: Instance or class name
- `property`: Property to check (e.g. `"Color"`)

**Returns:**
1. `true` if property exists
2. Error message (if any)

**Example:**
```lua
local existing = Properties:HasProperty(workspace.Part, "Name")
if existing then
   print("Part's name: " .. workspace.Part.Name)
   -- Output: "Part's name: Part"
end
```

---

### `Properties:GetAllClasses() -> (table, string?)`
Returns all class names in alphabetical order

**Returns:**
1. Array of class names
2. Error message (if any)

---

I've wrote this Module in 2 days, and do not expect a lot from it. Right now I'm working at lazy initialization, more functions for parsing properties, optimizing proxy server and module itself.

If you have suggestion of what I can add, error, or issues with the module, please let me know as soon as possible! Thanks.

--!strict

--[[
    Properties Module written by avlex (@uid3v)
    Useful for getting all properties and its values
    from Instance, or specific class name.

    Methods:
        Properties:GetProperties(): (class: Instance | string) -> (table, string?)
        Properties:HasProperty(): (class: Instance | string, property: string) -> (boolean, string?)
        Properties:GetAllClasses(): () -> (table, string?)
]]

local HttpService = game:GetService("HttpService")
local Properties = {
     -- :: endpoint that gives version + api‑dump
    _api = "https://properties.glitch.me/" :: string,

    -- :: raw structure for every class we parse
    _classes = {} :: { [string]: {
        Superclass: string?,
        Properties: {string}?,
        Derived: { [string]: any }?
    }},
    _instancesProperties = {} :: { [string]: {string}? }?,

    -- :: properties that are deprecated and we want to ignore
    -- :: (gonna add better support later)
    _deprecatedProperties = {
        RobloxLocked = true,
        archivable = true,
        className = true,
    } :: { [string]: boolean },

    _initializing = false :: boolean,
    _initialized  = false :: boolean,
}

--[=[
    Retrieves all properties and current values of an instance or class
    
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

    @param class Target class
    @return { [string]: any } Table of Property pairs
    @return string? Error Message
]=]
function Properties.GetProperties(self: Properties, class: Instance | string): ({ [string]: any }, string?)
    if not self:_isInitialized() then
        return {}, "Properties are not initialized"
    end

    if not class then
        return {}, "No class (Instance or string) provided"
    end

    -- :: safeguard in case cache nil (should never happen after init)
    if not self._instancesProperties then
        return {}, "No InstancesProperties table found"
    end

    -- :: turn Instance into its ClassName, keep string as is
    local className = if typeof(class) == "Instance" then class.ClassName else class
    local properties = self._instancesProperties[className]
    local result: { [string]: any? } = {}

    -- :: unknown class guard
    if not properties then
        return {}, `Unknown class: {className}`
    end

    -- :: loop over each property
    for _, property in pairs(properties) do
        local success, value = pcall(function()
            return (class :: any)[property]
        end)
        -- :: assign read value or nil on failure
        result[property] = if success then value else nil
    end

    return result, nil
end

--[=[
    Checks if a property exists on an instance or class

    ```lua
    local part = Instance.new("Part")
    local existing = Properties:HasProperty(part, "Transparency")
    
    if existing then
        -- If the property exists, modifying it
        part.Transpareny = math.random(0.5, 1)
    end
    ```

    @param class Target class
    @param property Property to check
    @return boolean Whether property exists
    @return string? Error Message
]=]
function Properties.HasProperty(self: Properties, class: Instance | string, property: string): (boolean, string?)
    if not self:_isInitialized() then
        return false, "Properties are not initialized"
    end

    -- :: validate call args
    if not class then
        return false, "No class (Instance or string) provided"
    end

    if not self._instancesProperties then
        return false, "No InstancesProperties table found"
    end

    -- :: turn Instance into its ClassName, keep string as is
    local className = if typeof(class) == "Instance" then class.ClassName else class
    local properties = self._instancesProperties[className]
    
    if not properties then
        return false, `Unknown class: {className}`
    end

    -- :: iterate properties, return true if found
    for _, prop: any? in ipairs(properties) do
        if prop ~= property then
            continue
        end
        return true, nil
    end

    -- :: returning false without an error
    return false, nil
end

--[=[
    Returns all class names in alphabetical order

    ```lua
    local classes = Properties:GetAllClasses()

    -- Looping through all classes
    for _, class in ipairs(classes) do
        local props = Properties:GetProperties(class)
        local propCount = 0

        -- Counting properties in class
        for _ in pairs(props) do
            propCount += 1
        end

        -- Output: "BasePart (30 properties), ..."
        print(class .. ` ({propCount} properties)`)
    end
    ```

    @return { string } Sorted list of classes
    @return string? Error Message
]=]
function Properties.GetAllClasses(self: Properties): ({string}, string?)
    if not self:_isInitialized() then
        return {}, "Properties are not initialized"
    end

    if not self._instancesProperties then
        return {}, "No InstancesProperties table found"
    end

    -- :: collect classes
    local classes = {}
    for name in pairs(self._instancesProperties) do
        table.insert(classes, name)
    end

    -- :: sorting it in alphabetical order
    table.sort(classes)
    return classes
end

-- :: fetch api‑dump json (two requests: version then dump)
function Properties._fetchApiDump(self: Properties): ({any}?, string?)
    -- :: 1/2 – get latest engine version string
    local success, response = pcall(function()
        return HttpService:GetAsync(`{self._api}/version`)
    end)
    
    if not success then
        return nil, `Failed to fetch Roblox Version: {tostring(response)}`
    end

    -- :: 2/2 – request actual api‑dump for that version
    local url = `{self._api}/api-dump?version={response}`
    local success_dump, response_dump = pcall(function()
        return HttpService:GetAsync(url)
    end)
    
    if not success_dump then
        return nil, `API dump request failed: {tostring(response_dump)}`
    end
    
    -- :: decode json
    local success_data, data = pcall(HttpService.JSONDecode, HttpService, response_dump)
    if not success_data then
        return nil, `Failed to parse API dump: {tostring(data)}`
    end
    
    return data, nil
end

-- :: build class tree with own properties
function Properties._buildDerivedStructure(self: Properties, apiData: { [string]: any }): ({ [string]: any? }?)
    -- :: iterate every class definition
    for _, class_data in ipairs(apiData.Classes) do
        local className: string = class_data.Name
        local superclass = if class_data.Superclass ~= "<<<ROOT>>>" then class_data.Superclass else nil

        self._classes[className] = {
            Superclass = superclass,
            Properties = {},
            Derived = {}
        }

        -- :: collect property members
        for _, member in ipairs(class_data.Members) do
            if member.MemberType == "Property" then
                -- :: ignore deprecated ones
                if self._deprecatedProperties[member.Name] then
                    continue 
                end
                table.insert(self._classes[className].Properties :: {string}, member.Name)
            end
        end
    end

    -- :: build parent‑child links
    local rootClasses = {}
    for class_name, class_data in pairs(self._classes) do
        if not class_data.Superclass then
            rootClasses[class_name] = class_data
        else
            local superclass = self._classes[class_data.Superclass]
            if (not superclass) or (not superclass.Derived) then
                continue
            end
            superclass.Derived[class_name] = class_data
        end
    end

    -- :: deep copy helper so outside cannot mutate cache
    local function convertClass(classData: any): (any)
        local result = {
            Properties = classData.Properties or {},
            Derived = {}
        }
        
        for derived_name, derived_data in pairs(classData.Derived) do
            result.Derived[derived_name] = convertClass(derived_data)
        end
        return result
    end

    local derivedStructure = {}
    for class_name, class_data in pairs(rootClasses) do
        derivedStructure[class_name] = convertClass(class_data)
    end

    return derivedStructure
end

function Properties._buildPropertiesTable(self: Properties, derivedStructure: { [string]: any? })
    local function processType(typeName: string, typeData: any, parsedProps: {string}?): ({string}?)
        -- :: clone lists to avoid mutation
        local currentProps = if typeData.Properties then table.clone(typeData.Properties) else {}
        local allProps = if parsedProps then table.clone(parsedProps) :: {} else {}

        -- :: add own props not yet in inherited list
        for _, property in ipairs(currentProps) do
            if table.find(allProps, property) then
                continue
            end
            table.insert(allProps, property)
        end

        if not self._instancesProperties then
            return nil
        end
        self._instancesProperties[typeName] = allProps
        
        -- :: recurse into derived classes
        if typeData.Derived then
            for derivedName, derivedDef in pairs(typeData.Derived) do
                processType(derivedName, derivedDef, allProps)
            end
        end

        return allProps
    end

    -- :: start recursion for each root
    for class_name, class_data in pairs(derivedStructure) do
        processType(class_name, class_data, nil)
    end
end

-- :: ensure lazy initialization
function Properties._isInitialized(self: Properties): boolean
    -- :: already done
    if self._initialized then
        return true
    end

    -- :: if another coroutine in progress, just wait
    if self._initializing then
        repeat task.wait()
        until self._initialized
        return true
    end

    -- :: fetching and preparing everything
    self._initializing = true
    local success, err = pcall(function()
        local apiData = self:_fetchApiDump() :: {}
        local derivedStructure = self:_buildDerivedStructure(apiData)

        if (apiData) and (derivedStructure) then
            self:_buildPropertiesTable(derivedStructure)
            self._initialized = true
        end
    end)

    if not success then
        -- :: warn if not success
        warn(`Properties module initialization failed: {err}`)
        return false
    end
    
    -- :: finally finished initializing
    self._initializing = false
    return true
end

type Properties = typeof(Properties)
task.defer(function()
    Properties:_isInitialized()
end)

return Properties

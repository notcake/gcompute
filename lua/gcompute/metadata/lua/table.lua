local self = {}
GCompute.Lua.Table = GCompute.MakeConstructor (self, GCompute.INamespace)

--- @param name The name of this namespace
function self:ctor (name, table)
	self.Value = table
	if type (self.Value) ~= "table" then
		self.Table = self.Value:GetTable ()
	else
		self.Table = table
	end
	
	self.Populated = false
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	
	if self.MergedLocalScope then
		self.MergedLocalScope:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:GetDisplayText ()
	if type (self.Value.ClassName) == "string" then
	return self:GetName () .. " (" .. type (self.Value) .. ":" .. tostring (self.Value.ClassName) .. ")"
	end
	return self:GetName () .. " (" .. type (self.Value) .. ")"
end

function self:GetEnumerator ()
	self:Populate ()
	
	local next, tbl, key = pairs (self.Members)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

--- Returns the definition object of a member object
-- @param name The name of the member object
-- @return The definition object for the given member object
function self:GetMember (name)
	self:Populate ()
	return self.Members [name]
end

--- Returns the metadata of a member object
-- @param name The name of the member object
-- @return The MemberInfo object for the given member object
function self:GetMemberMetadata (name)
	self:Populate ()
	return self.MemberMetadata [name]
end

--- Returns whether this namespace definition has no members
-- @return A boolean indicating whether this namespace definition has no members
function self:IsEmpty ()
	if not self.Populated then
		return next (self.Table) == nil
	end
	return next (self.Members) == nil
end

--- Returns whether a member with the given name exists
-- @param name The name of the member whose existance is being checked
-- @return A boolean indicating whether a member with the given name exists
function self:MemberExists (name)
	self:Populate ()
	return self.MemberMetadata [name] and true or false
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespaceDefinition = "[Namespace] " .. (self:GetName () or "[Unnamed]")
	
	if not self:IsEmpty () then
		namespaceDefinition = namespaceDefinition .. "\n{"
		
		for name, memberDefinition, memberMetadata in self:GetEnumerator () do
			namespaceDefinition = namespaceDefinition .. "\n    " .. memberDefinition:ToString ():gsub ("\n", "\n    ")
		end
		namespaceDefinition = namespaceDefinition .. "\n}"
	else
		namespaceDefinition = namespaceDefinition .. " { }"
	end
	
	return namespaceDefinition
end

-- Internal, do not call
function self:Populate ()
	if self.Populated then return end
	self.Populated = true
	
	local count = 0
	for k, v in pairs (self.Table) do
		if count > 200 then break end
		
		count = count + 1
		local t = type (v)
		local metatable = debug.getmetatable (v)
		if type (metatable) ~= "table" then metatable = nil end
		
		local objectDefinition
		if t == "function" then
			objectDefinition = GCompute.Lua.Function (tostring (k), v)
		elseif t == "table" or (metatable and metatable.GetTable) then
			objectDefinition = GCompute.Lua.Table (tostring (k), v)
		else
			objectDefinition = GCompute.Lua.Variable (tostring (k), v)
		end
		if objectDefinition then
			objectDefinition:SetContainingNamespace (self)
		end
		self.Members [tostring (k)] = objectDefinition
	end
end
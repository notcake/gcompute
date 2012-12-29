local self = {}
GCompute.Lua.Table = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this namespace
function self:ctor (name, table)
	self.Value = table
	if self.Value == nil then
	elseif type (self.Value) ~= "table" then
		if type (self.Value.IsValid) == "function" then
			self.Table = self.Value:IsValid () and self.Value:GetTable () or {}
		else
			self.Table = self.Value:GetTable ()
		end
	else
		self.Table = table
	end
	
	self.Namespace = GCompute.Lua.TableNamespace (self.Table)
	self.Namespace:SetDefinition (self)
end

-- Table
local forwardedFunctions =
{
	"GetEnumerator",
	"GetMember",
	"IsEmpty",
	"MemberExists"
}

for _, functionName in ipairs (forwardedFunctions) do
	self [functionName] = function (self, ...)
		return self.Namespace [functionName] (self.Namespace, ...)
	end
end

-- Definition
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

function self:IsNamespace ()
	return true
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespaceDefinition = "[Namespace] " .. (self:GetName () or "[Unnamed]")
	
	if not self:IsEmpty () then
		namespaceDefinition = namespaceDefinition .. "\n{"
		
		for name, memberDefinition in self:GetEnumerator () do
			namespaceDefinition = namespaceDefinition .. "\n    " .. memberDefinition:ToString ():gsub ("\n", "\n    ")
		end
		namespaceDefinition = namespaceDefinition .. "\n}"
	else
		namespaceDefinition = namespaceDefinition .. " { }"
	end
	
	return namespaceDefinition
end
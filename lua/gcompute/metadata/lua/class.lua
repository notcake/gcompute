local self = {}
GCompute.Lua.Class = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this class
function self:ctor (name, table)
	self.Value = table
	self.Table = table
	
	self.Namespace = GCompute.Lua.ClassNamespace (self.Table)
	self.Namespace:SetDefinition (self)
	
	if type (self.Table.ctor) == "function" then
		self.Namespace:AddConstructor (GCompute.Lua.Constructor (self:GetName (), self.Table.ctor))
	end
end

-- Class
local forwardedFunctions =
{
	"GetConstructor",
	"GetConstructorCount",
	"GetConstructorEnumerator",
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

function self:GetTypeArgumentList ()
	return GCompute.EmptyTypeArgumentList
end

function self:GetTypeParameterList ()
	return GCompute.EmptyTypeParameterList
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	
	return memoryUsageReport
end

function self:GetDisplayText ()
	return self:GetName ()
end

function self:IsClass ()
	return true
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespaceDefinition = "[Class] " .. (self:GetName () or "[Unnamed]")
	
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
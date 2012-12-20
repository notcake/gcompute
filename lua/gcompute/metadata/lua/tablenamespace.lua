local self = {}
GCompute.Lua.TableNamespace = GCompute.MakeConstructor (self, GCompute.Namespace)

function self:ctor (table)
	self.Table = table
	self.Populated = false
end

local forwardedFunctions =
{
	"GetEnumerator",
	"GetMember",
	"IsEmpty",
	"MemberExists"
}

for _, functionName in ipairs (forwardedFunctions) do
	self [functionName] = function (self, ...)
		self:Populate ()
		return self.__base [functionName] (self, ...)
	end
end

function self:SetDefinition (objectDefinition)
	self.Definition = objectDefinition
	
	for _, member in pairs (self.Members) do
		self:SetupMemberHierarchy (member)
	end
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
			self:SetupMemberHierarchy (objectDefinition)
		end
		self.Members [tostring (k)] = objectDefinition
	end
end
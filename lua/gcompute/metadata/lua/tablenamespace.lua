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
	
	if not self.Table then return end
	
	local explored = {}
	local t = self.Table
	while t and not explored [t] and type (t) == "table" do
		self:PopulateFromTable (t, 200)
		explored [t] = true
		
		t = t and getmetatable (t)
		t = t and t.__index
	end
end

function self:PopulateFromTable (t, limit)
	limit = limit or 200
	
	local count = 0
	for k, v in pairs (t) do
		if count >= limit then break end
		
		local name = tostring (k)
		
		if not self.Members [name] then
			count = count + 1
			
			local t = type (v)
			local metatable = debug.getmetatable (v)
			if type (metatable) ~= "table" then metatable = nil end
			
			local objectDefinition
			if t == "function" then
				objectDefinition = GCompute.Lua.Function (name, v)
			elseif t == "table" or (metatable and metatable.GetTable) then
				objectDefinition = GCompute.Lua.Table (name, v)
			else
				objectDefinition = GCompute.Lua.Variable (name, v)
			end
			if objectDefinition then
				self:SetupMemberHierarchy (objectDefinition)
			end
			self.Members [name] = objectDefinition
		end
	end
end
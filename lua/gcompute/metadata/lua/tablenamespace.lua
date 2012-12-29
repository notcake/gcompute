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

function self:GetMember (name)
	self:ResolveMember (name)
	return self.Members [name]
end

function self:MemberExists (name)
	self:ResolveMember (name)
	return self.Members [name] and true or false
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
			
			self:ResolveMemberFromTable (t, name)
		end
	end
end

function self:ResolveMember (name)
	if self.Members [name] then return end
	
	if not self.Table then return end
	
	local explored = {}
	local t = self.Table
	while t and not explored [t] and type (t) == "table" do
		if self:ResolveMemberFromTable (t, name) then return end
		explored [t] = true
		
		t = t and getmetatable (t)
		t = t and t.__index
	end
end

function self:ResolveMemberFromTable (t, name)
	local member = t [name]
	if not member then return false end
	
	local memberType = type (member)
	
	local metatable = debug.getmetatable (member)
	if type (metatable) ~= "table" then metatable = nil end
	
	local objectDefinition
	if memberType == "function" then
		objectDefinition = GCompute.Lua.Function (name, member)
	elseif memberType == "table" or (metatable and metatable.GetTable) then
		objectDefinition = GCompute.Lua.Table (name, member)
	else
		objectDefinition = GCompute.Lua.Variable (name, member)
	end
	if objectDefinition then
		self:SetupMemberHierarchy (objectDefinition)
	end
	self.Members [name] = objectDefinition
	
	return true
end
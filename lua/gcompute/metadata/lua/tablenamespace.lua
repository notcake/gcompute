local self = {}
GCompute.Lua.TableNamespace = GCompute.MakeConstructor (self, GCompute.ClassNamespace)
local base = GCompute.GetMetaTable (GCompute.ClassNamespace)

function self:ctor (table)
	self.Table = table
	self.Populated = false
end

local forwardedFunctions =
{
	"GetEnumerator",
	"GetMember",
	"MemberExists"
}

for _, functionName in ipairs (forwardedFunctions) do
	self [functionName] = function (self, ...)
		self:Populate ()
		return base [functionName] (self, ...)
	end
end

function self:GetMember (name)
	self:ResolveMember (name)
	return self.Members [name]
end

function self:IsClassNamespace ()
	return false
end

function self:IsEmpty ()
	if not self.Table then return true end
	return next (self.Table) == nil
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
function self:CheckParent (name, table)
	local declaringObject = self:GetDefinition ()
	while declaringObject do
		if declaringObject:GetNamespace ().Table == table and
		   declaringObject:GetName () == name then
			return declaringObject
		end
		declaringObject = declaringObject:GetDeclaringObject ()
	end
end

function self:Populate ()
	if self.Populated then return end
	self.Populated = true
	
	if not self.Table then return end
	
	if self.Table == _G then
		for k, v in pairs (self.Table) do
			if type (v) == "table" then
				self:ResolveMember (k)
			end
		end
	end
	
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
		
		local cleanName = tostring (k)
		
		if not self.Members [cleanName] then
			count = count + 1
			
			self:ResolveMemberFromTable (t, k)
		end
	end
end

function self:ResolveMember (name)
	local cleanName = tostring (name)
	
	if self.Members [cleanName] then return end
	
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
	local cleanName = tostring (name)
	
	local member = t [name]
	if member == nil then return false end
	
	local memberType = type (member)
	
	local metatable = getmetatable (member)
	if type (metatable) ~= "table" then metatable = nil end
	
	local objectDefinition
	if memberType == "function" then
		local firstUpvalueName, firstUpvalue = debug.getupvalue (member, 1)
		if firstUpvalueName == "metatable" and
		   type (firstUpvalue) == "table" and
		   not debug.getupvalue (member, 2) then
			objectDefinition = self:CheckParent (cleanName, firstUpvalue)
			objectDefinition = objectDefinition or GCompute.Lua.Class (cleanName, firstUpvalue)
		else
			objectDefinition = GCompute.Lua.Function (cleanName, member)
		end
	elseif memberType == "table" or (metatable and metatable.GetTable) then
		objectDefinition = self:CheckParent (cleanName, member)
		objectDefinition = objectDefinition or GCompute.Lua.Table (cleanName, member)
	else
		objectDefinition = GCompute.Lua.Variable (cleanName, member)
	end
	if objectDefinition then
		self:SetupMemberHierarchy (objectDefinition)
	end
	self.Members [cleanName] = objectDefinition
	
	return true
end

function self:SetupMemberHierarchy (objectDefinition)
	if not objectDefinition then return end
	if objectDefinition == self:GetDefinition () then return end
	local declaringObject = self:GetDefinition ()
	while declaringObject do
		if declaringObject == objectDefinition then return end
		declaringObject = declaringObject:GetDeclaringObject ()
	end
	
	base.SetupMemberHierarchy (self, objectDefinition)
end
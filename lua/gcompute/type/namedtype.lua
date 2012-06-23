local self = {}
local ctor = GCompute.MakeConstructor (self)

function GCompute.NamedType (typeName)
	if type (typeName) == "table" and typeName.ParsedTypeName then
		return typeName
	end
	return ctor (typeName)
end

function self:ctor (typeName)
	self.TypeName = typeName
	self.ParsedTypeName = typeName
	self.Type = nil
	self.Resolved = false
	
	if type (typeName) == "string" then
		self.ParsedTypeName = GCompute.TypeParser:Root (typeName)
	elseif typeName == nil then
		GCompute.Error ("NamedType:ctor : typeName is not allowed to be nil.")
	elseif typeName.ParsedTypeName then
		self.TypeName = typeName.TypeName
		self.ParsedTypeName = typeName.ParsedTypeName
		self.Type = typeName.Type
		self.Resolved = typeName.Resolved
	else
		self.TypeName = self.ParsedTypeName:ToString ()
	end
end

function self:GetType ()
	return self.Type ()
end

function self:GetTypeName ()
	return self.TypeName
end

function self:IsResolved ()
	return self.Resolved
end

function self:Resolve (simpleNameResolver)
	simpleNameResolver = simpleNameResolver or GCompute.SimpleNameResolver ()
	simpleNameResolver:ProcessStatement (self.ParsedTypeName)
	
	-- Should only have 1 match
	local matches = {}
	for i = 1, self.ParsedTypeName.NameResolutionResults:GetResultCount () do
		local result = self.ParsedTypeName.NameResolutionResults:GetResult (i)
		if result.Metadata:GetMemberType () == GCompute.MemberTypes.Namespace then
			matches [#matches + 1] = result.Result
		end
	end
	
	if #matches == 0 then
		ErrorNoHalt ("NamedType:Resolve : No matches for " .. self.QualifiedName .. ".\n")
	elseif #matches == 1 then
		self:SetType (matches [1])
	else
		ErrorNoHalt ("NamedType:Resolve : Too many matches for " .. self.QualifiedName .. ".\n")
		ErrorNoHalt (self.ParsedTypeName.NameResolutionResults:ToString () .. "\n")
	end
end

function self:SetType (type)
	self.Type = type
	self.Resolved = true
end

function self:ToString ()
	if not self:IsResolved () then
		return "[Unresolved] " .. self.TypeName
	end
	return self.TypeName
end
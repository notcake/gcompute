local self = {}
GCompute.UsingDirective = GCompute.MakeConstructor (self)

function self:ctor (qualifiedName)
	self.QualifiedName = qualifiedName
	self.ParsedQualifiedName = qualifiedName
	self.NamespaceDefinition = nil
	self.Resolved = false
	
	if type (qualifiedName) == "string" then
		self.ParsedQualifiedName = GCompute.TypeParser:Root (qualifiedName)
	else
		self.QualifiedName = self.ParsedQualifiedName:ToString ()
	end
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:GetQualifiedName ()
	return self.QualifiedName
end

function self:IsResolved ()
	return self.Resolved
end

function self:Resolve (simpleNameResolver)
	simpleNameResolver = simpleNameResolver or GCompute.SimpleNameResolver ()
	simpleNameResolver:ProcessStatement (self.ParsedQualifiedName)
	
	-- Should only have 1 match
	local matches = {}
	for i = 1, self.ParsedQualifiedName.NameResolutionResults:GetResultCount () do
		local result = self.ParsedQualifiedName.NameResolutionResults:GetResult (i)
		if result.Metadata:GetMemberType () == GCompute.MemberTypes.Namespace then
			matches [#matches + 1] = result.Result
		end
	end
	
	if #matches == 0 then
		ErrorNoHalt ("UsingDirective:Resolve : No matches for " .. self.QualifiedName .. ".\n")
	elseif #matches == 1 then
		self:SetNamespace (matches [1])
	else
		ErrorNoHalt ("UsingDirective:Resolve : Too many matches for " .. self.QualifiedName .. ".\n")
		ErrorNoHalt (self.ParsedQualifiedName.NameResolutionResults:ToString () .. "\n")
	end
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
	self.Resolved = true
end

function self:SetQualifiedName (qualifiedName)
	self.QualifiedName = qualifiedName
end

function self:ToString ()
	return "using " .. self.QualifiedName .. ";"
end
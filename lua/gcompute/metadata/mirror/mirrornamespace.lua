local self = {}
GCompute.MirrorNamespace = GCompute.MakeConstructor (self, GCompute.ClassNamespace)

function self:ctor ()
	self.SourceNamespaces = {}
end

function self:AddSourceNamespace (namespace)
	self.SourceNamespaces [#self.SourceNamespaces + 1] = namespace
	
	-- Merge in namespaces, overloaded classes, etc which we have
	-- already resolved
	for name, member in self:GetEnumerator () do
		if member:IsNamespace () then
			if namespace:GetMember (name) then
				self:MergeNamespace (name, namespace:GetMember (name))
			end
		elseif member:IsOverloadedClass () then
			if namespace:GetMember (name) then
				self:MergeOverloadedClass (name, namespace:GetMember (name))
			end
		elseif member:IsOverloadedMethod () then
			if namespace:GetMember (name) then
				self:MergeOverloadedMethod (name, namespace:GetMember (name))
			end
		end
	end
	
	if namespace:IsClassNamespace () then
		-- Import constructors
		for constructor in namespace:GetConstructorEnumerator () do
			self.Constructors [#self.Constructors + 1] = constructor
		end
		
		-- Import explicit casts
		for explicitCast in namespace:GetExplicitCastEnumerator () do
			self.ExplicitCasts [#self.ExplicitCasts + 1] = explicitCast
		end
		
		-- Import implicit casts
		for implicitCast in namespace:GetImplicitCastEnumerator () do
			self.ImplicitCasts [#self.ImplicitCasts + 1] = implicitCast
		end
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

-- Internal, do not call
function self:MergeOverloadedClass (name, overloadedClass)
	if not overloadedClass then return end
	if not self.Members [name] then
		self.Members [name] = GCompute.MirrorOverloadedClassDefinition (name)
		self:SetupMemberHierarchy (self.Members [name])
	end
	self.Members [name]:AddSourceOverloadedClass (overloadedClass)
end

function self:MergeOverloadedMethod (name, overloadedMethod)
	if not overloadedMethod then return end
	if not self.Members [name] then
		self.Members [name] = GCompute.MirrorOverloadedMethodDefinition (name)
		self:SetupMemberHierarchy (self.Members [name])
	end
	self.Members [name]:AddSourceOverloadedMethod (overloadedMethod)
end

function self:MergeNamespace (name, namespaceDefinition)
	if not namespaceDefinition then return end
	if not self.Members [name] then
		self.Members [name] = GCompute.MirrorNamespaceDefinition (name)
		self:SetupMemberHierarchy (self.Members [name])
		self.Members [name]:SetNamespaceType (namespaceDefinition:GetNamespaceType ())
	end
	self.Members [name]:AddSourceNamespace (namespaceDefinition)
end

--- Looks up a member with the given name in all of the source namespaces and adds it to this MirrorNamespace's table of members
-- @param name The name of the member to be looked up
function self:ResolveMember (name)
	if self.Members [name] then return end

	local matchNamespaces = {}
	local matchObjects = {}
	for _, namespace in ipairs (self.SourceNamespaces) do
		if namespace:MemberExists (name) and
		   not namespace:GetMember (name):IsFileStatic () then
			matchNamespaces [#matchNamespaces + 1] = namespace
			matchObjects [#matchObjects + 1] = namespace:GetMember (name)
		end
	end
	
	if #matchObjects == 0 then return end
	
	-- Assume that they are all the same type
	if matchObjects [1]:IsAlias () then
		self:AddAlias (name, matchObjects [1]:UnwrapAlias ():GetCorrespondingDefinition (self:GetGlobalNamespace ()))
	elseif matchObjects [1]:IsVariable () then
		-- TODO: Fix this
		-- The type of the source VariableDefinition may be a DeferredObjectResolution,
		-- for which GetCorrespondingDefinition should not be implemented.
		self.Members [name] = matchObjects [1]
		-- self:AddVariable (name, matchObjects [1]:GetType ():GetCorrespondingDefinition (self:GetGlobalNamespace ()))
	elseif matchObjects [1]:IsOverloadedMethod () then
		for _, overloadedMethod in ipairs (matchObjects) do
			self:MergeOverloadedMethod (name, overloadedMethod)
		end
	elseif matchObjects [1]:IsOverloadedClass () then
		for _, overloadedClass in ipairs (matchObjects) do
			self:MergeOverloadedClass (name, overloadedClass)
		end
	elseif matchObjects [1]:IsNamespace () then
		for _, namespaceDefinition in ipairs (matchObjects) do
			self:MergeNamespace (name, namespaceDefinition)
		end
	else
		ErrorNoHalt ("MirrorNamespace:ResolveMember : Unhandled member type on " .. matchObjects [1]:GetFullName () .. ".\n")
	end
end
local self = {}
GCompute.INamespace = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

function self:ctor ()
	self.Members = {}
	self.TypeSystem = nil
	
	self.ContainingFunction = nil
end

function self:GetContainingFunction ()
	return self.ContainingFunction
end

function self:GetCorrespondingDefinition (globalNamespace)
	if not self:GetContainingNamespace () then
		return globalNamespace
	end
	
	local leftNamespace = self:GetContainingNamespace ():GetCorrespondingDefinition (globalNamespace)
	return leftNamespace:GetMember (self:GetName ())
end

function self:GetEnumerator ()
	local next, tbl, key = pairs (self.Members)
	return function ()
		key = next (tbl, key)
		return key, tbl [key], self.MemberMetadata [key]
	end
end

--- Returns the definition object of a member object
-- @param name The name of the member object
-- @return The definition object for the given member object
function self:GetMember (name)
	GCompute.Error ("INamespace:GetMember : Not implemented. (" .. self:GetFullName () .. "." .. name .. ")")
end

--- Returns the metadata of a member object
-- @param name The name of the member object
-- @return The MemberInfo object for the given member object
function self:GetMemberMetadata (name)
	GCompute.Error ("INamespace:GetMemberMetadata : Not implemented. (" .. self:GetFullName () .. "." .. name .. ")")
end

function self:GetTypeSystem ()
	if not self.TypeSystem then
		self.TypeSystem = self:GetContainingNamespace ():GetTypeSystem ()
	end
	return self.TypeSystem
end

--- Returns whether this namespace definition has no members
-- @return A boolean indicating whether this namespace definition has no members
function self:IsEmpty ()
	GCompute.Error ("INamespace:IsEmpty : Not implemented. (" .. self:GetFullName () .. ")")
end

function self:IsNamespace ()
	return true
end

--- Returns whether a member with the given name exists
-- @param name The name of the member whose existance is being checked
-- @return A boolean indicating whether a member with the given name exists
function self:MemberExists (name)
	GCompute.Error ("INamespace:MemberExists : Not implemented. (" .. self:GetFullName () .. "." .. name .. ")")
end

function self:SetContainingFunction (containingFunction)
	self.ContainingFunction = containingFunction
end

function self:SetTypeSystem (typeSystem)
	self.TypeSystem = typeSystem
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
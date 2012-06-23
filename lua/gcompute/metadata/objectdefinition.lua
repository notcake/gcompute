local self = {}
GCompute.ObjectDefinition = GCompute.MakeConstructor (self)

--- @param name The name of this object
function self:ctor (name)
	self.Name = name
	self.ContainingNamespace = nil
	
	self.FileStatic = false
	self.MemberStatic = false
	self.LocalStatic = false
end

--- Gets the namespace definition containing this object
-- @return The NamespaceDefinition containing this object
function self:GetContainingNamespace ()
	return self.ContainingNamespace
end

--- Gets the name of this object
-- @return The name of this object
function self:GetName ()
	return self.Name
end

--- Gets whether this object is inaccessible from code in other files
-- @return A boolean indicating whether this object is inaccessible from code in other files
function self:IsFileStatic ()
	return self.FileStatic
end

--- Gets whether this local object's state is preserved between function calls
-- @return A boolean indicating whether this object's state is preserved between function calls
function self:IsLocalStatic ()
	return self.LocalStatic
end

--- Gets whether this object is shared between all instances of a type
-- @return A boolean indicating whether this object is shared between all instances of a type
function self:IsMemberStatic ()
	return self.MemberStatic
end

--- Sets the containing namespace definition of this object
-- @param containingNamespaceDefinition The NamespaceDefinition containing this object
function self:SetContainingNamespace (containingNamespaceDefinition)
	self.ContainingNamespace = containingNamespaceDefinition
end

--- Sets whether this object is inaccessible from code in other files
-- @param fileStatic A boolean indicating whether this object is inaccessible from code in other files
function self:SetFileStatic (fileStatic)
	self.FileStatic = fileStatic
	return self
end

--- Sets whether this local object's state is preserve between function calls
-- @param localStatic A boolean indicating whether this object's state is preserved between function calls
function self:SetLocalStatic (localStatic)
	self.LocalStatic = localStatic
	return self
end

--- Sets whether this object is shared between all instances of a type
-- @param memberStatic A boolean indicating whether this object is shared between all instances of a type
function self:SetMemberStatic (memberStatic)
	self.MemberStatic = memberStatic
	return self
end

--- Returns a string representing this ObjectDefinition
-- @return A string representing this ObjectDefinition
function self:ToString ()
	return self:GetName ()
end
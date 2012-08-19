local self = {}
GCompute.ObjectDefinition = GCompute.MakeConstructor (self, GCompute.IObject)

--- @param name The name of this object
function self:ctor (name)
	self.Name = name
	self.ContainingNamespace = nil
	
	self.Metadata = nil
	
	self.FileStatic = false
	self.MemberStatic = false
	self.LocalStatic = false
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Definitions", self)
	
	return memoryUsageReport
end

function self:CreateRuntimeObject ()
	GCompute.Error ("ObjectDefinition:CreateRuntimeObject : Not implemented (" .. self:GetFullName () .. ")")
end

--- Gets the namespace definition containing this object
-- @return The NamespaceDefinition containing this object
function self:GetContainingNamespace ()
	return self.ContainingNamespace
end

--- Gets the location of this object
-- @return The location of this object
function self:GetFullName ()
	return self:GetLocation ()
end

--- Gets the location of this object
-- @return The location of this object
function self:GetLocation ()
	if self:GetContainingNamespace () then
		if self:GetContainingNamespace ():GetContainingNamespace () then
			return self:GetContainingNamespace ():GetLocation () .. "." .. self:GetShortName ()
		else
			return self:GetShortName ()
		end
	else
		return self:GetShortName ()
	end
end

--- Gets the metadata of this object
-- @return The MemberInfo for this object
function self:GetMetadata ()
	return self.Metadata
end

--- Gets the name of this object
-- @return The name of this object
function self:GetName ()
	return self.Name
end

--- Gets the short name of this object
-- @return The short name of this object
function self:GetShortName ()
	return self:GetName () or "[Unnamed]"
end

--- Returns the type of this object
-- @return A Type representing the type of this object
function self:GetType ()
	GCompute.Error (self.Name .. ":GetType : Not implemented.")
	return nil
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

--- Gets whether this object is a NamespaceDefinition
-- @return A boolean indicating whether this object is a NamespaceDefinition
function self:IsNamespace ()
	return false
end

--- Gets whether this object is an ObjectDefinition
-- @return A boolean indicating whether this object is an ObjectDefinition
function self:IsObjectDefinition ()
	return true
end

--- Gets whether this object is an OverloadedFunctionDefinition
-- @return A boolean indicating whether this object is an OverloadedFunctionDefinition
function self:IsOverloadedFunctionDefinition ()
	return false
end

--- Gets whether this object is an OverloadedTypeDefinition
-- @return A boolean indicating whether this object is an OverloadedTypeDefinition
function self:IsOverloadedTypeDefinition ()
	return false
end

--- Gets whether this object is a TypeDefinition
-- @return A boolean indicating whether this object is a TypeDefinition
function self:IsType ()
	return false
end

--- Gets whether this object is a TypeDefinition
-- @return A boolean indicating whether this object is a TypeDefinition
function self:IsTypeDefinition ()
	return false
end

--- Resolves all types
function self:ResolveTypes (globalNamespace)
	ErrorNoHalt (self:GetLocation () .. ":ResolveTypes : Not implemented.\n")
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

--- Sets the metadata for this object
-- @param metadata The MemberInfo for this object
function self:SetMetadata (metadata)
	self.Metadata = metadata
	return self
end

--- Returns a string representing this ObjectDefinition
-- @return A string representing this ObjectDefinition
function self:ToString ()
	return self:GetName ()
end
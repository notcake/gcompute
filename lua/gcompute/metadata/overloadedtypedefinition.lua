local self = {}
GCompute.OverloadedTypeDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this type
function self:ctor (name)
	self.Types = {}
end

--- Adds a type to this type group
-- @param typeParamterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
-- @return The new TypeDefinition
function self:AddType (typeParameterList)
	for i = 1, #self.Types do
		if self.Types [i]:GetTypeParameterList ():Equals (typeParameterList) then
			return self.Types [i]
		end
	end

	self.Types [#self.Types + 1] = GCompute.TypeDefinition (self:GetName (), typeParameterList)
	self.Types [#self.Types]:SetContainingNamespace (self:GetContainingNamespace ())
	return self.Types [#self.Types]
end

--- Gets the type with the given index in this type group
-- @param index The index of the type to be retrieved
-- @return The TypeDefinition with the given index
function self:GetType (index)
	return self.Types [index]
end

--- Returns the number of types in this type group
-- @return The number of types in this type group
function self:GetTypeCount ()
	return #self.Types
end

--- Gets whether this object is an OverloadedTypeDefinition
-- @return A boolean indicating whether this object is an OverloadedTypeDefinition
function self:IsOverloadedTypeDefinition ()
	return true
end

--- Resolves the types of all types in this type group
function self:ResolveTypes (globalNamespace)
	for i = 1, self:GetTypeCount () do
		self:GetType (i):ResolveTypes (globalNamespace)
	end
end

--- Returns a string representation of this type group
-- @return A string representation of this type group
function self:ToString ()
	if self:GetTypeCount () == 1 then
		return "[Type Group] " .. self:GetType (1):ToString ()
	end
	
	local typeGroup = "[Type Group (" .. self:GetTypeCount () .. ")] " .. (self:GetName () or "[Unnamed]") .. "\n"
	typeGroup = typeGroup .. "{\n"
	for i = 1, self:GetTypeCount () do
		typeGroup = typeGroup .. "    " .. self:GetType (i):ToString ():gsub ("\n", "\n    ") .. "\n"
	end
	typeGroup = typeGroup .. "}"
	return typeGroup
end
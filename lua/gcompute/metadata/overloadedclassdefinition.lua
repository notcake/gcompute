local self = {}
GCompute.OverloadedClassDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this class
function self:ctor (name)
	self.Classes = {}
end

-- Class Group
--- Adds a class to this class group
-- @param typeParamterList A TypeParameterList describing the parameters the type takes or nil if the class is non-parametric
-- @return The new ClassDefinition
function self:AddClass (typeParameterList)
	typeParameterList = GCompute.ToTypeParameterList (typeParameterList)
	
	for class in self:GetEnumerator () do
		if class:GetTypeParameterList ():Equals (typeParameterList) then
			return class
		end
	end
	
	local classDefinition = GCompute.ClassDefinition (self:GetName (), typeParameterList)
	self:GetDeclaringObject ():GetNamespace ():SetupMemberHierarchy (classDefinition)
	
	self.Classes [#self.Classes + 1] = classDefinition
	
	return classDefinition
end

--- Gets the class with the given index in this class group
-- @param index The index of the class to be retrieved
-- @return The ClassDefinition with the given index
function self:GetClass (index)
	return self.Classes [index]
end

--- Returns the number of classes in this class group
-- @return The number of classes in this class group
function self:GetClassCount ()
	return #self.Classes
end

--- Returns the class which takes 0 type parameters
function self:GetConcreteClass ()
	for class in self:GetEnumerator () do
		if class:GetTypeParameterList ():IsEmpty () then
			return class
		end
	end
	return nil
end

--- Returns the only class in this OverloadedClassDefinition or the class which takes 0 type parameters
function self:GetDefaultClass ()
	if self:GetClassCount () == 1 then
		return self:GetClass (1)
	end
	return self:GetConcreteClass ()
end

--- Gets an iterator for this class group
-- @return An iterator function returning the ClassDefinitions in this class group
function self:GetEnumerator ()
	return GLib.ArrayEnumerator (self.Classes)
end
self.GetGroupEnumerator = self.GetEnumerator

-- Definition
--- Gets whether this object is an OverloadedClassDefinition
-- @return A boolean indicating whether this object is an OverloadedClassDefinition
function self:IsOverloadedClass ()
	return true
end

--- Resolves the types of all types in this class group
function self:ResolveTypes (objectResolver, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	for class in self:GetEnumerator () do
		class:ResolveTypes (objectResolver, errorReporter)
	end
end

--- Returns a string representation of this class group
-- @return A string representation of this class group
function self:ToString ()
	if self:GetClassCount () == 1 then
		return "[Type Group] " .. self:GetClass (1):ToString ()
	end
	
	local typeGroup = "[Type Group (" .. self:GetClassCount () .. ")] " .. (self:GetName () or "[Unnamed]") .. "\n"
	typeGroup = typeGroup .. "{\n"
	for class in self:GetEnumerator () do
		typeGroup = typeGroup .. "    " .. class:ToString ():gsub ("\n", "\n    ") .. "\n"
	end
	typeGroup = typeGroup .. "}"
	return typeGroup
end

function self:Visit (namespaceVisitor, ...)
	namespaceVisitor:VisitOverloadedClass (self, ...)
	
	for class in self:GetEnumerator () do
		class:Visit (namespaceVisitor, ...)
	end
end
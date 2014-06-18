local self = {}
GCompute.OverloadedMethodDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this overloaded method
function self:ctor (name)
	self.Methods = {}
end

-- Method Group
--- Adds a method to this method group
-- @param parameterList A ParameterList describing the parameters the method takes or nil if the method takes no parameters
-- @param typeParamterList A TypeParameterList describing the type parameters the method takes or nil if the method is non-type-parametric
-- @return The new MethodDefinition
function self:AddMethod (parameterList, typeParameterList)
	local methodDefinition = GCompute.MethodDefinition (self:GetName (), parameterList, typeParameterList)
	self:GetDeclaringObject ():GetNamespace ():SetupMemberHierarchy (methodDefinition)
	
	self.Methods [#self.Methods + 1] = methodDefinition
	
	return methodDefinition
end

--- Gets an iterator for this method group
-- @return An iterator function returning the MethodDefinitions in this method group
function self:GetEnumerator ()
	return GLib.ArrayEnumerator (self.Methods)
end
self.GetGroupEnumerator = self.GetEnumerator

--- Gets the method with the given index in this method group
-- @param index The index of the method to be retrieved
-- @return The MethodDefinition with the given index
function self:GetMethod (index)
	return self.Methods [index]
end

--- Returns the number of methods in this method group
-- @return The number of methods in this method group
function self:GetMethodCount ()
	return #self.Methods
end

-- Definition
--- Gets whether this object is an OverloadedMethodDefinition
-- @return A boolean indicating whether this object is an OverloadedMethodDefinition
function self:IsOverloadedMethod ()
	return true
end

--- Resolves the types of all methods in this method group
function self:ResolveTypes (objectResolver, compilerMessageSink)
	compilerMessageSink = compilerMessageSink or GCompute.DefaultCompilerMessageSink
	
	for method in self:GetEnumerator () do
		method:ResolveTypes (objectResolver, compilerMessageSink)
	end
end

--- Returns a string representation of this method group
-- @return A string representation of this method group
function self:ToString ()
	if self:GetMethodCount () == 1 then
		return "[Method Group] " .. self:GetMethod (1):ToString ()
	end
	
	local methodGroup = "[Method Group (" .. self:GetMethodCount () .. ")] " .. (self:GetName () or "[Unnamed]") .. "\n"
	methodGroup = methodGroup .. "{\n"
	for method in self:GetEnumerator () do
		methodGroup = methodGroup .. "    " .. method:ToString ():gsub ("\n", "\n    ") .. "\n"
	end
	methodGroup = methodGroup .. "}"
	return methodGroup
end

function self:Visit (namespaceVisitor, ...)
	namespaceVisitor:VisitOverloadedMethod (self, ...)
	
	for method in self:GetEnumerator () do
		method:Visit (namespaceVisitor, ...)
	end
end
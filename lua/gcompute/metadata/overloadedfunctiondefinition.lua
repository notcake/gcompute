local self = {}
GCompute.OverloadedFunctionDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this function
function self:ctor (name)
	self.Functions = {}
end

--- Adds a function to this function group
-- @param parameterList A ParameterList describing the parameters the function takes or nil if the function takes no parameters
-- @param typeParamterList A TypeParameterList describing the type parameters the function takes or nil if the function is non-type-parametric
-- @return The new FunctionDefinition
function self:AddFunction (parameterList, typeParameterList)
	local functionDefinition = GCompute.FunctionDefinition (self:GetName (), parameterList, typeParameterList)
	functionDefinition:SetContainingNamespace (self:GetContainingNamespace ())
	
	self.Functions [#self.Functions + 1] = functionDefinition
	self.Functions [#self.Functions]:SetMetadata (GCompute.MemberInfo (self:GetName (), GCompute.MemberTypes.Method))
	
	return functionDefinition
end

--- Gets an iterator for this function group
-- @return An iterator function returning the FunctionDefinitions in this FunctionGroup
function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Functions [i]
	end
end

--- Gets the function with the given index in this function group
-- @param index The index of the function to be retrieved
-- @return The FunctionDefinition with the given index
function self:GetFunction (index)
	return self.Functions [index]
end

--- Returns the number of functions in this function group
-- @return The number of functions in this function group
function self:GetFunctionCount ()
	return #self.Functions
end

--- Gets whether this object is an OverloadedFunctionDefinition
-- @return A boolean indicating whether this object is an OverloadedFunctionDefinition
function self:IsOverloadedFunctionDefinition ()
	return true
end

--- Resolves the types of all functions in this function group
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	for i = 1, self:GetFunctionCount () do
		self:GetFunction (i):ResolveTypes (globalNamespace, errorReporter)
	end
end

--- Returns a string representation of this function group
-- @return A string representation of this function group
function self:ToString ()
	if self:GetFunctionCount () == 1 then
		return "[Function Group] " .. self:GetFunction (1):ToString ()
	end
	
	local functionGroup = "[Function Group (" .. self:GetFunctionCount () .. ")] " .. (self:GetName () or "[Unnamed]") .. "\n"
	functionGroup = functionGroup .. "{\n"
	for i = 1, self:GetFunctionCount () do
		functionGroup = functionGroup .. "    " .. self:GetFunction (i):ToString ():gsub ("\n", "\n    ") .. "\n"
	end
	functionGroup = functionGroup .. "}"
	return functionGroup
end
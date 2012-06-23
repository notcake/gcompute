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
	self.Functions [#self.Functions + 1] = GCompute.FunctionDefinition (self:GetName (), parameterList, typeParameterList)
	self.Functions [#self.Functions]:SetContainingNamespace (self:GetContainingNamespace ())
	return self.Functions [#self.Functions]
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

--- Returns a string representation of this function group
-- @return A string representation of this function group
function self:ToString ()
	local functionGroup = self:GetName () .. " (Function Group [" .. self:GetFunctionCount () .. "])\n"
	functionGroup = functionGroup .. "{\n"
	for i = 1, self:GetFunctionCount () do
		functionGroup = functionGroup .. "    " .. self:GetFunction (i):ToString ():gsub ("\n", "\n    ") .. "\n"
	end
	functionGroup = functionGroup .. "}"
	return functionGroup
end
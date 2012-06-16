local self = {}
GCompute.FunctionDefinition = GCompute.MakeConstructor (self, GCompute.MetadataObject)

--- @param The name of this function
-- @param parameterList A ParameterList describing the parameters the function takes or nil if the function is nullary
-- @param typeParameterList A TypeParameterList describing the type parameters the function takes or nil if the function is non-type-parametric
function self:ctor (name, parameterList, typeParameterList)
	self.ParameterList = parameterList or GCompute.EmptyParameterList
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	
	self.NativeFunction = nil
end

--- Gets the native implementation of this function
-- @return The native implementation of this function
function self:GetNativeFunction ()
	return self.NativeFunction
end

--- Gets the parameter list of this function
-- @return The parameter list of this function
function self:GetParameterList ()
	return self.ParameterList
end

--- Gets the type parameter list of this function
-- @return The type parameter list of this function
function self:GetTypeParameterList ()
	return self.TypeParameterList
end

--- Sets the native implementation of this function
-- @param nativeFunction The native implementation of this function
function self:SetNativeFunction (nativeFunction)
	self.NativeFunction = nativeFunction
end
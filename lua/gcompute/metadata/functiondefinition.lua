local self = {}
GCompute.FunctionDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this function
-- @param parameterList A ParameterList describing the parameters the function takes or nil if the function takes no parameters
-- @param typeParameterList A TypeParameterList describing the type parameters the function takes or nil if the function is non-type-parametric
function self:ctor (name, parameterList, typeParameterList)
	self.ParameterList = parameterList or GCompute.EmptyParameterList
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	self.ReturnType = GCompute.NamedType ("void")
	
	if #self.ParameterList > 0 then
		self.ParameterList = GCompute.ParameterList (self.ParameterList)
	end
	if #self.TypeParameterList > 0 then
		self.TypeParameterList = GCompute.TypeParameterList (self.TypeParameterList)
	end
	
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

--- Gets the return type of this function as a NamedType
-- @return A NamedType representing the return type of this function
function self:GetReturnType ()
	return self.ReturnType
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
	return self
end

--- Sets the return type of this function
-- @param returnType The name of the return type or a NamedType
function self:SetReturnType (returnType)
	self.ReturnType = GCompute.NamedType (returnType)
	return self
end

--- Returns a string representation of this function
-- @return A string representation of this function
function self:ToString ()
	local functionDefinition = self.ReturnType and self.ReturnType:ToString () or "[Unknown Type]"
	functionDefinition = functionDefinition .. " " .. self:GetName ()
	functionDefinition = functionDefinition .. " ("
	
	local parameters = ""
	for i = 1, self:GetParameterList ():GetParameterCount () do
		if parameters ~= "" then
			parameters = parameters .. ", "
		end
		local parameterType = self:GetParameterList ():GetParameterType (i)
		local parameterName = self:GetParameterList ():GetParameterName (i)
		parameterType = parameterType and parameterType:ToString () or "[Unknown Type]"
		parameters = parameters .. parameterType
		if parameterName then
			parameters = parameters .. " " .. parameterName
		end
	end
	
	functionDefinition = functionDefinition .. parameters
	functionDefinition = functionDefinition .. ")"
	return functionDefinition
end
local self = {}
GCompute.FunctionDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this function
-- @param parameterList A ParameterList describing the parameters the function takes or nil if the function takes no parameters
-- @param typeParameterList A TypeParameterList describing the type parameters the function takes or nil if the function is non-type-parametric
function self:ctor (name, parameterList, typeParameterList)
	self.ParameterList = parameterList or GCompute.EmptyParameterList
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	self.ReturnType = GCompute.DeferredNameResolution ("void")
	
	if #self.ParameterList > 0 then
		self.ParameterList = GCompute.ParameterList (self.ParameterList)
	end
	if #self.TypeParameterList > 0 then
		self.TypeParameterList = GCompute.TypeParameterList (self.TypeParameterList)
	end
	
	self.FunctionDeclaration = nil
	self.NativeString = nil
	self.NativeFunction = nil
end

--- Gets the FunctionDeclaration syntax tree node corresponding to this function
-- @return The FunctionDeclaration corresponding to this function
function self:GetFunctionDeclaration ()
	return self.FunctionDeclaration
end

--- Gets the native implementation of this function
-- @return The native implementation of this function
function self:GetNativeFunction ()
	return self.NativeFunction
end

--- Gets the native inline code for this function
-- @return The native inline code for this function
function self:GetNativeString ()
	return self.NativeString
end

--- Gets the parameter list of this function
-- @return The parameter list of this function
function self:GetParameterList ()
	return self.ParameterList
end

--- Gets the return type of this function as a DeferredNameResolution or Type
-- @return A DeferredNameResolution or Type representing the return type of this function
function self:GetReturnType ()
	return self.ReturnType
end

--- Gets the short name of this function
-- @return The short name of this function
function self:GetShortName ()
	if self:GetTypeParameterList ():IsEmpty () then
		return self:GetName () or "[Unnamed]"
	else
		return (self:GetName () or "[Unnamed]") .. " " .. self:GetTypeParameterList ():ToString ()
	end
end

--- Gets the type of this function
-- @return A FunctionType representing the type of this function
function self:GetType ()
	if self:IsMemberFunction () then
		local parameterList = GCompute.ParameterList ()
		parameterList:AddParameter (self:GetContainingNamespace (), "self")
		parameterList:AddParameters (self:GetParameterList ())
		return GCompute.FunctionType (self:GetReturnType (), parameterList)
	else
		return GCompute.FunctionType (self:GetReturnType (), self:GetParameterList ())
	end
end

--- Gets the type parameter list of this function
-- @return The type parameter list of this function
function self:GetTypeParameterList ()
	return self.TypeParameterList
end

--- Gets whether this function is a member function
-- @return A boolean indicating whether this function is a member function
function self:IsMemberFunction ()
	if not self:GetContainingNamespace () then return false end
	if self:IsMemberStatic () then return false end
	return self:GetContainingNamespace ():IsType ()
end

--- Resolves the return type and paremeter types of this function
function self:ResolveTypes (globalNamespace)
	if self:GetReturnType () then
		self:GetReturnType ():Resolve ()
	end
	self:GetParameterList ():ResolveTypes (globalNamespace, self:GetContainingNamespace ())
end

--- Sets the FunctionDeclaration syntax tree node corresponding to this function
-- @param functionDeclaration The FunctionDeclaration corresponding to this function
function self:SetFunctionDeclaration (functionDeclaration)
	self.FunctionDeclaration = functionDeclaration
end

--- Sets the native implementation of this function
-- @param nativeFunction The native implementation of this function
function self:SetNativeFunction (nativeFunction)
	self.NativeFunction = nativeFunction
	return self
end

--- Sets the native inline code for this function
-- @param nativeString The native inline code for this function
function self:SetNativeString (nativeString)
	self.NativeString = nativeString
	return self
end

--- Sets the return type of this function
-- @param returnType The return type as a string or DeferredNameResolution or Type
function self:SetReturnType (returnType)
	if type (returnType) == "string" then
		self.ReturnType = GCompute.DeferredNameResolution (returnType, nil, nil, self:GetContainingNamespace ())
	elseif returnType:IsDeferredNameResolution () then
		self.ReturnType = returnType
	elseif returnType:IsType () then
		self.ReturnType = returnType
	else
		GCompute.Error ("FunctionDefinition:SetReturnType : returnType was not a string, DeferredNameResolution or Type")
	end
	return self
end

--- Returns a string representation of this function
-- @return A string representation of this function
function self:ToString ()
	local functionDefinition = self.ReturnType and self.ReturnType:ToString () or "[Unknown Type]"
	functionDefinition = functionDefinition .. " " .. self:GetName ()
	if not self:GetTypeParameterList ():IsEmpty () then
		functionDefinition = functionDefinition .. " " .. self:GetTypeParameterList ():ToString ()
	end
	functionDefinition = functionDefinition .. " " .. self:GetParameterList ():ToString ()
	return functionDefinition
end
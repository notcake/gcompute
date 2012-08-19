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

--- Returns the compatibility rating of the given number and types of arguments with this FunctionDefinition
-- @param argumentTypeArray An array of argument Types
-- @return A number indicating how compatible this FunctionDefinition is with the given argument type list
function self:CanAcceptArgumentTypes (argumentTypeArray)
	-- Bail out if the function cannot accept the given number of arguments
	if self:IsMemberFunction () then
		if not self.ParameterList:MatchesArgumentCount (#argumentTypeArray - 1) then return -math.huge end
	else
		if not self.ParameterList:MatchesArgumentCount (#argumentTypeArray) then return -math.huge end
	end

	-- Check first argument
	local argumentTypeArrayIndex = 1
	if self:IsMemberFunction () then
		if not argumentTypeArray [1]:CanConvertTo (self:GetContainingNamespace (), GCompute.TypeConversionMethod.ImplicitConversion) then
			print ("Argument " .. 1 .. ", " .. 0 .. ": " .. argumentTypeArray [1]:GetFullName () .. " and " .. self:GetContainingNamespace ():GetFullName ())
			return -math.huge
		end
		argumentTypeArrayIndex = 2
	end
	
	local parameterList = self:GetParameterList ()
	local parameterCount = parameterList:GetParameterCount ()
	local compatibility = 0
	
	local i = 1
	while argumentTypeArrayIndex <= #argumentTypeArray do
		local argumentType = argumentTypeArray [argumentTypeArrayIndex]:UnwrapAlias ()
		if not argumentType:CanConvertTo (parameterList:GetParameterType (i), GCompute.TypeConversionMethod.ImplicitConversion) then
			print ("Argument " .. argumentTypeArrayIndex .. ", " .. i .. ": " .. argumentTypeArray [argumentTypeArrayIndex]:GetFullName () .. " and " .. parameterList:GetParameterType (i):GetFullName ())
			return -math.huge
		end
		if i == parameterCount then
			-- vararg function, match remaining given parameter types against final defined parameter type
		else
			i = i + 1
		end
		argumentTypeArrayIndex = argumentTypeArrayIndex + 1
	end
	
	return compatibility
end

function self:CreateRuntimeObject ()
	return self
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
		if not self:GetReturnType ():IsFailedResolution () then
			self:SetReturnType (self:GetReturnType ():GetObject ())
		end
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
	else
		if returnType:IsAlias () then
			self.ReturnType = returnType
		elseif returnType:IsDeferredNameResolution () then
			self.ReturnType = returnType
		elseif returnType:IsType () then
			self.ReturnType = returnType
		else
			GCompute.Error ("FunctionDefinition:SetReturnType : returnType was not a string, DeferredNameResolution or Type")
		end
	end
	return self
end

--- Returns a string representation of this function
-- @return A string representation of this function
function self:ToString ()
	local functionDefinition = self.ReturnType and self.ReturnType:GetFullName () or "[Unknown Type]"
	if self:IsMemberFunction () then
		functionDefinition = functionDefinition .. " " .. self:GetContainingNamespace ():GetFullName () .. ":" .. self:GetName ()
	else
		functionDefinition = functionDefinition .. " " .. self:GetName ()
	end
	if not self:GetTypeParameterList ():IsEmpty () then
		functionDefinition = functionDefinition .. " " .. self:GetTypeParameterList ():ToString ()
	end
	functionDefinition = functionDefinition .. " " .. self:GetParameterList ():ToString ()
	return functionDefinition
end
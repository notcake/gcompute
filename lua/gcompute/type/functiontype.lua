local self = {}
GCompute.FunctionType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (returnType, parameterList)
	self:SetReturnType (returnType)
	self.ParameterList = parameterList or GCompute.EmptyParameterList
	
	if #self.ParameterList > 0 then
		self.ParameterList = GCompute.ParameterList (self.ParameterList)
	end
	
	self:SetNativelyAllocated (true)
end

--- Returns the compatibility rating of the given number and types of arguments with this FunctionDefinition
-- @param argumentTypeArray An array of argument Types
-- @return A boolean indicating whether this FunctionDefinition can accept the given argument type list
-- @return A number indicating how compatible this FunctionDefinition is with the given argument type list
function self:CanAcceptArgumentTypes (argumentTypeArray)
	-- Bail out if we cannot accept the given number of arguments
	if not self.ParameterList:MatchesArgumentCount (#argumentTypeArray) then return false, -math.huge end

	-- Check first argument
	local argumentTypeArrayIndex = 1
	
	local parameterList = self:GetParameterList ()
	local parameterCount = parameterList:GetParameterCount ()
	local compatibility = 0
	
	local i = 1
	while argumentTypeArrayIndex <= #argumentTypeArray do
		local argumentType = argumentTypeArray [argumentTypeArrayIndex]:UnwrapAlias ()
		local canConvert, conversionType = argumentType:CanConvertTo (parameterList:GetParameterType (i), GCompute.TypeConversionMethod.ImplicitConversion)
		if not canConvert then
			print ("Argument " .. argumentTypeArrayIndex .. ", " .. i .. ": " .. argumentTypeArray [argumentTypeArrayIndex]:GetFullName () .. " and " .. parameterList:GetParameterType (i):GetFullName ())
			return false, -math.huge
		end
		
		if conversionType == GCompute.TypeConversionMethod.Identity then
		elseif conversionType == GCompute.TypeConversionMethod.Downcast then
			compatibility = compatibility - 1
		else
			compatibility = compatibility - 1000
		end
		
		if i == parameterCount then
			-- vararg function, match remaining given parameter types against final defined parameter type
		else
			i = i + 1
		end
		argumentTypeArrayIndex = argumentTypeArrayIndex + 1
	end
	
	return true, compatibility
end

function self:Equals (otherType)
	otherType = otherType:UnwrapAlias ()
	if self == otherType then return true end
	if not otherType:IsFunctionType () then return false end
	if not self:GetReturnType ():UnwrapAlias ():Equals (otherType:GetReturnType ()) then return false end
	return self:GetParameterList ():TypeEquals (otherType:GetParameterList ())
end

function self:GetBaseType (index)
	if index == 1 then return self:GetTypeSystem ():GetTop () end
	return nil
end

function self:GetBaseTypeCount ()
	return 1
end

function self:GetFullName ()
	local returnType = self.ReturnType and self.ReturnType:GetFullName () or "[Unknown Type]"
	
	return returnType .. " " .. self:GetParameterList ():ToString ()
end

function self:GetParameterList ()
	return self.ParameterList
end

function self:GetReturnType ()
	return self.ReturnType
end

function self:GetClassDefinition ()
end

function self:IsFunctionType ()
	return true
end

function self:SetReturnType (returnType)
	if type (returnType) == "string" then
		self.ReturnType = GCompute.DeferredObjectResolution (returnType, GCompute.ResolutionObjectType.Type)
	elseif returnType:IsAlias () then
		self.ReturnType = returnType
	elseif returnType:IsDeferredObjectResolution () then
		self.ReturnType = returnType
	elseif returnType:IsType () then
		self.ReturnType = returnType
	else
		GCompute.Error ("FunctionType:SetReturnType : returnType must be a string, DeferredObjectResolution or Type")
	end
end

function self:ToString ()
	local returnType = self.ReturnType and self.ReturnType:GetFullName () or "[Unknown Type]"
	
	return returnType .. " " .. self:GetParameterList ():ToString ()
end
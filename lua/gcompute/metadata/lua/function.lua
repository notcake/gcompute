local self = {}
GCompute.Lua.Function = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

function self:ctor (name, f)
	self.Function = f
	
	self.ReturnType = nil
	self.ParameterList = GCompute.Lua.FunctionParameterList (nil, self.Function)
end

function self:GetDisplayText ()
	local displayText = ""
	if debug.getlocal (self.Function, 1) == "self" then
		displayText = displayText .. ":"
	end
	displayText = displayText .. self:GetShortName () .. " " .. self:GetParameterList ():GetRelativeName (self)
	return displayText
end

function self:GetParameterCount ()
	return self.ParameterList:GetParameterCount ()
end

function self:GetParameterList ()
	return self.ParameterList
end

function self:GetParameterName (index)
	return self.ParameterList:GetParameterName (index)
end

function self:GetReturnType ()
	return self.ReturnType
end

function self:GetShortName ()
	return self:GetName () or "[Unnamed]"
end

function self:GetType ()
	if self:IsMemberFunction () then
		local parameterList = GCompute.ParameterList ()
		parameterList:AddParameter (self:GetDeclaringType (), "self")
		parameterList:AddParameters (self:GetParameterList ())
		return self:GetTypeSystem ():CreateFunctionType (self:GetReturnType (), parameterList)
	else
		return self:GetTypeSystem ():CreateFunctionType (self:GetReturnType (), self:GetParameterList ())
	end
end

function self:GetTypeArgumentList ()
	return GCompute.EmptyTypeArgumentList
end

function self:GetTypeParameterList ()
	return GCompute.EmptyTypeParameterList
end

function self:IsMethod ()
	return true
end

function self:IsMemberFunction ()
	if not self:GetDeclaringObject () then return false end
	if self:IsMemberStatic () then return false end
	return self:GetDeclaringObject ():IsType ()
end

--- Returns a string representation of this method
-- @return A string representation of this method
function self:ToString ()
	local methodDefinition = self.ReturnType and (self.ReturnType:GetFullName () .. " ") or ""
	if self:IsMemberFunction () then
		methodDefinition = methodDefinition .. self:GetDeclaringObject ():GetFullName () .. ":" .. self:GetName ()
	else
		methodDefinition = methodDefinition .. self:GetName ()
	end
	methodDefinition = methodDefinition .. " " .. self:GetParameterList ():ToString ()
	return methodDefinition
end
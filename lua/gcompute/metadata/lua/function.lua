local self = {}
GCompute.Lua.Function = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

function self:ctor (name, f)
	self.Function = f
	
	self.ReturnType = nil
	self.ParameterList = GCompute.ParameterList ()
end

function self:GetDisplayText ()
	return self:ToString ()
end

function self:GetParameterCount ()
	return 0
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
		parameterList:AddParameter (self:GetContainingNamespace (), "self")
		parameterList:AddParameters (self:GetParameterList ())
		return GCompute.FunctionType (self:GetReturnType (), parameterList)
	else
		return GCompute.FunctionType (self:GetReturnType (), self:GetParameterList ())
	end
end

function self:GetTypeParameterList ()
	return self.TypeParameterList
end

function self:IsFunction ()
	return true
end

function self:IsMemberFunction ()
	if not self:GetContainingNamespace () then return false end
	if self:IsMemberStatic () then return false end
	return self:GetContainingNamespace ():IsType ()
end

--- Returns a string representation of this function
-- @return A string representation of this function
function self:ToString ()
	local functionDefinition = self.ReturnType and (self.ReturnType:GetFullName () .. " ") or ""
	if self:IsMemberFunction () then
		functionDefinition = functionDefinition .. self:GetContainingNamespace ():GetFullName () .. ":" .. self:GetName ()
	else
		functionDefinition = functionDefinition .. self:GetName ()
	end
	functionDefinition = functionDefinition .. " " .. self:GetParameterList ():ToString ()
	return functionDefinition
end
local self = {}
GCompute.FunctionType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (returnType, parameterList)
	self:SetReturnType (returnType)
	self.ParameterList = parameterList or GCompute.EmptyParameterList
	
	if #self.ParameterList > 0 then
		self.ParameterList = GCompute.ParameterList (self.ParameterList)
	end
end

function self:GetParameterList ()
	return self.ParameterList
end

function self:GetReturnType ()
	return self.ReturnType
end

function self:IsFunctionType ()
	return true
end

function self:SetReturnType (returnType)
	if type (returnType) == "string" then
		self.ReturnType = GCompute.DeferredNameResolution (returnType)
	elseif returnType:IsDeferredNameResolution () then
		self.ReturnType = returnType
	elseif returnType:IsType () then
		self.ReturnType = returnType
	else
		GCompute.Error ("FunctionType:SetReturnType : returnType must be a string, DeferredNameResolution or Type")
	end
end

function self:ToString ()
	local returnType = self.ReturnType and self.ReturnType:ToString () or "[Unknown Type]"
	
	return returnType .. " " .. self:GetParameterList ():ToString ()
end
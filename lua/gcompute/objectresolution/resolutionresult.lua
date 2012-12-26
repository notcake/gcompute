local self = {}
GCompute.ResolutionResult = GCompute.MakeConstructor (self)

function self:ctor (object, resultType)
	self.Object        = object
	self.ResultType    = resultType or GCompute.ResolutionResultType.Other
	if not GCompute.ResolutionResultType [self.ResultType] then
		GCompute.Error ("FAIL")
	end
	self.LocalDistance = math.huge
end

function self:GetLocalDistance ()
	return self.LocalDistance
end

function self:GetObject ()
	return self.Object
end

function self:GetResultType ()
	return self.ResultType
end

function self:IsGlobal ()
	return self.ResultType == GCompute.ResolutionResultType.Global
end

function self:IsLocal ()
	return self.ResultType == GCompute.ResolutionResultType.Local
end

function self:IsMember ()
	return self.ResultType == GCompute.ResolutionResultType.Member
end

function self:IsOther ()
	return self.ResultType == GCompute.ResolutionResultType.Other
end

function self:SetLocalDistance (localDistance)
	self.LocalDistance = localDistance
	return self
end

function self:SetObject (object)
	self.Object = object
	return self
end

function self:SetResultType (resultType)
	self.ResultType = resultType
	return self
end

function self:ToString ()
	local object = ""
	if self.Object then
		if self.Object:IsObjectDefinition () then
			if self.Object:IsNamespace () then
				object = "[Namespace] " .. self.Object:GetFullName ()
			elseif self.Object:IsOverloadedClass () then
				object = "[Type Group] " .. (self.Object:GetClassCount () == 1 and self.Object:GetClass (1):GetFullName () or self.Object:GetFullName ())
			elseif self.Object:IsClass () then
				object = "[Class] " .. self.Object:GetFullName ()
			elseif self.Object:IsOverloadedMethod () then
				object = "[Method Group] " .. (self.Object:GetMethodCount () == 1 and self.Object:GetMethod (1):GetFullName () or self.Object:GetFullName ())
			elseif self.Object:IsMethod () then
				object = "[Method] " .. self.Object:GetFullName ()
			else
				object = self.Object:ToString ()
			end
		elseif self.Object:IsType () then
			object = "[Type]" .. self.Object:ToString ()
		else
			object = self.Object:ToString ()
		end
	else
		object = "[Nothing]"
	end
	if self.ResultType == GCompute.ResolutionResultType.Local then
		return "[" .. GCompute.ResolutionResultType [self.ResultType] .. ":" .. tostring (self.LocalDistance) .. "] " .. object
	end
	return "[" .. GCompute.ResolutionResultType [self.ResultType] .. "] " .. object
end
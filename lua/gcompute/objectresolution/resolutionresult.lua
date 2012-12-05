local self = {}
GCompute.ResolutionResult = GCompute.MakeConstructor (self)

function self:ctor (resolvedObject, resultType)
	self.ResolvedObject = resolvedObject
	self.ResultType     = resultType or GCompute.ResolutionResultType.Other
	self.LocalDistance  = math.huge
end

function self:GetLocalDistance ()
	return self.LocalDistance
end

function self:GetResolvedObject ()
	return self.ResolvedObject
end

function self:GetResultType ()
	return self.ResultType
end

function self:SetLocalDistance (localDistance)
	self.LocalDistance = localDistance
	return self
end

function self:SetResolvedObject (resolvedObject)
	self.ResolvedObject = resolvedObject
	return self
end

function self:SetResultType (resultType)
	self.ResultType = resultType
	return self
end

function self:ToString ()
	local resolvedObject = self.ResolvedObject and self.ResolvedObject:ToString () or "[Nothing]"
	if self.ResultType == GCompute.ResolutionResultType.Local then
		return "[" .. GCompute.ResolutionResultType [self.ResultType] .. ":" .. tostring (self.LocalDistance) .. "] " .. resolvedObject
	end
	return "[" .. GCompute.ResolutionResultType [self.ResultType] .. "] " .. resolvedObject
end
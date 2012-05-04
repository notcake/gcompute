local self = {}
self.__Type = "Expression"
GCompute.AST.Expression = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.CachedValue = nil
	self.IsCached = false
	self.IsConstant = false
	
	self.ResultType = nil
end

function self:Evaluate (executionContext)
	return nil
end

function self:GetResultType ()
	return self.ResultType
end

function self:IsConstant ()
	return self.IsConstant
end

function self:SetResultType (type)
	self.ResultType = type
end

function self:ToString ()
	return "[expression]"
end
local self = {}
self.__Type = "Expression"
GCompute.AST.Expression = GCompute.AST.MakeConstructor (self)

function self:ctor ()	
	-- type inference
	self.TargetTypes = {}
	self.PossibleTypes = {}
	
	self.ResultType = nil
	self.Value = nil
end

function self:AddTargetType (type)
	self.TargetTypes [#self.TargetTypes + 1] = type
end

function self:Evaluate (executionContext)
	return nil
end

function self:GetResultType ()
	return self.ResultType
end

function self:GetValue ()
	return self.Value
end

function self:SetResultType (type)
	self.ResultType = type
end

function self:SetValue (value)
	self.Value = value
end

function self:ToString ()
	return "[Unknown Expression]"
end
local self = {}
GCompute.FunctionCallPlan = GCompute.MakeConstructor (self)

function self:ctor ()
	self.FunctionName = nil
	self.FunctionDefinition = nil
	self.Function = nil
	
	self.MemberFunctionCall = false
	self.VirtualFunctionCall = false
	
	self.ArgumentCount = 0
	self.ArgumentCountIndeterminate = false
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:GetFunction ()
	return self.Function
end

function self:GetFunctionDefinition ()
	return self.FunctionDefinition
end

function self:IsArgumentCountIndeterminate ()
	return self.ArgumentCountIndeterminate
end

function self:SetArgumentCount (argumentCount)
	self.ArgumentCount = argumentCount
end

function self:SetFunctionDefinition (functionDefinition)
	self.FunctionDefinition = functionDefinition
end

function self:SetFunctionName (functionName)
	self.FunctionName = functionName
end
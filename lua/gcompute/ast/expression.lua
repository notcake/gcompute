local self = {}
self.__Type = "Expression"
GCompute.AST.Expression = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Type           = nil
	self.Value          = nil
	
	self.ResolutionResults = nil
	self.ResolutionResult  = nil
end

function self:Evaluate (executionContext)
	return nil
end

function self:GetResolutionResults ()
	return self.ResolutionResults
end

function self:GetResolutionResult ()
	if not self:GetResolutionResults () then return nil end
	return self:GetResolutionResults ():GetFilteredResultObject (1)
end

function self:GetType ()
	return self.Type
end

function self:GetValue ()
	return self.Value
end

function self:SetType (type)
	self.Type = type
end

function self:SetValue (value)
	self.Value = value
end

function self:ToString ()
	return "[Unknown Expression]"
end

function self:ToTypeNode (typeSystem)
	GCompute.Error (self:GetNodeType () .. ":ToTypeNode : Not implemented.")
end
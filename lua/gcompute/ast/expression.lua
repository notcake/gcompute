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

--- Gets the type of this expression as a Type
-- @return The type of this expression, as a Type
function self:GetType ()
	return self.Type
end

function self:GetValue ()
	return self.Value
end

--- Sets the type of this expression
-- @param type The Type of this expression, or an ObjectDefinition which corresponds to a Type
function self:SetType (type)
	type = type and type:ToType ()
	self.Type = type
end

function self:SetValue (value)
	self.Value = value
end

function self:ToString ()
	return "[Unknown Expression]"
end

function self:ToTypeNode ()
	GCompute.Error (self:GetNodeType () .. ":ToTypeNode : Not implemented.")
end
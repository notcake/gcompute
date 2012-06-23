local self = {}
self.__Type = "NameIndex"
GCompute.AST.NameIndex = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	self.Identifier = nil
	
	-- TODO: Remove this below
	self.IndexType = GCompute.AST.NameIndexType.Namespace
	self.LookupType = GCompute.AST.NameLookupType.Reference
	self.NameResolutionResults = GCompute.NameResolutionResults ()
	self.ResultsPopulated = false
end

function self:Evaluate (executionContext)
	local left, leftReference = self.LeftExpression:Evaluate (executionContext)
	if self.NameLookupType == GCompute.AST.NameLookupType.Value then
		return left:GetMember (self.Right.Name)
	else
		return left:GetMemberReference (self.Right.Name)
	end
end

function self:GetIndexType ()
	return self.IndexType
end

function self:GetIdentifier ()
	return self.Identifier
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetLookupType ()
	return self.LookupType
end

function self:SetIndexType (indexType)
	self.IndexType = indexType
end

function self:SetIdentifier (identifier)
	self.Identifier = identifier
	if self.Identifier then self.Identifier:SetParent (self) end
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Unknown Expression]"
	local identifier = self.Identifier and self.Identifier:ToString () or "[Unknown Identifier]"
	return leftExpression .. "." .. identifier
end
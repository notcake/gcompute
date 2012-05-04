local self = {}
self.__Type = "NameIndex"
GCompute.AST.NameIndex = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.Left = nil
	self.Right = nil
	
	self.IndexType = GCompute.AST.NameIndexType.Namespace
	self.LookupType = GCompute.AST.NameLookupType.Reference
	self.NameResolutionResults = GCompute.NameResolutionResults ()
	self.ResultsPopulated = false
end

function self:Evaluate (executionContext)
	local left, leftReference = self.Left:Evaluate (executionContext)
	if self.NameLookupType == GCompute.AST.NameLookupType.Value then
		return left:GetMember (self.Right.Name)
	else
		return left:GetMemberReference (self.Right.Name)
	end
end

function self:GetIndexType ()
	return self.IndexType
end

function self:GetLookupType ()
	return self.LookupType
end

function self:SetIndexType (indexType)
	self.IndexType = indexType
end

function self:ToString ()
	local left = self.Left:ToString ()
	local right = self.Right and self.Right:ToString () or "[nil]"
	return left .. "." .. right
end
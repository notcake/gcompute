local self = {}
self.__Type = "StaticMemberAccess"
GCompute.AST.StaticMemberAccess = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (leftExpression, name, typeArgumentList)
	self.LeftExpression = nil
	self.Name = name
	self.TypeArgumentList = nil
	
	self.RuntimeName = nil
	
	self:SetLeftExpression (leftExpression)
	self:SetTypeArgumentList (typeArgumentList)
	
	self.ResolutionResults = GCompute.ResolutionResults ()
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Lookup member
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
		
		if self:GetLeftExpression () then
			-- Expression, state 0
			astRunner:PushNode (self:GetLeftExpression ())
			astRunner:PushState (0)
		else
			astRunner:PushValue (executionContext:GetRuntimeNamespace ())
		end
	elseif state == 1 then
		-- Discard StaticMemberAccess
		astRunner:PopNode ()
		
		astRunner:PushValue (astRunner:PopValue () [self.RuntimeName])
	end
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetName ()
	return self.Name
end

function self:GetResolutionResults ()
	return self.ResolutionResults
end

function self:GetRuntimeName ()
	return self.RuntimeName
end

function self:GetTypeArgumentList ()
	return self.TypeArgumentList
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetName (name)
	self.Name = name
end

function self:SetResolutionResults (resolutionResults)
	self.ResolutionResults = resolutionResults
end

function self:SetRuntimeName (runtimeName)
	self.RuntimeName = runtimeName
end

function self:SetTypeArgumentList (typeArgumentList)
	self.TypeArgumentList = typeArgumentList
	if self.TypeArgumentList then self.TypeArgumentList:SetParent (self) end
end

function self:ToString ()
	if self.TypeArgumentList then
		return (self.LeftExpression and (self.LeftExpression:ToString () .. ".") or "") .. (self.Name or "[Nothing]") .. " " .. self.TypeArgumentList:ToString ()
	end
	return (self.LeftExpression and (self.LeftExpression:ToString () .. ".") or "")  .. (self.Name or "[Nothing]")
end
local self = {}
self.__Type = "StaticMemberAccess"
GCompute.AST.StaticMemberAccess = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (leftExpression, name, typeArgumentList)
	self.LeftExpression = nil
	self.Name = name
	self.TypeArgumentList = nil
	
	self.MemberDefinition = nil
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

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.LeftExpression
		elseif i == 2 then
			return self.TypeArgumentList
		end
		return nil
	end
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetMemberDefinition ()
	return self.MemberDefinition
end

function self:GetName ()
	return self.Name
end

function self:GetRuntimeName ()
	return self.RuntimeName
end

function self:GetTypeArgumentList ()
	return self.TypeArgumentList
end

function self:ResolveMemberDefinition (globalNamespace)
	if self.MemberDefinition then return self.MemberDefinition end
	
	local leftNamespace = globalNamespace
	if self.LeftExpression then
		leftNamespace = self.LeftExpression:ResolveMemberDefinition (globalNamespace)
	end
	
	if not leftNamespace then
		GCompute.Error ("StaticMemberAccess:ResolveMemberDefinition : Left namespace is of " .. self:ToString () .. " is nil.")
		return nil
	end
	self.MemberDefinition = leftNamespace:GetMember (self:GetName ())
	
	if self.TypeArgumentList and not self.TypeArgumentList:IsEmpty () then
		GCompute.Error ("StaticMemberAccess:ResolveMemberDefinition : This StaticMemberAccess has a TypeArgumentList.")
	end
	
	return self.MemberDefinition
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetMemberDefinition (memberDefinition)
	self.MemberDefinition = memberDefinition
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

function self:ToTypeNode (typeSystem)
	return self
end

function self:Visit (astVisitor, ...)
	if self:GetLeftExpression () then
		self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	end

	return astVisitor:VisitExpression (self, ...)
end
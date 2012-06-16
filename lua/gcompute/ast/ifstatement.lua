local self = {}
self.__Type = "IfStatement"
GCompute.AST.IfStatement = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.ConditionCount = 0
	self.Conditions = {}
	self.Statements = {}
	self.Else = nil
end

function self:AddCondition (condition, statement)
	self.ConditionCount = self.ConditionCount + 1
	self.Conditions [self.ConditionCount] = condition
	self.Statements [self.ConditionCount] = statement
end

function self:Evaluate (executionContext)
	local conditionMatched = false
	for i = 1, #self.Conditions do
		if self.Conditions [i]:Evaluate (executionContext) then
			conditionMatched = true
			self.Statements [i]:Evaluate (executionContext)
			break
		end
	end
	if not conditionMatched and self.Else then
		self.Else:Evaluate (executionContext)
	end
end

function self:GetCondition (index)
	return self.Conditions [index]
end

function self:GetConditionCount ()
	return self.ConditionCount
end

function self:GetElseStatement ()
	return self.Else
end

function self:GetStatement (index)
	return self.Statements [index]
end

function self:SetCondition (index, expression)
	self.Conditions [index] = expression
end

function self:SetElseStatement (statement)
	self.Else = statement
end

function self:SetStatement (index, statement)
	self.Statements [index] = statement
end

function self:ToString ()
	local ifStatement = ""
	for i = 1, self.ConditionCount do
		local condition = self.Conditions [i] and self.Conditions [i]:ToString () or "[Unknown Expression]"
		local statement = " [Unknown Statement]"
		if self.Statements [i] then
			statement = self.Statements [i]:ToString ()
			if self.Statements [i]:Is ("Block") then
				statement = "    " .. statement:gsub ("\n", "\n    ")
			else
				statement = "    " .. statement
			end
			statement = "\n" .. statement
		end
		
		if ifStatement == "" then
			ifStatement = ifStatement .. "if ("
		else
			ifStatement = ifStatement .. "elseif ("
		end
		ifStatement = ifStatement .. condition .. ")" .. statement
	end
	
	if self.Statement then
		Statement = self.Statement:ToString ()
		if not self.Statement:Is ("Block") then
			Statement = "    " .. Statement:gsub ("\n", "\n    ")
		end
		Statement = "\n" .. Statement
	end
	
	if self.Else then
		local elseStatement = self.Else:ToString ()
		if not self.Else:Is ("Block") then
			elseStatement = "    " .. elseStatement:gsub ("\n", "\n    ")
		else
			elseStatement = "    " .. elseStatement
		end
		elseStatement = "\n" .. elseStatement
		return "if (" .. Condition .. ")" .. Statement .. "\nelse " .. elseStatement
	else
		return "if (" .. Condition .. ")" .. Statement
	end
end
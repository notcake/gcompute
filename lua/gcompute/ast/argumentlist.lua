local self = {}
self.__Type = "ArgumentList"
GCompute.AST.ArgumentList = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.ArgumentCount = 0
	self.Arguments = {}
end

function self:AddArgument (expression)
	self.ArgumentCount = self.ArgumentCount + 1
	self:SetArgument (self.ArgumentCount, expression)
end

function self:AddArguments (arguments)
	for _, argument in ipairs (arguments) do
		self:AddArgument (argument)
	end
end

function self:AppendArgumentList (argumentList)
	for argument in argumentList:GetEnumerator () do
		self:AddArgument (argument)
	end
end

function self:Clone ()
	local argumentList = GCompute.AST.ArgumentList ()
	argumentList:SetStartToken (self:GetStartToken ())
	argumentList:SetEndToken (self:GetEndToken ())
	
	argumentList.ArgumentCount = self.ArgumentCount
	argumentList.Arguments = {}
	for i = 1, self.ArgumentCount do
		argumentList.Arguments [i] = self.Arguments [i]
	end
	return argumentList
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	for i = 1, self:GetArgumentCount () do
		if self:GetArgument (i) then
			self:GetArgument (i):ComputeMemoryUsage (memoryUsageReport, "Syntax Trees")
		end
	end
	
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0+: Evaluate arguments
	if state + 1 <= self:GetArgumentCount () then
		astRunner:PushState (state + 1)
		
		-- Expresssion, state 0
		astRunner:PushNode (self:GetArgument (state + 1))
		astRunner:PushState (0)
	else
		-- Discard ArgumentList
		astRunner:PopNode ()
	end
end

function self:GetArgument (argumentId)
	return self.Arguments [argumentId]
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:GetArgumentTypes ()
	local argumentTypes = {}
	for i = 1, self.ArgumentCount do
		argumentTypes [#argumentTypes + 1] = self.Arguments [i]:GetType ()
	end
	return argumentTypes
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		while not self.Arguments [i] do
			if i >= self.ArgumentCount then break end
			i = i + 1
		end
		return self.Arguments [i]
	end
end

--- Returns an iterator function for this argument list
-- @return An iterator function for this argument list
function self:GetEnumerator ()
	return GLib.ArrayEnumerator (self.Arguments)
end

function self:InsertArgument (argumentId, argument)
	if argumentId < 1 then argumentId = 1 end
	if argumentId > self.ArgumentCount then argumentId = self.ArgumentCount + 1 end
	
	self.ArgumentCount = self.ArgumentCount + 1
	table.insert (self.Arguments, argumentId, argument)
end

function self:IsEmpty ()
	return self.ArgumentCount == 0
end

function self:RemoveArgument (argumentId)
	if argumentId > self.ArgumentCount then return end
	self.ArgumentCount = self.ArgumentCount - 1
	table.remove (self.Arguments, argumentId)
end

function self:SetArgument (argumentId, expression)
	self.Arguments [argumentId] = expression
	if expression then expression:SetParent (self) end
end

function self:ToString ()
	local argumentList = ""
	for i = 1, self.ArgumentCount do
		if argumentList ~= "" then
			argumentList = argumentList .. ", "
		end
		argumentList = argumentList .. (self.Arguments [i] and self.Arguments [i]:ToString () or "[Nothing]")
	end
	return "(" .. argumentList .. ")"
end

function self:ToTypeNode ()
	local parameterList = GCompute.AST.ParameterList ()
	parameterList:SetStartToken (self:GetStartToken ())
	parameterList:SetEndToken (self:GetEndToken ())
	
	for i = 1, self.ArgumentCount do
		parameterList:AddParameter (self.Arguments [i]:ToTypeNode ())
	end
	return parameterList
end

function self:ToTypeString ()
	local argumentList = ""
	for i = 1, self.ArgumentCount do
		if argumentList ~= "" then
			argumentList = argumentList .. ", "
		end
		argumentList = argumentList .. (self.Arguments [i] and self.Arguments [i]:GetType () and self.Arguments [i]:GetType ():GetFullName () or "[Nothing]")
	end
	return "(" .. argumentList .. ")"
end

function self:Visit (astVisitor, ...)
	for i = 1, self:GetArgumentCount () do
		local argument = self:GetArgument (i)
		if argument then
			self:SetArgument (i, argument:Visit (astVisitor, ...) or argument)
		end
	end
	
	local astOverride = astVisitor:VisitArgumentList (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
end

GCompute.AST.EmptyArgumentList = GCompute.AST.ArgumentList ()
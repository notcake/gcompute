local self = {}
self.__Type = "FunctionCall"
GCompute.AST.FunctionCall = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.FunctionExpression = nil		-- Expression
	self.CachedFunction = nil
	
	self.MemberFunctionCall = false
	
	self.Arguments = {}
	self.ArgumentCount = 0
end

function self:AddArgument (argument)
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] = argument or GCompute.AST.UnknownExpression ()
end

function self:AddArguments (arguments)
	for _, argument in ipairs (arguments) do
		self:AddArgument (argument)
	end
end

function self:Evaluate (executionContext)
	local functionObject = nil
	if self.CachedFunction then
		functionObject = self.CachedFunction
	else
		functionObject = self.FunctionExpression:Evaluate (executionContext)
	end

	if functionObject then
		local arguments = {}
		for i = 1, self.ArgumentCount do
			arguments [i] = self.Arguments [i]:Evaluate (executionContext)
		end
		if self:IsMemberFunctionCall () then
			local this = self.FunctionExpression.Left:Evaluate (executionContext)
			return functionObject:Call (executionContext, self.ArgumentTypes, this, unpack (arguments))
		else
			return functionObject:Call (executionContext, self.ArgumentTypes, unpack (arguments))
		end
	else
		executionContext:Error ("Unresolved function " .. self.FunctionExpression:ToString () .. " in " .. self:ToString () .. ".")
	end
end

function self:GetArgument (index)
	return self.Arguments [index]
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:GetFunctionExpression ()
	return self.FunctionExpression
end

function self:IsMemberFunctionCall ()
	return self.MemberFunctionCall
end

function self:SetFunctionExpression (functionExpression)
	self.FunctionExpression = functionExpression
end

function self:SetMemberFunctionCall (memberFunctionCall)
	self.MemberFunctionCall = memberFunctionCall
end

function self:ToString ()
	local arguments = ""
	for i = 1, self.ArgumentCount do
		if arguments ~= "" then
			arguments = arguments .. ", "
		end
		arguments = arguments .. self.Arguments [i]:ToString ()
	end
	return self.FunctionExpression:ToString () .. " (" .. arguments .. ")"
end
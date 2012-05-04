local self = {}
self.__Type = "FunctionCall"
GCompute.AST.FunctionCall = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.Function = nil		-- Expression
	self.CachedFunction = nil
	
	self.MemberFunctionCall = false
	
	self.Arguments = {}
	self.ArgumentCount = 0
end

function self:AddArgument (argument)
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] = argument or GCompute.AST.UnknownExpression ()
end

function self:Evaluate (executionContext)
	local functionObject = nil
	if self.CachedFunction then
		functionObject = self.CachedFunction
	else
		functionObject = self.Function:Evaluate (executionContext)
	end

	if functionObject then
		local arguments = {}
		for i = 1, self.ArgumentCount do
			arguments [i] = self.Arguments [i]:Evaluate (executionContext)
		end
		if self:IsMemberFunctionCall () then
			local this = self.Function.Left:Evaluate (executionContext)
			return functionObject:Call (executionContext, self.ArgumentTypes, this, unpack (arguments))
		else
			return functionObject:Call (executionContext, self.ArgumentTypes, unpack (arguments))
		end
	else
		executionContext:Error ("Unresolved function " .. self.Function:ToString () .. " in " .. self:ToString () .. ".")
	end
end

function self:GetArgument (index)
	return self.Arguments [index]
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:IsMemberFunctionCall ()
	return self.MemberFunctionCall
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
	return self.Function:ToString () .. " (" .. arguments .. ")"
end
local self = {}
GCompute.Function = GCompute.MakeConstructor (self)

function self:ctor (name, returnType)
	self.Name = Name or "[anonymous function]"
	self.ParentScope = nil
	self.ReturnType = GCompute.TypeReference (returnType or "void")
	
	self.MemberFunction = false
	
	self.ArgumentCount = 0
	self.Arguments = {}
	self.Native = nil
	self.NativeString = nil
	
	self.Block = nil
	self.Scope = GCompute.Scope ()
end

function self:AddArgument (argumentType, name)
	if not argumentType then GCompute.PrintStackTrace () end

	local Argument = {}
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] = Argument
	Argument.Type = GCompute.TypeReference (argumentType)
	Argument.Type:SetResolutionScope (self.ParentScope)
	Argument.Name = name
end

function self:Apply (executionContext, ...)
	local outer = {...}
	return function (executionContext, ...)
		return self:Call (executionContext, unpack (outer), ...)
	end
end

function self:Call (executionContext, argumentTypes, ...)
	if self.Native then
		return self.Native (executionContext, ...)
	end
	
	local scopeInstance = executionContext:PushScope (self.Scope)
	-- bind variables
	local Arguments = {...}
	for i = 1, self.ArgumentCount do
		scopeInstance:SetMember (self.Arguments [i].Name, Arguments [i])
	end
	
	self.Block:GetOptimizedBlock ():Evaluate (executionContext)
	executionContext:PopScope ()
	return executionContext:ClearReturn ()
end

function self:GetArgumentCount ()
	return #self.Arguments
end

function self:GetParentScope ()
	return self.ParentScope
end

function self:GetScope ()
	return self.Scope
end

function self:IsMemberFunction ()
	return self.MemberFunction
end

function self:SetArgumentType (index, argumentType)
	self.Arguments [index].Type = GCompute.TypeReference (argumentType)
	self.Arguments [index].Type:SetResolutionScope (self.ParentScope)
end

function self:SetBlock (block)
	self.Block = block
end

function self:SetMemberFunction (memberFunction)
	self.MemberFunction = memberFunction
end

function self:SetNative (NativeFunction)
	self.Native = NativeFunction
end

function self:SetParentScope (parentScope)
	if self.ParentScope and self.ParentScope ~= parentScope then GCompute.Error ("Parent scope already set!") end

	self.ParentScope = parentScope
	self.ReturnType:SetResolutionScope (parentScope)
	for i = 1, self.ArgumentCount do
		self.Arguments [i].Type:SetResolutionScope (parentScope)
	end
end

function self:SetReturnType (returnType)
	self.ReturnType = GCompute.TypeReference (returnType)
end

function self:SetScope (scope)
	self.Scope = scope
end

function self:ToString ()
	local arguments = ""
	if self:IsMemberFunction () then
		arguments = arguments .. "this"
	end
	for i = 1, self.ArgumentCount do
		if arguments ~= "" then
			arguments = arguments .. ", "
		end
		arguments = arguments .. self.Arguments [i].Type:ToString () .. " " .. self.Arguments [i].Name
	end
	
	return self.ReturnType:ToString () .. " (" .. arguments .. ")"
end
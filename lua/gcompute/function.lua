local Function = {}
Function.__index = Function

function GCompute.Function (...)
	local Object = {}
	setmetatable (Object, Function)
	Object:ctor (...)
	return Object
end

function Function:ctor (Name, ReturnType)
	self.Name = Name
	self.ReturnType = ReturnType
	
	self.ArgumentCount = 0
	self.Arguments = {}
	self.Native = nil
	self.NativeString = nil
	self.Static = false
end

function Function:AddArgument (ArgumentType, Name)
	local Argument = {}
	self.Arguments [#self.Arguments + 1] = Argument
	self.ArgumentCount = self.ArgumentCount + 1
	Argument.Type = ArgumentType
	Argument.Name = Name
end

function Function:Apply (ExecutionContext, ...)
	local Outer = {...}
	return function (ExecutionContext, ...)
		return self:Call (ExecutionContext, unpack (Outer), ...)
	end
end

function Function:Call (ExecutionContext, ...)
	if self.Native then
		return self.Native (ExecutionContext, ...)
	end
end

function Function:SetNative (NativeFunction)
	self.Native = NativeFunction
end
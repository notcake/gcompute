local FunctionList = {}
FunctionList.__index = FunctionList

function GCompute.FunctionList (...)
	local Object = {}
	setmetatable (Object, FunctionList)
	Object:ctor (...)
	return Object
end

function FunctionList:ctor (Name)
	self.Name = Name
	self.Functions = {}
end

function FunctionList:AddFunction (ReturnType, ...)
	local Function = GCompute.Function (self.Name, ReturnType)
	self.Functions [#self.Functions + 1] = Function
	Function.Static = true
	Function:AddArgument (...)
	return Function
end

function FunctionList:AddMemberFunction (ReturnType, ...)
	local Function = GCompute.Function (self.Name, ReturnType)
	self.Functions [#self.Functions + 1] = Function
	Function:AddArgument (...)
	return Function
end
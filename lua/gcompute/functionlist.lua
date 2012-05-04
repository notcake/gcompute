local self = {}
GCompute.FunctionList = GCompute.MakeConstructor (self)

function self:ctor (name)
	self.Name = name
	self.ParentScope = nil
	
	self.Functions = {}
end

function self:AddFunction (returnType)
	local functionObject = GCompute.Function (self.Name, returnType)
	self.Functions [#self.Functions + 1] = functionObject
	functionObject:SetParentScope (self.ParentScope)
	return functionObject
end

function self:AddMemberFunction (returnType)
	local functionObject = GCompute.Function (self.Name, returnType)
	self.Functions [#self.Functions + 1] = functionObject
	functionObject:SetParentScope (self.ParentScope)
	functionObject:SetMemberFunction (true)
	return functionObject
end

function self:Call (executionContext, argumentTypes, ...)
	return self.Functions [1]:Call (executionContext, argumentTypes, ...)
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Functions [i]
	end
end

function self:GetFunction (index)
	return self.Functions [index]
end

function self:GetFunctionCount ()
	return #self.Functions
end

function self:GetParentScope ()
	return self.ParentScope
end

function self:SetParentScope (parentScope)
	if self.ParentScope and self.ParentScope ~= parentScope then GCompute.Error ("Parent scope already set!") end

	self.ParentScope = parentScope
	for functionObject in self:GetEnumerator () do
		functionObject:SetParentScope (parentScope)
	end
end

function self:ToString ()
	if #self.Functions == 1 then
		return self.Functions [1]:ToString ()
	end
	return "[FunctionList]"
end
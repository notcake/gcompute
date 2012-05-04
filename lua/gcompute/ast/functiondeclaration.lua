local self = {}
self.__Type = "FunctionDeclaration"
GCompute.AST.FunctionDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Name = "[unknown]"
	self.Function = nil
	
	self.ReturnType = nil		-- TypeReference
	self.ArgumentTypes = {}
	self.ArgumentNames = {}
	self.ArgumentCount = 0
	self.Block = GCompute.AST.Block ()
	self.Block.BlockType = GCompute.AST.BlockType.Function
end

function self:AddArgument (argumentType, argumentName)
	self.ArgumentCount = self.ArgumentCount + 1
	self.ArgumentTypes [self.ArgumentCount] = argumentType or GCompute.AST.UnknownExpression ()
	self.ArgumentNames [self.ArgumentCount] = argumentName or "[unknown]"
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:GetArgumentName (index)
	return self.ArgumentNames [index]
end

function self:GetArgumentType (index)
	return self.ArgumentTypes [index]
end

function self:GetBlock ()
	return self.Block
end

function self:GetFunction ()
	return self.Function
end

function self:GetName ()
	return self.Name
end

function self:GetReturnType ()
	return self.ReturnType
end

function self:SetFunction (func)
	self.Function = func
end

function self:ToString ()
	local Type = self.ReturnType and self.ReturnType:ToString () or "[unknown]"
	
	local Arguments = ""
	for i = 1, self.ArgumentCount do
		if Arguments ~= "" then
			Arguments = Arguments .. ", "
		end
		Arguments = Arguments .. self.ArgumentTypes [i]:ToString () .. " " .. self.ArgumentNames [i]
	end
	return Type .. " " .. self.Name .. " (" .. Arguments .. ")\n" .. self.Block:ToString ()
end
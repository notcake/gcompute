local self = ASTBuilder

function self:BuildAST (parseTree)
	return self:Block (parseTree, GCompute.AST.BlockType.Global)
end

function self:Block (parseTree, blockType)
	local block = GCompute.AST.Block ()
	block.BlockType = blockType or GCompute.AST.BlockType.Block
	for node in parseTree:GetEnumerator () do
		block:AddNode (self:Statement (node))
	end
	return block
end

function self:Statement (parseTree)
	if parseTree.Value == "break" then
		return GCompute.AST.Break ()
	elseif parseTree.Value == "continue" then
		return GCompute.AST.Continue ()
	elseif parseTree.Value == "expr" then
		return self:Expression (parseTree)
	elseif parseTree.Value == "decl" then
		return self:VariableDeclaration (parseTree)
	elseif parseTree.Value == "fdecl" then
		return self:FunctionDeclaration (parseTree)
	elseif parseTree.Value == "for" then
		return self:ForLoop (parseTree)
	elseif parseTree.Value == "if" then
		return self:IfStatement (parseTree)
	elseif parseTree.Value == "return" then
		return self:Return (parseTree)
	elseif parseTree.Value == "scope" then
		return self:Block (parseTree, GCompute.AST.BlockType.Block)
	end
end

function self:FunctionDeclaration (parseTree)
	local FunctionDeclaration = GCompute.AST.FunctionDeclaration ()
	
	FunctionDeclaration.ReturnType = self:Type (parseTree:FindChild ("rtype"):GetFirstChild ())
	FunctionDeclaration.Name = parseTree:GetChild (2).Value
	FunctionDeclaration.Block = self:Block (parseTree:FindChild ("scope"), GCompute.AST.BlockType.Function)
	
	local Arguments = parseTree:FindChild ("args")
	for Argument in Arguments:GetEnumerator () do
		FunctionDeclaration:AddArgument (self:Type (Argument:GetFirstChild ()), Argument:GetChild (1).Value)
	end
	
	return FunctionDeclaration
end

function self:VariableDeclaration (parseTree)
	local VariableDeclaration = GCompute.AST.VariableDeclaration ()

	VariableDeclaration.Type = self:Type (parseTree:FindChild ("type"):GetFirstChild ())
	VariableDeclaration.Name = parseTree:FindChild ("var"):GetChild (0).Value
	VariableDeclaration.Value = nil
	if parseTree:FindChild ("var"):GetChild (1) then
		VariableDeclaration.Value = self:Expression (parseTree:FindChild ("var"):GetChild (1))
	end
	
	return VariableDeclaration
end

-- Expressions
function self:Expression (parseTree)
	if parseTree.Value == "expr" then
		parseTree = parseTree:GetFirstChild ()
	end
	
	if parseTree.Value == "call" then
		return self:FunctionCall (parseTree)
	elseif parseTree.Value == "name" then
		return GCompute.AST.Identifier (parseTree:GetFirstChild ().Value)
	elseif parseTree.Value == "." then
		return self:NameIndex (parseTree)
	elseif parseTree.Value == "num" then
		return GCompute.AST.NumberLiteral (parseTree:GetFirstChild ().Value)
	elseif parseTree.Value == "str" then
		return GCompute.AST.StringLiteral (parseTree:GetFirstChild ().Value)
	end
	
	-- operators
	
	if parseTree.ChildCount == 2 then
		if parseTree.Value ~= "==" and parseTree.Value ~= ">=" and parseTree.Value ~= "<=" and parseTree.Value:find ("=") then
			local BinaryAssignmentOperator = GCompute.AST.BinaryAssignmentOperator ()
			BinaryAssignmentOperator:SetOperator (parseTree.Value)
			BinaryAssignmentOperator.Left = self:Expression (parseTree:GetFirstChild ())
			BinaryAssignmentOperator.Right = self:Expression (parseTree:GetChild (1))
			return BinaryAssignmentOperator
		end
		local BinaryOperator = GCompute.AST.BinaryOperator ()
		BinaryOperator:SetOperator (parseTree.Value)
		BinaryOperator.Left = self:Expression (parseTree:GetFirstChild ())
		BinaryOperator.Right = self:Expression (parseTree:GetChild (1))
		return BinaryOperator
	end
	
	if parseTree.Value == "++" or parseTree.Value == "--" then
		local UnaryOperator = GCompute.AST.UnaryOperator ()
		UnaryOperator:SetOperator (parseTree.Value)
		UnaryOperator.Left = self:Expression (parseTree:GetFirstChild ())
		return UnaryOperator
	end
	
	ErrorNoHalt ("Unknown expression node: " .. parseTree:ToString () .. "\n")
	return GCompute.AST.UnknownExpression ()
end

function self:FunctionCall (parseTree)
	local functionExpression = self:Expression (parseTree:GetFirstChild ())
	local functionCall = GCompute.AST.FunctionCall ()
	functionCall.Function = functionExpression
	
	local arguments = parseTree:FindChild ("args")
	if arguments then
		for argumentNode in arguments:GetEnumerator () do
			functionCall:AddArgument (self:Expression (argumentNode))
		end
	end
	
	return functionCall
end

function self:NameIndex (parseTree)
	if parseTree.Value == "name" then
		return GCompute.AST.Identifier (parseTree:GetFirstChild ().Value)
	elseif parseTree.Value == "." then
		local nameIndex = GCompute.AST.NameIndex ()
		nameIndex.Left = self:NameIndex (parseTree:GetFirstChild ())
		if parseTree:GetChild (1).Value == "name" then
			nameIndex.Right = GCompute.AST.Identifier (parseTree:GetChild (1):GetFirstChild ().Value)
		elseif parseTree:GetChild (1).Value == "parametric_type" then
			nameIndex.Right = self:NameParameters (parseTree:GetChild (1))
		else
			GCompute.Error ("Unknown right hand side of NameIndex (" .. parseTree:GetChild (1).Value .. ")!")
		end
		return nameIndex
	else
		GCompute.Error ("Unknown node " .. parseTree.Value .. " in parse tree.")
	end
	
	return nil
end

function self:NameParameters (parseTree)
	local parametricName = GCompute.AST.ParametricName ()
	parametricName.Name = GCompute.AST.Identifier (parseTree:FindChild ("name"):GetFirstChild ().Value)

	local arguments = parseTree:FindChild ("args")
	for argumentNode in arguments:GetEnumerator () do
		parametricName:AddArgument (self:Type (argumentNode))
	end
	
	return parametricName
end

-- Control
function self:ForLoop (parseTree)
	local ForLoop = GCompute.AST.ForLoop ()
	ForLoop.Initializer = self:Statement (parseTree:FindChild ("init"):GetFirstChild ())
	ForLoop.Condition = self:Expression (parseTree:FindChild ("cond"):GetFirstChild ())
	ForLoop.PostLoop = self:Expression (parseTree:FindChild ("post"):GetFirstChild ())
	ForLoop.Loop = self:Statement (parseTree:FindChild ("loop"):GetFirstChild ())
	
	return ForLoop
end

function self:IfStatement (parseTree)
	local IfStatement = GCompute.AST.IfStatement ()
	IfStatement.Condition = self:Expression (parseTree:FindChild ("cond"):GetFirstChild ())
	IfStatement.Statement = self:Statement (parseTree:GetChild (1))
	if parseTree:GetChild (2) then
		IfStatement.Else = self:Statement (parseTree:GetChild (2))
	end
	
	return IfStatement
end

function self:Return (parseTree)
	local Return = GCompute.AST.Return ()
	if parseTree.ChildCount > 0 then
		Return.ReturnValue = self:Expression (parseTree:GetFirstChild ())
	end
	
	return Return
end

-- takes a raw type tree (either a direct name, or "." node)
function self:Type (parseTree)
	local typeName = ""
	
	if parseTree.Value == "." then
		return self:NameIndex (parseTree)
	elseif parseTree.Value == "name" then
		return GCompute.AST.Identifier (parseTree:GetFirstChild ().Value)
	else
		GCompute.Error ("Unknown node " .. parseTree.Value .. " in parse tree.")
	end
	
	return nil
end
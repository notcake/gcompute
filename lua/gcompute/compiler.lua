if not GCompute.Compiler then
	GCompute.Compiler = {}
end
local Compiler = GCompute.Compiler
Compiler.__index = Compiler
Compiler.Statements = {}

function Compiler.CompileExpression (CompilerContext, Scope, Node)
	local Type = Node.Value
	if Type == "call" then
		Node.Function = Compiler.ResolveNamespaceItem (CompilerContext, Scope, Node:GetFirstChild ())
		Node.ArgumentCount = Node:FindChild ("args").ChildCount
		local Arguments = Node.Children.First.Next.Value
		PrintTable (Arguments)
	end
end

function Compiler.Process (CompilerContext)
	Compiler.ProcessScope (CompilerContext, CompilerContext.Scope, CompilerContext.ParseTree)
end

function Compiler.ResolveNamespaceItem (CompilerContext, Scope, Node)
	local Namespace = GCompute.GlobalScope
	local Item, Type = Namespace:GetItem (Node.Value)
	return Item
end

function Compiler.ValueFunction (CompilerContext, Value)
	return function (ExecutionContext)
		return Value
	end
end

-- Variable declaration
Compiler.Statements ["decl"] = function (self, Scope, Node)
	local Modifiers = Node:FindChild ("mod")
	local Type = Node:FindChild ("type")
	if Type then
		Type = Type:GetFirstChild ().Value
	end
	for Variable in Node:GetEnumerator () do
		if Variable.Value == "var" then
			local Current = Variable.Children.First
			local Name = Current.Value.Value
			Current = Current.Next
			if Current then
				Current = Current.Value
			end
			Scope:AddMemberVariable (Type, Name, Current)
		end
	end
end

-- Expression
Compiler.Statements ["expr"] = function (self, Scope, Node)
	Scope:AddCommand (Node)
	Compiler.CompileExpression (self, Scope, Node:GetFirstChild ():GetFirstChild ())
end

-- Function declaration
Compiler.Statements ["fdecl"] = function (self, Scope, Node)
	local Modifiers = ParseTreeNode:FindChild ("mod")
	local ReturnType = ParseTreeNode:FindChild ("rtype")
	if ReturnType then
		PrintTable (ReturnType)
		ReturnType = ReturnType:GetFirstChild ().Value
	end
	local Name = Node.Children.First.Next.Next.Value.Value
	Scope:AddMemberFunction (ReturnType, Name)
end

function Compiler.ProcessScope (CompilerContext, Scope, ParseTree)
	for Node in ParseTree:GetEnumerator () do
		local NodeType = Node.Value
		if Compiler.Statements [NodeType] then
			Compiler.Statements [NodeType] (CompilerContext, Scope, ParseTree)
		end
	end
end
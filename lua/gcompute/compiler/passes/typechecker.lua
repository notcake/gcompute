local self = {}
GCompute.TypeCheckerPass = GCompute.MakeConstructor (self, GCompute.CompilerPass)

--[[
	This pass:
		1. Tags all expressions with their result type as a TypeReference.
		2. Resolves all function calls
]]

function self:ctor ()
	self.ScopeLookup = GCompute.ScopeLookup ()
end

function self:Process (compilationUnit, rootBlock)
	self:ProcessBlock (compilationUnit, rootBlock)
end

function self:ProcessBlock (compilationUnit, block)
	self.ScopeLookup:PushScope (block.Scope)

	for statement in block:GetEnumerator () do
		if statement:Is ("Expression") then
			self:ProcessExpression (compilationUnit, block:GetScope (), statement)
		elseif statement:Is ("ForLoop") then
			self:ProcessBlock (compilationUnit, statement.Loop)
		elseif statement:Is ("IfStatement") then
			self:ProcessBlock (compilationUnit, statement.Statement)
			
			if statement.Else then
				self:ProcessBlock (compilationUnit, Statement.Else)
			end
		elseif statement:Is ("Control") then
		elseif statement:Is ("FunctionDeclaration") then
			self:ProcessBlock (compilationUnit, statement:GetBlock ())
		elseif statement:Is ("VariableDeclaration") then
			if statement.Value then
				self:ProcessExpression (compilationUnit, block:GetScope (), statement.Value)
			end
		else
			compilationUnit:Error ("TypeChecker: Unhandled AST node " .. statement.__Type .. " (" .. statement:ToString () .. ")", statement:GetSourceLine (), statement:GetSourceCharacter ())
		end
	end
	
	self.ScopeLookup:PopScope ()
end

function self:ProcessExpression (compilationUnit, scope, statement)
	if statement:Is ("FunctionCall") then
		for i = 1, statement:GetArgumentCount () do
			self:ProcessExpression (compilationUnit, scope, statement:GetArgument (i))
		end
		
		self:ProcessExpression (compilationUnit, scope, statement.Function)
		
		if statement.Function:Is ("NameIndex") or
			statement.Function:Is ("Identifier") then
			
			print (statement:ToString ())
			print (statement.Function:ToString () .. " evaluates to : " .. statement.Function.NameResolutionResults:ToString ())
			for i = 1, statement.Function.NameResolutionResults:GetResultCount () do
				local result = statement.Function.NameResolutionResults:GetResult (i)
				local functionList = result:GetValue ()
				for j = 1, functionList:GetFunctionCount () do
					local functionObject = functionList:GetFunction (j)
					statement.CachedFunction = functionObject
					if functionObject:IsMemberFunction () then
						statement:SetMemberFunctionCall (true)
					end
				end
			end
		end
		
		-- TODO: Identify function to call and get return type
	elseif statement:Is ("NumberLiteral") then
		if statement.Number == math.floor (statement.Number) then
			statement.ResultType = GCompute.TypeReference ("int")
		else
			statement.ResultType = GCompute.TypeReference ("float")
		end
		statement.ResultType:SetResolutionScope (scope)
		statement.ResultType:ResolveType ()
		
		compilationUnit:Debug ("Type of " .. statement:ToString () .. " is " .. statement.ResultType:ToString () .. ".")
	elseif statement:Is ("StringLiteral") then
		statement.ResultType = GCompute.TypeReference ("string")
		statement.ResultType:SetResolutionScope (scope)
		statement.ResultType:ResolveType ()
		
		compilationUnit:Debug ("Type of " .. statement:ToString () .. " is " .. statement.ResultType:ToString () .. ".")
	elseif statement:Is ("BinaryOperator") then
		self:ProcessExpression (compilationUnit, scope, statement.Left)
		self:ProcessExpression (compilationUnit, scope, statement.Right)
		
		-- TODO: Identify function to call and get return type
	elseif statement:Is ("Identifier") then
		local value, reference = self.ScopeLookup:GetReference ({ statement.Name })
		if reference then
			statement.ResultType = reference:GetType ()
			
			local result = GCompute.NameResolutionResult ()
			result:SetIndexType (GCompute.AST.NameIndexType.Namespace)
			result:SetResult (value, reference:GetType (), reference)
			statement.NameResolutionResults:AddResult (result)
			
			compilationUnit:Debug ("Type of " .. statement:ToString () .. " is " .. statement.ResultType:ToString () .. ".")
		else
			print ("TypeChecker: Failed Identifier (" .. statement:ToString () .. ")")
			print (self.ScopeLookup.TopScope:ToString ())
			compilationUnit:Error ("TypeChecker: Failed Identifier (" .. statement:ToString () .. ")", statement:GetSourceLine (), statement:GetSourceCharacter ())
		end
	elseif statement:Is ("NameIndex") then
		self:ProcessExpression (compilationUnit, scope, statement.Left)
		
		-- TODO: Rewrite to evaluate over all possibilities for left.
		
		local left = statement.Left
		local leftType = statement.Left.ResultType:UnreferenceType ()
		local leftTypeName = leftType:ToString ()
		if leftTypeName == "_G.Namespace" then
			statement:SetIndexType (GCompute.AST.NameIndexType.Namespace)
		elseif leftTypeName == "_G.Type" then
			statement:SetIndexType (GCompute.AST.NameIndexType.StaticClassMember)
		else
			statement:SetIndexType (GCompute.AST.NameIndexType.ObjectMember)
			if leftType:HasVTable () then
				-- virtual function call or index
			else
				-- non virtual function call or index
				local typeMembers = leftType:GetMembers ()
				local member, memberType = typeMembers:GetMember (statement.Right.Name)
				local _, memberReference = typeMembers:GetMemberReference (statement.Right.Name)
				
				local result = GCompute.NameResolutionResult ()
				result:SetIndexType (GCompute.AST.NameIndexType.ObjectMember)
				result:SetResult (member, memberType, memberReference)
				statement.NameResolutionResults:AddResult (result)
				
				statement.ResultType = memberType
			end
		end
		if statement.ResultType then
			compilationUnit:Debug ("Type of " .. statement:ToString () .. " is " .. statement.ResultType:ToString () .. ".")
		else
			compilationUnit:Debug ("Failed to determine type of " .. statement:ToString () .. ".")
		end
	else
		compilationUnit:Error ("TypeChecker: Unhandled AST node " .. statement.__Type .. " (" .. statement:ToString () .. ")", statement:GetSourceLine (), statement:GetSourceCharacter ())
	end
end
local self = {}
GCompute.NameResolver = GCompute.MakeConstructor (self)

--[[
	First identifier:
		All local scopes first
		Class, then base classes
		Global scope, all usings
		
	Second identifier:
		Namespace -> obvious
		Type -> obvious
		Type instance -> type members?
]]

function self:ctor ()
end

function self:Resolve (scope, astNode)
	if astNode.ResultsPopulated then return end
	
	if astNode:Is ("Identifier") then
		self:ResolveIdentifier (scope, astNode)
	elseif astNode:Is ("NameIndex") then
		self:ResolveNameIndex (scope, astNode)
	elseif astNode:Is ("ParametricName") then
		self:ResolveParametricName (scope, astNode)
	else
		GCompute.Error ("NameResolver: Cannot handle unknown AST node " .. astNode.__Type .. "!")
	end
end

function self:ResolveIdentifier (scope, astIdentifier)
	if astIdentifier.ResultsPopulated then return end
	astIdentifier.ResultsPopulated = true

	local name = astIdentifier.Name
	
	if not scope then
		GCompute.Error ("NameResolver:ResolveIdentifier: No scope given!")
	end
	
	-- Do local scopes
	local parentScope = scope
	while parentScope do
		local member, memberReference = parentScope:GetMemberReference (name)
		if memberReference then
			local result = GCompute.NameResolutionResult ()
			result:SetResult (member, memberReference:GetType (), memberReference)
			astIdentifier.NameResolutionResults:AddResult (result)
		end
		
		parentScope = parentScope:GetParentScope ()
	end
	
	if astIdentifier.NameResolutionResults:GetResultCount () == 0 then
		GCompute.Error ("NameResolver:ResolveIdentifier: No results for " .. name .. "!")
	end
end

function self:ResolveNameIndex (scope, astNameIndex)
	if astNameIndex.ResultsPopulated then return end
	astNameIndex.ResultsPopulated = true
	
	local left = astNameIndex.Left
	local right = astNameIndex.Right
	
	self:Resolve (scope, left)
	if right:Is ("Identifier") then
		local name = right.Name
		print ("ID")
	elseif right:Is ("ParametricName") then
		print ("PARAMETRICNAME")
		for result in left.NameResolutionResults:GetEnumerator () do
			local left = result:GetValue ()
			local leftType = result:GetType ():UnreferenceType ()
			local member, memberReference = left:GetMember (right.Name)
			if memberReference then
				local memberType = memberReference:GetType ():UnreferenceType ()
				
				for i = 1, right:GetArgumentCount () do
					self:ResolveType (right:GetArgument (i))
				end
			end
		end
	else
		GCompute.Error ("NameResolver:ResolveNameIndex : Unknown AST node on right (" .. right.__Type .. ")!")
	end
end

function self:ResolveParametricName (scope, astParametricName)
	if astParametricName.ResultsPopulated then return end
	astParametricName.ResultsPopulated = true
	
	self:ResolveIdentifier (scope, astParametricName.Name)
	
end

GCompute.NameResolver = GCompute.NameResolver ()
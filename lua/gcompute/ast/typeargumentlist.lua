local self = {}
self.__Type = "TypeArgumentList"
GCompute.AST.TypeArgumentList = GCompute.AST.MakeConstructor (self, GCompute.AST.ArgumentList)

function self:ctor ()
end

function self:ToString ()
	local typeParameterList = ""
	for i = 1, self.ArgumentCount do
		if typeParameterList ~= "" then
			typeParameterList = typeParameterList .. ", "
		end
		typeParameterList = typeParameterList .. (self.Arguments [i] and self.Arguments [i]:ToString () or "[Nothing]")
	end
	return "<" .. typeParameterList .. ">"
end

-- Converts this AST.TypeArgumentList to a TypeArgumentList.
function self:ToTypeArgumentList ()
	local typeArgumentList = GCompute.TypeArgumentList ()
	for argument in self:GetEnumerator () do
		-- resolvedObject should always be a Type or TypeDefinition (which is a Type) or OverloadedTypeDefinition here.
		local resolvedObject = argument and argument.ResolutionResults:GetFilteredResultObject (1)
		if resolvedObject and resolvedObject:UnwrapAlias ():IsOverloadedTypeDefinition () then
			resolvedObject = resolvedObject:GetType (1):UnwrapAlias ()
		end
		typeArgumentList:AddArgument (resolvedObject or GCompute.PlaceholderType ())
	end
	return typeArgumentList
end

function self:Visit (astVisitor, ...)
	for i = 1, self:GetArgumentCount () do
		local argument = self:GetArgument (i)
		if argument then
			self:SetArgument (i, argument:Visit (astVisitor, ...) or argument)
		end
	end
	
	local astOverride = astVisitor:VisitTypeArgumentList (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
end

GCompute.AST.EmptyTypeArgumentList = GCompute.AST.TypeArgumentList ()
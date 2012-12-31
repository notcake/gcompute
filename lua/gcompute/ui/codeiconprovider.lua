local self = {}
GCompute.CodeIconProvider = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:GetIconForObjectDefinition (objectDefinition)
	local isAlias = objectDefinition:IsAlias ()
	
	if isAlias then
		return "icon16/link_go.png"
	end
	
	if objectDefinition:IsClass () then
		if objectDefinition:GetTypeParameterList ():IsEmpty () then
			return "gui/codeicons/class"
		else
			return "gui/codeicons/parametrictype"
		end
	elseif objectDefinition:IsOverloadedClass () then
		if objectDefinition:GetClassCount () == 1 then
			return self:GetIconForObjectDefinition (objectDefinition:GetClass (1))
		end
		return "gui/codeicons/class"
	elseif objectDefinition:IsEvent () then
		return "icon16/lightning.png"
	elseif objectDefinition:IsMethod () or
	       objectDefinition:IsOverloadedMethod () then
		return "gui/codeicons/method"
	elseif objectDefinition:IsNamespace () then
		return "gui/codeicons/namespace"
	elseif objectDefinition:IsProperty () then
		return "gui/codeicons/application_double"
	elseif objectDefinition:IsTypeParameter () then
		return "gui/codeicons/parametrictype"
	elseif objectDefinition:IsVariable () then
		return "gui/codeicons/field"
	end
	return "icon16/exclamation.png"
end

GCompute.CodeIconProvider = GCompute.CodeIconProvider ()
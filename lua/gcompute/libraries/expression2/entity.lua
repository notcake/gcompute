local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Entity = Expression2:AddClass ("entity")
Entity:SetNullable (false)
Entity:SetPrimitive (true)
Entity:SetDefaultValueCreator (
	function ()
		return ents.GetByIndex (-1)
	end
)

Expression2:AddMethod ("noentity")
	:SetReturnType ("entity")
	:SetNativeFunction (
		function ()
			return ents.GetByIndex (-1)
		end
	)

Entity:AddConstructor ("number entIndex")
	:SetNativeFunction (ents.GetByIndex)

Entity:AddMethod ("ToString")
	:SetReturnType ("String")
	:SetNativeFunction (tostring)
	
Entity:AddMethod ("toString")
	:SetReturnType ("string")
	:SetNativeFunction (tostring)
	
Entity:AddMethod ("isPlayer")
	:SetReturnType ("bool")
	:SetNativeString ("%self%:IsPlayer ()")
	:SetNativeFunction (IsPlayer)
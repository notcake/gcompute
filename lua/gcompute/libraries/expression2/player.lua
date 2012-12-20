local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Player = Expression2:AddClass ("player")
Player:AddBaseType ("entity")
Player:SetNullable (false)
Player:SetPrimitive (true)
Player:SetDefaultValueCreator (
	function ()
		return ents.GetByIndex (-1)
	end
)
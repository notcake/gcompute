local Global = GCompute.GlobalNamespace
local Collections = Global:AddNamespace ("Collections")

local List = Collections:AddClass ("List", "T")
	:AddBaseType ("IEnumerable<T>")
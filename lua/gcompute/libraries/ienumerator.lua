local Global = GCompute.GlobalNamespace
local IEnumerator = Global:AddClass ("IEnumerator", "T")

IEnumerator:AddProperty ("Current", "T")
	:AddGetter ()

IEnumerator:AddMethod ("MoveNext")
	:SetReturnType ("bool")

IEnumerator:AddMethod ("Reset")
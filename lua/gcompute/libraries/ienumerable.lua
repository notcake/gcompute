local Global = GCompute.GlobalNamespace
local IEnumerable = Global:AddClass ("IEnumerable", "T")

IEnumerable:AddMethod ("GetEnumerator")
	:SetReturnType ("IEnumerator<T>")
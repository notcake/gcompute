local Global = GCompute.GlobalNamespace
local Type = Global:AddClass ("Type")
Type:SetNativelyAllocated (true)

Global:GetTypeSystem ():SetType (Type)

Type:AddMethod ("ToString")
	:SetNativeFunction (
		function (type)
			return type:GetFullName ()
		end
	)
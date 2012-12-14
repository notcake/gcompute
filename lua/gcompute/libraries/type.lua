local Global = GCompute.GlobalNamespace
local Type = Global:AddType ("Type")
Type:SetNativelyAllocated (true)

Global:GetTypeSystem ():SetType (Type)

Type:AddFunction ("ToString")
	:SetNativeFunction (
		function (type)
			return type:GetFullName ()
		end
	)
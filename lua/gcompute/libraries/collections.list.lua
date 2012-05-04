local G = GCompute.GlobalScope
local Collections = G:AddNamespace ("Collections")

local Type = nil
local Function = nil
Type = Collections:AddType ("List")
Type:AddArgument ("Type", "T")
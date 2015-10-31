TOOL.Category   = "GCompute"
TOOL.Name       = "Chip - Computation Core"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

TOOL.ClientConVar =
{
	model = "models/beer/wiremod/gate_e2.mdl"
}

if CLIENT then
	language.Add ("Tool_gcompute_core_name",      "GCompute Tool")
	language.Add ("Tool_gcompute_core_desc",      "Spawns a GCompute Core.")
	language.Add ("Tool_gcompute_core_0",         "Primary: Create / update Core, Secondary: Open Core's source file in editor.")
	language.Add ("sboxlimit_gcompute_core",      "You've hit the GCompute Core limit!")
	language.Add ("Undone_gcompute_core",         "Undone Core")
	language.Add ("Cleanup_gcompute_cores",       "GCompute Cores")
	language.Add ("Cleaned_gcompute_cores",       "Cleaned up all GCompute Cores.")
end

cleanup.Register ("gcompute_cores")

if SERVER then
	CreateConVar ("sbox_maxgcompute_cores", 20)
	
	function TOOL:RightClick (trace)
		local owner = self:GetOwner ()
		if not owner or not owner:IsValid () then return false end
		umsg.Start ("gcompute_open_editor", owner)
		umsg.End ()
		return false
	end
elseif CLIENT then
	usermessage.Hook ("gcompute_open_editor",
		function (umsg)
			GCompute.IDE.GetInstance():GetFrame():SetVisible (true)
		end
	)
end

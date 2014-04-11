GCompute.Services.ConnectionRunner = GLib.Net.ConnectionRunner ()

GCompute:AddEventListener ("Unloaded", "GCompute.ConnectionRunner",
	function ()
		GCompute.Services.ConnectionRunner:dtor ()
		GCompute.Services.ConnectionRunner = nil
	end
)
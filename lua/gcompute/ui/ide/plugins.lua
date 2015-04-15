GCompute.IDE.Plugins = {}
GCompute.IDE.Plugins.PluginConstructors = {}
GCompute.IDE.Plugins.Plugins = {}

function GCompute.IDE.Plugins:Create (pluginName)
	local plugin = {}
	plugin.Initialize   = GCompute.NullCallback
	plugin.Uninitialize = GCompute.NullCallback
	self.PluginConstructors [pluginName] = GCompute.MakeConstructor (plugin)
	return plugin
end

function GCompute.IDE.Plugins:Initialize (...)
	for pluginName, ctor in pairs (self.PluginConstructors) do
		local success, plugin = xpcall (ctor, GLib.Error, ...)
		if success then
			self.Plugins [pluginName] = plugin
		end
	end
end

function GCompute.IDE.Plugins:Uninitialize (...)
	for _, plugin in pairs (self.Plugins) do
		xpcall (plugin.dtor, GLib.Error, plugin, ...)
	end
	self.Plugins = {}
end
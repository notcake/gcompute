GCompute.IDE.Plugins = {}
GCompute.IDE.Plugins.PluginConstructors = {}
GCompute.IDE.Plugins.Plugins = {}

function GCompute.IDE.Plugins:Create (pluginName)
	local plugin = {}
	plugin.Initialize = GCompute.NullCallback
	plugin.Uninitialize = GCompute.NullCallback
	self.PluginConstructors [pluginName] = GCompute.MakeConstructor (plugin)
	return plugin
end

function GCompute.IDE.Plugins:Initialize (...)
	for pluginName, ctor in pairs (self.PluginConstructors) do
		self.Plugins [pluginName] = ctor (...)
	end
end

function GCompute.IDE.Plugins:Uninitialize (...)
	for _, plugin in pairs (self.Plugins) do
		plugin:dtor (...)
	end
	self.Plugins = {}
end
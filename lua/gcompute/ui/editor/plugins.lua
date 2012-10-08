GCompute.Editor.Plugins = {}
GCompute.Editor.Plugins.PluginConstructors = {}
GCompute.Editor.Plugins.Plugins = {}

function GCompute.Editor.Plugins:Create (pluginName)
	local plugin = {}
	plugin.Initialize = GCompute.NullCallback
	plugin.Uninitialize = GCompute.NullCallback
	self.PluginConstructors [pluginName] = GCompute.MakeConstructor (plugin)
	return plugin
end

function GCompute.Editor.Plugins:Initialize (...)
	for pluginName, ctor in pairs (self.PluginConstructors) do
		self.Plugins [pluginName] = ctor (...)
	end
end

function GCompute.Editor.Plugins:Uninitialize (...)
	for _, plugin in pairs (self.Plugins) do
		plugin:dtor (...)
	end
	self.Plugins = {}
end
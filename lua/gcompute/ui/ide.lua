if GCompute.IDE then return end
GCompute.IDE = {}

function GCompute.IDE.GetInstance ()
	if not GCompute.IDE.Instance then
		GCompute.IDE.Instance = GCompute.IDE.IDE ()
		GCompute:AddEventListener ("Unloaded",
			function ()
				GCompute.IDE.Instance:dtor ()
			end
		)
	end
	return GCompute.IDE.Instance
end

-- Documents
include ("ide/document.lua")
include ("ide/documenttype.lua")
include ("ide/documenttypes.lua")
include ("ide/documentmanager.lua")

-- Subviews
include ("ide/subview.lua")

-- Views
include ("ide/view.lua")
include ("ide/viewtype.lua")
include ("ide/viewtypes.lua")
include ("ide/viewmanager.lua")

-- Serializers
include ("ide/serializer.lua")
include ("ide/serializertype.lua")
include ("ide/serializerregistry.lua")

-- IDE
include ("ide/ide.lua")
include ("ide/ideframe.lua")
include ("ide/menustrip.lua")
include ("ide/plugins.lua")
include ("ide/savableproxy.lua")
include ("ide/tabcontextmenu.lua")
include ("ide/toolbar.lua")
include ("ide/undoredostackproxy.lua")

-- Keyboard Shortcuts and Plugins
GCompute.IDE.KeyboardMap = Gooey.KeyboardMap ()
GCompute.IncludeDirectory ("gcompute/ui/ide/keyboardmap")
GCompute.IncludeDirectory ("gcompute/ui/ide/plugins")

-- Actions
GCompute.IDE.ActionMap = Gooey.ActionMap ()
GCompute.IncludeDirectory ("gcompute/ui/ide/actions")

-- Notification Bars
include ("ide/notificationbars/notificationbar.lua")
include ("ide/notificationbars/filechangenotificationbar.lua")
include ("ide/notificationbars/savefailurenotificationbar.lua")

-- Undo / Redo
include ("ide/undoredo/undoredostack.lua")
include ("ide/undoredo/undoredoitem.lua")
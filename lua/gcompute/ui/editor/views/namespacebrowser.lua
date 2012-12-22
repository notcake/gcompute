local self = GCompute.Editor.ViewTypes:CreateType ("NamespaceBrowser")

function self:ctor (container)
	self.ComboBox = vgui.Create ("GComboBox", container)
	self.ComboBox:AddChoice ("Lua - GLib",     function () return GCompute.Lua.Table ("GLib",     GLib    ) end)
	self.ComboBox:AddChoice ("Lua - GAuth",    function () return GCompute.Lua.Table ("GAuth",    GAuth   ) end)
	self.ComboBox:AddChoice ("Lua - VFS",      function () return GCompute.Lua.Table ("VFS",      VFS     ) end)
	self.ComboBox:AddChoice ("Lua - GCompute", function () return GCompute.Lua.Table ("GCompute", GCompute) end)
	self.ComboBox:AddChoice ("Lua - GVote",    function () return GCompute.Lua.Table ("GVote",    GVote   ) end)
	self.ComboBox:AddChoice ("GCompute",       function () return GCompute.GlobalNamespace end)
	self.ComboBox:AddChoice ("Expression 2",   function () return GCompute.Other.Expression2Namespace () end)
	self.ComboBox:AddChoice ("Lemon Gate",     function () return GCompute.Other.LemonGateNamespace () end)
	
	self.ComboBox:AddEventListener ("SelectedItemChanged",
		function (_, text, data)
			local namespaceDefinition = data ()
			if not namespaceDefinition then return end
			self:SetNamespaceDefinition (namespaceDefinition)
		end
	)
	
	self.NamespaceBrowser = vgui.Create ("GComputeNamespaceTreeView", container)
	
	self:SetNamespaceDefinition (GCompute.GlobalNamespace)
	
	function container.PerformLayout ()
		local w, h = container:GetSize ()
		self.ComboBox:SetPos (0, 0)
		self.ComboBox:SetWide (w)
		self.NamespaceBrowser:SetPos (0, self.ComboBox:GetTall () + 4)
		self.NamespaceBrowser:SetSize (w, h - self.ComboBox:GetTall () - 4)
	end
	
	self:SetTitle ("Namespace Browser")
	self:SetIcon ("icon16/application_side_list.png")
	
	self.ComboBox:ChooseOptionID (6)
end

function self:SetNamespaceDefinition (namespaceDefinition)
	self.NamespaceBrowser:SetNamespaceDefinition (namespaceDefinition)
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end
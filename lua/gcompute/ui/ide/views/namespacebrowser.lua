local self, info = GCompute.IDE.ViewTypes:CreateType ("NamespaceBrowser")
self.Title = "Namespace Browser"
self.Icon  = "icon16/application_side_list.png"

function self:ctor (container)
	self.ComboBox = vgui.Create ("GComboBox", container)
	self.ComboBox:AddItem ("Lua - GLib"    ).GetNamespace = function (_) return GCompute.Lua.Table ("GLib",     GLib    ) end
	self.ComboBox:AddItem ("Lua - GAuth"   ).GetNamespace = function (_) return GCompute.Lua.Table ("GAuth",    GAuth   ) end
	self.ComboBox:AddItem ("Lua - VFS"     ).GetNamespace = function (_) return GCompute.Lua.Table ("VFS",      VFS     ) end
	self.ComboBox:AddItem ("Lua - GCompute").GetNamespace = function (_) return GCompute.Lua.Table ("GCompute", GCompute) end
	self.ComboBox:AddItem ("Lua - GVote"   ).GetNamespace = function (_) return GCompute.Lua.Table ("GVote",    GVote   ) end
	self.ComboBox:AddItem ("GCompute"      ).GetNamespace = function (_) return GCompute.GlobalNamespace                  end
	self.ComboBox:AddItem ("Expression 2"  ).GetNamespace = function (_) return GCompute.Other.Expression2Namespace ()    end
	
	-- Add all languages
	local languages = GLib.Enumerator.ToArray (GCompute.Languages.GetEnumerator ())
	table.sort (languages,
		function (a, b)
			return a:GetName () < b:GetName ()
		end
	)
	for _, language in ipairs (languages) do
		self.ComboBox:AddItem (language:GetName ()).GetNamespace = function (_)
			return language:GetEditorHelper ():GetRootNamespace ()
		end
	end
	
	self.ComboBox:AddEventListener ("SelectedItemChanged",
		function (_, lastSelectedItem, selectedItem)
			local namespaceDefinition = selectedItem:GetNamespace ()
			if not namespaceDefinition then return end
			
			self:SetNamespaceDefinition (namespaceDefinition)
		end
	)
	
	self.NamespaceBrowser = vgui.Create ("GComputeNamespaceTreeView", container)
	
	self:SetNamespaceDefinition (GCompute.GlobalNamespace)
	
	self.ComboBox:SetSelectedItem ("GCompute")
end

function self:SetNamespaceDefinition (namespaceDefinition)
	self.NamespaceBrowser:SetNamespaceDefinition (namespaceDefinition)
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end

-- Event handlers
function self:PerformLayout (w, h)
	self.ComboBox:SetPos (0, 0)
	self.ComboBox:SetWide (w)
	self.NamespaceBrowser:SetPos (0, self.ComboBox:GetTall () + 4)
	self.NamespaceBrowser:SetSize (w, h - self.ComboBox:GetTall () - 4)
end
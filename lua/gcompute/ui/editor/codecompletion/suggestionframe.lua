local self = {}

function self:Init ()
	self.Control = nil
	
	self:SetSize (256, 128)
	
	self.ResizeGrip = vgui.Create ("GResizeGrip", self)
	self.ResizeGrip:SetSize (16, 16)
	
	self.ListBox = vgui.Create ("GListBox", self)
	self.ListBox:SetKeyboardInputEnabled (false)
	self.ListBox:SetSelectionMode (Gooey.SelectionMode.One)
	
	self.ListBox:AddEventListener ("SelectionChanged",
		function (_, listBoxItem)
			self.ListBox:EnsureVisible (listBoxItem)
		end
	)
	
	self.ObjectDefinitionSet = {}
	
	self.LastShowTime = CurTime ()
	
	self:SetVisible (false)
	
	self:AddEventListener ("VisibleChanged",
		function (_, visible)
			if visible then
				self:MakePopup ()
				self:MoveToFront ()
				self:SetKeyboardInputEnabled (false)
				self.LastShowTime = CurTime ()
			end
		end
	)
	
	GCompute:AddEventListener ("Unloaded", tostring (self:GetTable ()),
		function ()
			self:Remove ()
		end
	)
end

function self:AddObjectDefinition (objectDefinition)
	if not objectDefinition then return end
	if self.ObjectDefinitionSet [objectDefinition] then return end
	
	if objectDefinition:IsOverloadedClass () and objectDefinition:GetClassCount () == 1 then
		objectDefinition = objectDefinition:GetClass (1)
	elseif objectDefinition:IsOverloadedMethod () and objectDefinition:GetMethodCount () == 1 then
		objectDefinition = objectDefinition:GetMethod (1)
	end
	
	self.ObjectDefinitionSet [objectDefinition] = true
	
	local listBoxItem = self.ListBox:AddItem (objectDefinition:GetShortName ())
	listBoxItem.ObjectDefinition = objectDefinition
	listBoxItem:SetFont (self:GetFont ())
	listBoxItem:SetIcon (GCompute.CodeIconProvider:GetIconForObjectDefinition (objectDefinition))
	
	if not self.ListBox:GetSelectedItem () then
		self.ListBox:SetSelectedItem (listBoxItem)
	end
	
	return listBoxItem
end

function self:Clear ()
	self.ObjectDefinitionSet = {}
	self.ListBox:Clear ()
end

function self:GetBorderThickness ()
	return 6
end

function self:GetItemCount ()
	return self.ListBox:GetItemCount ()
end

function self:GetSelectedItem ()
	local listBoxItem = self.ListBox:GetSelectedItem ()
	if not listBoxItem then return nil end
	return listBoxItem.ObjectDefinition
end

function self:IsEmpty ()
	return self.ListBox:IsEmpty ()
end

function self:Paint (w, h)
	draw.RoundedBox (4, 0, 0, w, h, GLib.Colors.Silver)
end

function self:PerformLayout ()
	local w, h = self:GetSize ()
	self.ListBox:SetPos (self:GetBorderThickness (), self:GetBorderThickness ())
	self.ListBox:SetSize (w - self:GetBorderThickness () * 2, h - self:GetBorderThickness () * 2)
end

function self:SelectById (id)
	local listBoxItem = self.ListBox:GetItemBySortedId (id)
	if not listBoxItem then return end
	listBoxItem:Select ()
end

function self:SelectPrevious ()
	A = self.ListBox
	local selectedItem = self.ListBox:GetSelectedItem ()
	local selectedSortedId = 0
	if selectedItem then
		selectedSortedId = selectedItem:GetSortedId () - 1
	end
	if selectedSortedId < 1 then
		selectedSortedId = self.ListBox:GetItemCount ()
	end
	self.ListBox:SetSelectedItem (self.ListBox:GetItemBySortedId (selectedSortedId))
end

function self:SelectNext ()
	A = self.ListBox
	local selectedItem = self.ListBox:GetSelectedItem ()
	local selectedSortedId = 1
	if selectedItem then
		selectedSortedId = selectedItem:GetSortedId () + 1
	end
	if selectedSortedId > self.ListBox:GetItemCount () then
		selectedSortedId = 1
	end
	self.ListBox:SetSelectedItem (self.ListBox:GetItemBySortedId (selectedSortedId))
end

function self:SetAlignedPos (x, y)
	x = x - self:GetBorderThickness ()
	x = x - 1  -- ListBox border
	x = x - 16
	x = x - 8
	self:SetPos (x, y)
end

function self:SetControl (control)
	self.Control = control
end

function self:Sort ()
	self.ListBox:Sort (
		function (a, b)
			return a:GetText ():lower () < b:GetText ():lower ()
		end
	)
end

-- Event handlers
function self:OnRemove ()
	GCompute:RemoveEventListener ("Unloaded", tostring (self:GetTable ()))
end

function self:Think ()
	if not self.Control then return end
	
	local x, y = self:CursorPos ()
	local containsMouse = x >= 0 and x < self:GetWide () and
	                      y >= 0 and y < self:GetTall ()
	containsMouse = containsMouse or self.ResizeGrip:IsPressed ()
	if self.Control:IsVisible () and
	   not self.Control:HasHierarchicalFocus () and
	   not self:HasHierarchicalFocus () and
	   not containsMouse and
	   CurTime () ~= self.LastShowTime then
		self:SetVisible (false)
	else
		self:MoveToFront ()
	end
end

Gooey.Register ("GComputeCodeSuggestionFrame", self, "GPanel")
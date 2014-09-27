local self = {}

--[[
	Events:
		ItemChosen (SuggestionType itemType, item)
			Fired when the user has double clicked an item.
]]

function self:Init ()
	self.Control = nil
	
	self:SetSize (256, 128)
	
	self.ResizeGrip = vgui.Create ("GResizeGrip", self)
	self.ResizeGrip:SetSize (16, 16)
	
	self.ListBox = vgui.Create ("GListBox", self)
	
	self.ListBox:SetKeyboardInputEnabled (false)
	self.ListBox:SetSelectionMode (Gooey.SelectionMode.One)
	
	self.ListBox.IsFocused = function () return true end
	
	self.ListBox:AddEventListener ("DoubleClick",
		function (_, item)
			if not self:GetSelectedItem () then return end
			self:DispatchEvent ("ItemChosen", self:GetSelectedItemType (), self:GetSelectedItem ())
		end
	)
	
	self.ListBox:AddEventListener ("Scroll",
		function (_, scrollOffset)
			self:UpdateToolTip ()
		end
	)
	
	self.ListBox:AddEventListener ("SelectionChanged",
		function (_, listBoxItem)
			self:UnhookSelectedItem (self.SelectedItem)
			self.ListBox:EnsureVisible (listBoxItem)
			self.SelectedItem = listBoxItem
			self:HookSelectedItem (self.SelectedItem)
			
			self:UpdateToolTip ()
		end
	)
	
	self.SelectedItem = nil
	
	self.ToolTip = vgui.Create ("GToolTip")
	self.ToolTip.ShouldHideFrameCount = 0
	self.ToolTip.Think = function ()
		-- Hide the ToolTip if our control is not visible
		local parent = self.Control
		while parent do
			if not parent:IsVisible () then
				self.ToolTip:SetVisible (false)
				return
			end
			parent = parent:GetParent ()
		end
		
		if self:ShouldHide (self.LastToolTipShowTime) then
			self.ToolTip.ShouldHideFrameCount = self.ToolTip.ShouldHideFrameCount + 1
		else
			self.ToolTip.ShouldHideFrameCount = 0
		end
		if self.ToolTip.ShouldHideFrameCount >= 5 then
			self.ToolTip:SetVisible (false)
		end
	end
	
	self.ToolTip:AddEventListener ("VisibleChanged",
		function (_, visible)
			if visible then
				self.LastToolTipShowTime = CurTime ()
			end
		end
	)
	
	self.ObjectDefinitionSet = {}
	self.KeywordSet          = {}
	
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
			self:UpdateToolTip ()
		end
	)
	
	GCompute:AddEventListener ("Unloaded", self:GetHashCode (),
		function ()
			self:Remove ()
		end
	)
end

function self:AddObjectDefinition (objectDefinition)
	if not objectDefinition then return end
	if self.ObjectDefinitionSet [objectDefinition] then return end
	self.ObjectDefinitionSet [objectDefinition] = true
	
	if objectDefinition:IsOverloadedClass () and objectDefinition:GetClassCount () == 1 then
		objectDefinition = objectDefinition:GetClass (1)
	elseif objectDefinition:IsOverloadedMethod () and objectDefinition:GetMethodCount () == 1 then
		objectDefinition = objectDefinition:GetMethod (1)
	end
	self.ObjectDefinitionSet [objectDefinition] = true
	
	local listBoxItem = self:CreateSuggestionItem (objectDefinition:GetShortName ())
	listBoxItem:SetIcon (GCompute.CodeIconProvider:GetIconForObjectDefinition (objectDefinition))
	listBoxItem.SuggestionItem = objectDefinition
	listBoxItem.SuggestionType = GCompute.CodeEditor.CodeCompletion.SuggestionType.Definition
	
	return listBoxItem
end

function self:AddKeyword (keyword)
	if not keyword then return end
	if self.KeywordSet [keyword] then return end
	self.KeywordSet [keyword] = true
	
	local listBoxItem = self:CreateSuggestionItem (keyword)
	listBoxItem:SetIcon ("icon16/text_padding_top.png")
	listBoxItem.SuggestionItem = keyword
	listBoxItem.SuggestionType = GCompute.CodeEditor.CodeCompletion.SuggestionType.Keyword
	
	return listBoxItem
end

function self:Clear ()
	self.ObjectDefinitionSet = {}
	self.KeywordSet          = {}
	self.ListBox:Clear ()
end

function self:EnsureVisible (listBoxItem)
	self.ListBox:EnsureVisible (listBoxItem)
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
	return listBoxItem.SuggestionItem
end

function self:GetSelectedItemType ()
	local listBoxItem = self.ListBox:GetSelectedItem ()
	if not listBoxItem then return GCompute.CodeEditor.CodeCompletion.SuggestionType.None end
	return listBoxItem.SuggestionType
end

function self:IsEmpty ()
	return self.ListBox:IsEmpty ()
end

function self:IsToolTipVisible ()
	return self.ToolTip:IsVisible ()
end

function self:Paint (w, h)
	draw.RoundedBox (4, 0, 0, w, h, GLib.Colors.Silver)
end

function self:PerformLayout ()
	local w, h = self:GetSize ()
	self.ListBox:SetPos (self:GetBorderThickness (), self:GetBorderThickness ())
	self.ListBox:SetSize (w - self:GetBorderThickness () * 2, h - self:GetBorderThickness () * 2)
	self.ListBox:InvalidateLayout ()
	
	self:UpdateToolTip ()
end

function self:SelectById (id)
	local listBoxItem = self.ListBox:GetItem (id)
	if not listBoxItem then return end
	listBoxItem:Select ()
end

function self:SelectItem (listBoxItem)
	if not listBoxItem then return end
	self.ListBox:SetSelectedItem (listBoxItem)
end

function self:SelectPrevious ()
	local selectedItem = self.ListBox:GetSelectedItem ()
	local selectedSortedIndex = 0
	if selectedItem then
		selectedSortedIndex = selectedItem:GetSortedIndex () - 1
	end
	if selectedSortedIndex < 1 then
		selectedSortedIndex = self.ListBox:GetItemCount ()
	end
	self.ListBox:SetSelectedItem (self.ListBox:GetItemBySortedIndex (selectedSortedIndex))
end

function self:SelectNext ()
	local selectedItem = self.ListBox:GetSelectedItem ()
	local selectedSortedIndex = 1
	if selectedItem then
		selectedSortedIndex = selectedItem:GetSortedIndex () + 1
	end
	if selectedSortedIndex > self.ListBox:GetItemCount () then
		selectedSortedIndex = 1
	end
	self.ListBox:SetSelectedItem (self.ListBox:GetItemBySortedIndex (selectedSortedIndex))
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

function self:SetSelectedItem (listBoxItem)
	self.ListBox:SetSelectedItem (listBoxItem)
end

function self:SetToolTipVisible (toolTipVisible)
	if not self.ToolTip then return self end
	if not self.ToolTip:IsValid () then return self end
	
	self.ToolTip:SetVisible (toolTipVisible)
	return self
end

function self:ShouldHide (lastShowTime)
	local x, y = self:CursorPos ()
	local containsMouse = x >= 0 and x < self:GetWide () and
	                      y >= 0 and y < self:GetTall ()
	containsMouse = containsMouse or self.ResizeGrip:IsPressed ()
	if self.Control:IsVisible () and
	   not self.Control:IsFocused () and
	   not self.Control:HasHierarchicalFocus () and
	   not self:HasHierarchicalFocus () and
	   not containsMouse and
	   CurTime () > lastShowTime then
		return true
	end
	return false
end

function self:Sort ()
	self.ListBox:Sort (
		function (a, b)
			return a:GetText ():lower () < b:GetText ():lower ()
		end
	)
end

-- Internal, do not call
function self:CreateSuggestionItem (text)
	local listBoxItem = self.ListBox:AddItem (text)
	listBoxItem:SetFont (self:GetFont ())
	
	if not self.ListBox:GetSelectedItem () then
		self.ListBox:SetSelectedItem (listBoxItem)
	end
	
	return listBoxItem
end

function self:HookSelectedItem (listBoxItem)
	if not listBoxItem then return end
	
	listBoxItem:AddEventListener ("PositionChanged", self:GetHashCode (),
		function (_)
			self:UpdateToolTip ()
		end
	)
	listBoxItem:AddEventListener ("SizeChanged", self:GetHashCode (),
		function (_)
			self:UpdateToolTip ()
		end
	)
end

function self:UnhookSelectedItem (listBoxItem)
	if not listBoxItem then return end
	
	listBoxItem:RemoveEventListener ("PositionChanged", self:GetHashCode ())
	listBoxItem:RemoveEventListener ("SizeChanged",     self:GetHashCode ())
end

function self:UpdateToolTip ()
	local selectedItem = self.ListBox:GetSelectedItem ()
	local suggestionItem = self:GetSelectedItem ()
	local suggestionType = self:GetSelectedItemType ()
	
	local hideToolTip = false
	hideToolTip = hideToolTip or not self:IsVisible ()
	hideToolTip = hideToolTip or not self.ListBox:IsItemVisible (selectedItem)
	hideToolTip = hideToolTip or suggestionType == GCompute.CodeEditor.CodeCompletion.SuggestionType.None
	hideToolTip = hideToolTip or suggestionType == GCompute.CodeEditor.CodeCompletion.SuggestionType.Keyword
	
	self.ToolTip:SetVisible (not hideToolTip)
	if hideToolTip then return end
	
	local _, y = selectedItem:LocalToScreen (0, 0)
	local x = self:GetPos () + self:GetWide () + 8
	self.ToolTip:SetPos (x, y)
	
	-- Update contents
	if suggestionItem:IsClass () and suggestionItem:GetConstructorCount () > 0 then
		suggestionItem = suggestionItem:GetConstructor (1)
	end
	if suggestionItem then
		self.ToolTip:SetText (suggestionItem:GetDisplayText ())
	end
end

-- Event handlers
function self:OnRemoved ()
	self.ToolTip:Remove ()
	GCompute:RemoveEventListener ("Unloaded", self:GetHashCode ())
end

function self:Think ()
	if not self.Control then return end
	
	if self:ShouldHide (self.LastShowTime) then
		self:SetVisible (false)
	else
		self:MoveToFront ()
	end
end

Gooey.Register ("GComputeCodeSuggestionFrame", self, "GPanel")
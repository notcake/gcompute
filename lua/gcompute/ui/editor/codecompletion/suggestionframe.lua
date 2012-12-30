local self = {}

function self:Init ()
	self.Control = nil
	
	self:SetSize (256, 128)
	
	self.ResizeGrip = vgui.Create ("GResizeGrip", self)
	self.ResizeGrip:SetSize (16, 16)
	
	self.ListBox = vgui.Create ("GListBox", self)
	self.ListBox:SetKeyboardInputEnabled (false)
	
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
	
	if objectDefinition:IsOverloadedClass () and objectDefinition:GetClassCount () == 1 then
		objectDefinition = objectDefinition:GetClass (1)
	elseif objectDefinition:IsOverloadedMethod () and objectDefinition:GetMethodCount () == 1 then
		objectDefinition = objectDefinition:GetMethod (1)
	end
	
	local listBoxItem = self.ListBox:AddItem (objectDefinition:GetShortName ())
	listBoxItem:SetIcon (GCompute.CodeIconProvider:GetIconForObjectDefinition (objectDefinition))
	return listBoxItem
end

function self:Clear ()
	self.ListBox:Clear ()
end

function self:PerformLayout ()
	local w, h = self:GetSize ()
	self.ListBox:SetPos (8, 8)
	self.ListBox:SetSize (w - 16, h - 16)
end

function self:SetControl (control)
	self.Control = control
end

function self:Sort ()
	self.ListBox:Sort ()
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
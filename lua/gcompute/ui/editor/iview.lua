local self = {}
GCompute.Editor.IView = GCompute.MakeConstructor (self)

--[[
	Events:
		DocumentChanged (oldDocument, newDocument)
			Fired when the view's document has changed.
		IconChanged (icon)
			Fired when the view's icon has changed.
		TitleChanged (title)
			Fired when the view's title has changed.
		ToolTipChanged (toolTip)
			Fired when the view's tooltip text has changed.
]]

function self:ctor (container)
	self.Container = container
	self.Icon = "icon16/cross.png"
	self.Title = "View"
	self.ToolTipText = nil
	
	GCompute.EventProvider (self)
	
	self.Container:AddEventListener ("Removed", tostring (self),
		function ()
			self:DispatchEvent ("Removed")
		end
	)
end

function self:GetType ()
	return self.__Type
end

-- UI
function self:GetContainer ()
	return self.Container
end

function self:GetDocumentManager ()
	return self:GetContainer () and self:GetContainer ():GetDocumentManager ()
end

function self:GetIcon ()
	return self.Icon
end

function self:GetTitle ()
	return self.Title
end

function self:GetToolTipText ()
	return self.ToolTipText
end

function self:Select ()
	if not self.Container then return end
	self.Container:Select ()
end

function self:SetIcon (icon)
	if self.Icon == icon then return end
	
	self.Icon = icon
	self:DispatchEvent ("IconChanged", self.Icon)
end

function self:SetTitle (title)
	if self.Title == title then return end
	
	self.Title = title
	self:DispatchEvent ("TitleChanged", self.Title)
end

function self:SetToolTipText (toolTipText)
	if self.ToolTipText == toolTipText then return end
	
	self.ToolTipText = toolTipText
	self:DispatchEvent ("ToolTipTextChanged", self.ToolTipText)
end

-- Components
function self:GetClipboardTarget ()
	return nil
end

function self:GetDocument ()
	return nil
end

function self:GetSavable ()
	return nil
end

function self:GetUndoRedoStack ()
	return nil
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end
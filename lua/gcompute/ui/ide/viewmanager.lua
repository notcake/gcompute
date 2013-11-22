local self = {}
GCompute.IDE.ViewManager = GCompute.MakeConstructor (self)

--[[
	Events:
		ViewAdded (View view)
			Fired when a view has been added.
		ViewRemoved (View view)
			Fired when a view has been removed.
]]

function self:ctor ()
	-- IDE
	self.IDE        = nil
	self.ViewTypes  = nil
	
	-- Views
	self.Views      = {}
	self.ViewsById  = {}
	self.ViewCount  = 0
	
	self.NextViewId = 0
	
	GCompute.EventProvider (self)
end

-- IDE
function self:GetDocumentManager ()
	if not self.IDE then return nil end
	return self.IDE:GetDocumentManager ()
end

function self:GetIDE ()
	return self.IDE
end

function self:GetViewTypes ()
	return self.ViewTypes
end

function self:SetIDE (ide)
	self.IDE = ide
end

function self:SetViewTypes (viewTypes)
	self.ViewTypes = viewTypes
end

-- Views
function self:AddView (view)
	if self.Views [view] then return end
	
	self.Views [view] = true
	if not view:GetId () then
		view:SetId (self:GenerateViewId (view))
	end
	self.ViewsById [view:GetId ()] = view
	self.ViewCount = self.ViewCount + 1
	
	view:SetIDE (self:GetIDE ())
	view:SetViewManager (self)
	
	self:HookView (view)
	
	self:DispatchEvent ("ViewAdded", view)
end

function self:Clear ()
	for view, _ in pairs (self.Views) do
		self.ViewCount = self.ViewCount - 1
		self:UnhookView (view)
	
		self:DispatchEvent ("ViewRemoved", view)
	end
	
	self.Views = {}
	self.ViewsById = {}
end

function self:CreateView (viewType, viewId)
	local view = self.ViewTypes:Create (viewType)
	if not view then return nil end
	view:SetId (viewId or self:GenerateViewId ())
	self:AddView (view)
	
	return view
end

function self:GenerateViewId (view)
	while self.ViewsById [tostring (self.NextViewId)] do
		self.NextViewId = self.NextViewId + 1
	end
	self.NextViewId = self.NextViewId + 1
	return tostring (self.NextViewId - 1)
end

function self:GetEnumerator ()
	local next, tbl, key = pairs (self.Views)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:GetViewById (viewId)
	return self.ViewsById [viewId]
end

function self:GetViewCount ()
	return self.ViewCount
end

function self:RemoveView (view)
	if not self.Views [view] then return end
	
	self.Views [view] = nil
	self.ViewsById [view:GetId ()] = nil
	self.ViewCount = self.ViewCount - 1
	
	self:UnhookView (view)
	
	self:DispatchEvent ("ViewRemoved", view)
end

-- Persistance
function self:LoadSession (inBuffer)
	local viewId = inBuffer:String ()
	while viewId ~= "" do
		local viewType = inBuffer:String ()
		local visible = inBuffer:Boolean ()
		local subInBuffer = GLib.StringInBuffer (inBuffer:String ())
		local view = self:GetViewById (viewId) or self:CreateView (viewType, viewId)
		if view then
			view:SetVisible (visible)
			view:LoadSession (subInBuffer)
			self:AddView (view)
		end
		
		inBuffer:Char () -- Discard newline
		viewId = inBuffer:String ()
	end
	
	inBuffer:Char () -- Discard newline
end

function self:SaveSession (outBuffer)
	local subOutBuffer = GLib.StringOutBuffer ()
	
	for view in self:GetEnumerator () do
		outBuffer:String (view:GetId ())
		outBuffer:String (view:GetType ())
		outBuffer:Boolean (view:IsVisible ())
		subOutBuffer:Clear ()
		view:SaveSession (subOutBuffer)
		outBuffer:String (subOutBuffer:GetString ())
		outBuffer:Char ("\n")
	end
	outBuffer:String ("")
	outBuffer:Char ("\n")
end

-- Internal, do not call
function self:HookView (view)
	if not view then return end
end

function self:UnhookView (view)
	if not view then return end
end
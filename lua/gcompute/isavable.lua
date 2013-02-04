local self = {}
GCompute.ISavable = GCompute.MakeConstructor (self)

--[[
	Events:
		CanSaveChanged (bool canSave)
			Fired when the presence of savable changes has changed.
		Reloaded ()
			Fired when the copy from disk is about to be reloaded.
		Reloading ()
			Fired when the copy from disk has been reloaded.
		ResourceChanged (IResource oldResource, IResource resource)
			Fired when the resource has changed.
		Saved (bool success)
			Fired when this object has been attempted to be saved.
		SaveFailed ()
			Fired when this object has failed to be saved.
		Saving ()
			Fired when this object is about to be saved.
		UnsavedChanged (bool unsaved)
			Fired when this object's unsaved status has changed.
		UriChanged (oldUri, uri)
			Fired when the uri has changed.
]]

function self:ctor ()
	self.Resource = nil
	self.Uri      = nil
	
	GCompute.EventProvider (self)
end

function self:CanSave ()
	return false
end

function self:GetResource ()
	return self.Resource
end

function self:GetUri ()
	return self.Uri
end

function self:HasResource ()
	return self.Resource and true or false
end

function self:HasUri ()
	return self.Uri and true or false
end

function self:IsUnsaved ()
	return false
end

function self:Reload ()
end

function self:Save ()
	self:DispatchEvent ("Saved", true)
end

function self:SetResource (resource)
	if self.Resource == resource then return end
	
	local oldResource = self.Resource
	self.Resource = resource
	self:SetUri (self.Resource and self.Resource:GetUri () or nil)
	
	self:DispatchEvent ("ResourceChanged", oldResource, self.Resource)
end

function self:SetUri (uri)
	if self.Uri == uri then return end
	
	local oldUri = self.Uri
	self.Uri = nil -- Suppress extra UriChanged event
	if self.Resource and self.Resource:GetUri () ~= uri then
		self:SetResource (nil)
	end
	self.Uri = uri
	
	self:DispatchEvent ("UriChanged", oldUri, self.Uri)
end
local self = {}
GCompute.ISavable = GCompute.MakeConstructor (self)

--[[
	Events:
		CanSaveChanged (bool canSave)
			Fired when the presence of savable changes has changed.
		FileChanged (IFile oldFile, IFile file)
			Fired when the file has changed.
		PathChanged (oldPath, path)
			Fired when the path has changed.
		Reloaded ()
			Fired when the copy from disk is about to be reloaded.
		Reloading ()
			Fired when the copy from disk has been reloaded.
		Saved (bool success)
			Fired when this object has been attempted to be saved.
		Saving ()
			Fired when this object is about to be saved.
		UnsavedChanged (bool unsaved)
			Fired when this object's unsaved status has changed.
]]

function self:ctor ()
	self.File = nil
	self.Path = nil
	
	GCompute.EventProvider (self)
end

function self:CanSave ()
	return false
end

function self:GetFile ()
	return self.File
end

function self:GetPath ()
	return self.Path
end

function self:HasFile ()
	return self.File and true or false
end

function self:HasPath ()
	return self.Path and true or false
end

function self:IsUnsaved ()
	return false
end

function self:Reload ()
end

function self:Save ()
	self:DispatchEvent ("Saved", true)
end

function self:SetFile (file)
	if self.File == file then return end
	
	local oldFile = self.File
	self.File = file
	self:SetPath (self.File and self.File:GetPath () or nil)
	
	self:DispatchEvent ("FileChanged", oldFile, self.File)
end

function self:SetPath (path)
	if self.Path == path then return end
	
	local oldPath = self.Path
	self.Path = nil -- Suppress extra PathChanged event
	if self.File and self.File:GetPath () ~= path then
		self:SetFile (nil)
	end
	self.Path = path
	
	self:DispatchEvent ("PathChanged", oldPath, self.Path)
end
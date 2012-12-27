local self = {}
GCompute.Editor.Document = GCompute.MakeConstructor (self, GCompute.ISavable)

--[[
	Events:
		PathChanged (oldPath, path)
			Fired when this document's path has changed.
		Reloaded ()
			Fired when this document has finished reloading the copy from disk.
		Reloading ()
			Fired when this document is about to reload the copy from disk.
		ViewAdded (IView view)
			Fired when this document is opened in an IView.
		ViewRemoved (IView view)
			Fired when an IView for this document is closed.
]]

function self:ctor ()
	self.Title = nil
	self.Id = nil
	
	-- ISavable
	self.SavePoint = nil
	
	self.Views   = {}
	self.ViewSet = {}
	
	self.UndoRedoStack = GCompute.UndoRedoStack ()
	self.UndoRedoStack:AddEventListener ("StackChanged",
		function ()
			self:DispatchEvent ("CanSaveChanged", self:CanSave ())
			self:DispatchEvent ("UnsavedChanged", self:IsUnsaved ())
		end
	)
end

function self:GetId ()
	return self.Id
end

function self:GetType ()
	return self.__Type
end

function self:GetUndoRedoStack ()
	return self.UndoRedoStack
end

function self:SetId (id)
	self.Id = id
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end

-- ISavable
function self:CanSave ()
	if self:IsUnsaved () then return true end
	if not self:HasPath () then return true end
	return false
end

function self:IsUnsaved ()
	return self.SavePoint ~= self:GetUndoRedoStack ():GetUndoItem ()
end

function self:LoadFromStream (fileStream, callback)
	callback = callback or GCompute.NullCallback ()
	callback ()
end

function self:MarkSaved ()
	if not self:IsUnsaved () then return end
	self.SavePoint = self:GetUndoRedoStack ():GetUndoItem ()
	
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
	self:DispatchEvent ("UnsavedChanged", self:IsUnsaved ())
end

function self:MarkUnsaved ()
	if self:IsUnsaved () then return end
	self.SavePoint = ""
	
	self:DispatchEvent ("CanSaveChanged", self:CanSave ())
	self:DispatchEvent ("UnsavedChanged", self:IsUnsaved ())
end

function self:Reload ()
	if not self:GetFile () then return end
	
	self:GetFile ():Open (GLib.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then return end
			
			self:DispatchEvent ("Reloading")
			
			self:Clear ()
			self.UndoRedoStack:Clear ()
			
			self:LoadFromStream (fileStream,
				function ()
					fileStream:Close ()
					self:MarkSaved ()
					self:DispatchEvent ("Reloaded")
				end
			)
		end
	)
end

function self:Save (callback)
	callback = callback or GCompute.NullCallback
	
	if not self:GetFile () then
		if not self:GetPath () then callback (false) return end
		VFS.Root:CreateFile (GAuth.GetLocalId (), self:GetPath (),
			function (returnCode, file)
				if returnCode ~= VFS.ReturnCode.Success then callback (false) return end
				if not file then callback (false) return end
				self:SetFile (file)
				self:Save (callback)
			end
		)
		return
	end
	
	self:DispatchEvent ("Saving")
	
	self:GetFile ():Open (GAuth.GetLocalId (), VFS.OpenFlags.Write + VFS.OpenFlags.Overwrite,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then
				self:DispatchEvent ("Saved")
				callback (false)
				return
			end
			
			self:SaveToStream (fileStream,
				function ()
					fileStream:Close ()
					self:MarkSaved ()
					self:DispatchEvent ("Saved")
					callback (true)
				end
			)
		end
	)
end

function self:SaveToStream (fileStream, callback)
	callback = callback or GCompute.NullCallback ()
	callback ()
end

-- Views
function self:AddView (view)
	if self.ViewSet [view] then return end
	
	self.Views [#self.Views + 1] = view
	self.ViewSet [view] = true
	
	self:DispatchEvent ("ViewAdded", view)
end

function self:GetView (viewIndex)
	return self.Views [viewIndex]
end

function self:GetViewCount ()
	return #self.Views
end

function self:RemoveView (view)
	if not self.ViewSet [view] then return end
	
	for k, v in ipairs (self.Views) do
		if v == view then
			table.remove (self.Views, k)
			break
		end
	end
	self.ViewSet [view] = nil
	
	self:DispatchEvent ("ViewRemoved", view)
end
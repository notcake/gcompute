local self = {}
GCompute.IDE.Document = GCompute.MakeConstructor (self, GCompute.ISavable)

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
function self:LoadSession (inBuffer, serializerRegistry)
	local serializerType = serializerRegistry:FindSerializerForDocument (self:GetType ())
	serializerType = serializerType or serializerRegistry:GetType ("Code")
	local serializer = serializerType:Create (self)
	
	local hasPath = inBuffer:Boolean ()
	if hasPath then
		local path = inBuffer:String ()
		VFS.Root:OpenFile (GLib.GetLocalId (), path, VFS.OpenFlags.Read,
			function (returnCode, fileStream)
				if returnCode ~= VFS.ReturnCode.Success then
					self:SetPath (path)
					return
				end
				
				self:SetFile (fileStream:GetFile ())
				
				fileStream:Read (fileStream:GetLength (),
					function (returnCode, data)
						if returnCode == VFS.ReturnCode.Progress then return end
						
						fileStream:Close ()
						serializer:Deserialize (GLib.StringInBuffer (data))
					end
				)
			end
		)
	else
		if inBuffer:Boolean () then
			self:MarkUnsaved ()
		end
		local subInBuffer = GLib.StringInBuffer (inBuffer:LongString ())
		serializer:Deserialize (subInBuffer)
	end
	self:LoadSessionMetadata (inBuffer)
end

function self:LoadSessionMetadata (inBuffer)
end

function self:SaveSession (outBuffer, serializerRegistry)
	local serializerType = serializerRegistry:FindSerializerForDocument (self:GetType ())
	serializerType = serializerType or serializerRegistry:GetType ("Code")
	local serializer = serializerType:Create (self)
	
	outBuffer:Boolean (self:HasPath ())
	if self:HasPath () then
		outBuffer:String (self:GetPath ())
	else
		outBuffer:Boolean (self:IsUnsaved ())
		
		local subOutBuffer = GLib.StringOutBuffer ()
		serializer:Serialize (subOutBuffer)
		outBuffer:LongString (subOutBuffer:GetString ())
	end
	self:SaveSessionMetadata (outBuffer)
end

function self:SaveSessionMetadata (outBuffer)
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
	
	local serializerType = serializerRegistry:FindSerializerForDocument (self:GetType ())
	serializerType = serializerType or serializerRegistry:GetType ("Code")
	local serializer = serializerType:Create (self)
	
	self:GetFile ():Open (GLib.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then return end
			
			self:DispatchEvent ("Reloading")
			
			self:Clear ()
			self.UndoRedoStack:Clear ()
			
			fileStream:Read (fileStream:GetLength (),
				function (returnCode, data)
					if returnCode == VFS.ReturnCode.Progress then return end
					
					fileStream:Close ()
					serializer:Deserialize (GLib.StringInBuffer (data),
						function ()
							self:MarkSaved ()
							self:DispatchEvent ("Reloaded")
						end
					)
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
				if returnCode ~= VFS.ReturnCode.Success or
				   not file then
					self:DispatchEvent ("SaveFailed")
					callback (false)
					return
				end
				
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
				self:DispatchEvent ("SaveFailed")
				callback (false)
				return
			end
			
			local serializerType = serializerRegistry:FindSerializerForDocument (self:GetType ())
			serializerType = serializerType or serializerRegistry:GetType ("Code")
			local serializer = serializerType:Create (self)
			local outBuffer = GLib.StringOutBuffer ()
			serializer:Serialize (outBuffer,
				function ()
					fileStream:Write (outBuffer:GetSize (), outBuffer:GetString (),
						function (returnCode)
							fileStream:Close ()
							self:MarkSaved ()
							self:DispatchEvent ("Saved")
							callback (true)
						end
					)
				end
			)
		end
	)
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
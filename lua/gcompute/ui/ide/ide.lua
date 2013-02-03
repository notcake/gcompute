local self = {}
GCompute.IDE.IDE = GCompute.MakeConstructor (self)

function self:ctor ()
	self.DocumentTypes      = GCompute.IDE.DocumentTypes
	self.ViewTypes          = GCompute.IDE.ViewTypes
	self.SerializerRegistry = GCompute.IDE.SerializerRegistry
	
	self.DocumentManager    = GCompute.IDE.DocumentManager ()
	self.ViewManager        = GCompute.IDE.ViewManager ()
	
	self.DocumentManager:SetIDE (self)
	self.DocumentManager:SetDocumentTypes (self.DocumentTypes)
	self.ViewManager:SetIDE (self)
	self.ViewManager:SetViewTypes (self.ViewTypes)
	
	self.ViewManager:AddEventListener ("ViewAdded",
		function (_, view)
			self:HookView (view)
			self:RegisterDocument (view:GetDocument ())
		end
	)
	
	self.ViewManager:AddEventListener ("ViewRemoved",
		function (_, view)
			self:UnhookView (view)
			view:dtor ()
		end
	)
	
	self.Panel = nil
end

function self:dtor ()
	if self.Panel and self.Panel:IsValid () then
		self.Panel:Remove ()
	end
end

-- IDE
function self:GetDocumentManager ()
	return self.DocumentManager
end

function self:GetDocumentTypes ()
	return self.DocumentTypes
end

function self:GetFrame ()
	if not self.Panel then
		self.Panel = vgui.Create ("GComputeIDEFrame")
		self.Panel:SetIDE (self)
		self.Panel:LoadWorkspace ()
	end
	return self.Panel
end

function self:GetSerializerRegistry ()
	return self.SerializerRegistry
end

function self:GetViewManager ()
	return self.ViewManager
end

function self:GetViewTypes ()
	return self.ViewTypes
end

function self:SetVisible (visible)
	self:GetFrame ():SetVisible (visible)
end

-- Opening
--- Opens a new tab for the IFile. Use OpenPath instead if you have a path only.
-- @param file The IFile to be opened.
-- @param callback A callback function (success, IFile file, IView view)
function self:OpenFile (file, callback)
	if not file then return end
	
	local document = self:GetDocumentManager ():GetDocumentByPath (file:GetPath ())
	if document then
		callback (true, file, document:GetView (1))
		return
	end
	
	local extension = file:GetExtension () or ""
	extension = string.lower (extension)
	
	local serializerType = self:GetSerializerRegistry ():FindDeserializerForExtension (extension)
	serializerType = serializerType or self:GetSerializerRegistry ():GetType ("Code")
	
	local documentType   = serializerType and self:GetDocumentTypes ():GetType (serializerType:GetDocumentType ())
	local viewType       = documentType and documentType:GetViewType ()
	
	file:Open (GLib.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then
				callback (false, file)
				return
			end
			
			fileStream:Read (fileStream:GetLength (),
				function (returnCode, data)
					if returnCode == VFS.ReturnCode.Progress then return end
					
					fileStream:Close ()
					
					local document = documentType:Create ()
					local serializer = serializerType:Create (document)
					
					local view = self:CreateView (viewType)
					view:SetTitle (file:GetDisplayName ())
					serializer:Deserialize (GLib.StringInBuffer (data))
					view:SetDocument (document)
					view:GetSavable ():SetFile (file)
					
					callback (true, file, view)
				end
			)
		end
	)
	print (serializerType, documentType, viewType)
end

--- Opens a new tab for the given path. Use OpenFile instead if you have an IFile.
-- @param path The path of the file to be opened
-- @param callback A callback function (success, IFile file, IView view)
function self:OpenPath (path, callback)
	callback = callback or GCompute.NullCallback
	
	local document = self:GetDocumentManager ():GetDocumentByPath (path)
	if document then
		callback (true, document:GetFile (), document:GetView (1))
		return
	end
	
	VFS.Root:GetChild (GAuth.GetLocalId (), path,
		function (returnCode, file)
			if not self:GetFrame ():IsValid () then return end
			if not file then callback (false) return end
			self:OpenFile (file, callback)
		end
	)
end

-- Documents
--- Prompts for a file to which to save, then saves a document's contents.
-- @param document The document whose contents are to be saved
-- @param callback A callback function (success, IFile file)
function self:SaveAsDocument (document, callback)
	callback = callback or GCompute.NullCallback
	if not document then callback (true) return end
	
	VFS.OpenSaveFileDialog ("GCompute.IDE",
		function (path, file)
			if not path then callback (false) return end
			if not self:GetFrame ():IsValid () then callback (false) return end
			
			document:SetPath (path)
			self:SaveDocument (document, path, callback)
		end
	)
end

--- Saves a document's contents.
-- @param document The document whose contents are to be saved
-- @param pathOrCallback Optional path to which to save
-- @param callback A callback function (success, IFile file)
function self:SaveDocument (document, pathOrCallback, callback)
	if type (pathOrCallback) == "function" then
		callback = pathOrCallback
		pathOrCallback = nil
	end
	callback = callback or GCompute.NullCallback
	
	if not document then callback (true) return end
	
	-- Determine save path
	local path = pathOrCallback
	if not path and document:HasPath () then
		path = document:GetPath ()
		document:SetPath (path)
	end
	
	-- If the document has no path, invoke the save as dialog.
	if not path then
		self:SaveAsDocument (document, callback)
		return
	end
	
	document:Save (callback, self:GetSerializerRegistry ())
end

-- Views
--- Returns false if the view is the last remaining document view and contains the unchanged default text
function self:CanCloseView (view)
	if not view then return true end
	
	-- No special checks for views that do not host documents
	if not view:GetDocument () then
		return view:CanClose ()
	end
	
	if self:GetDocumentManager ():GetDocumentCount () == 1 and
	   view:GetDocument ():GetViewCount () == 1 and
	   view:GetType () == "Code" and
	   not view:GetSavable ():HasPath () and
	   not view:GetSavable ():IsUnsaved () then
		return false
	end
	
	return view:CanClose ()
end

--- Closes a view
-- @param callback function (success)
function self:CloseView (view, callback)
	callback = callback or GCompute.NullCallback
	
	if not view             then callback (true)  return end
	if not view:CanClose () then callback (false) return end

	-- Don't close the last tab if it contains the default text
	if not self:CanCloseView (view) then
		callback (false)
		return
	end
	
	if view:GetSavable () and view:GetSavable ():IsUnsaved () and view:GetDocument ():GetViewCount () <= 1 then
		Gooey.YesNoDialog ()
			:SetTitle ("Save")
			:SetText ("Save \"" .. view:GetTitle () .. "\"?")
			:SetCallback (
				function (result)
					if result == "Yes" then
						self:SaveView (view,
							function (saved)
								if saved then
									self:CloseView (view, callback)
								else
									callback (false)
								end
							end
						)
					elseif result == "No" then
						view:dtor ()
						callback (true)
					else
						callback (false)
					end
				end
			)
	else
		view:dtor ()
		callback (true)
	end
end

function self:CreateView (viewType, viewId)
	return self:GetViewManager ():CreateView (viewType, viewId)
end

--- Prompts for a file to which to save, then saves a view's contents.
-- @param view The view whose contents are to be saved
-- @param callback A callback function (success, IFile file)
function self:SaveAsView (view, callback)
	callback = callback or GCompute.NullCallback
	if not view               then callback (true) return end
	if not view:GetSavable () then callback (true) return end
	
	self:SaveAsDocument (view:GetSavable ())
end

--- Saves a view's contents.
-- @param view The view whose contents are to be saved
-- @param pathOrCallback Optional path to which to save
-- @param callback A callback function (success, IFile file)
function self:SaveView (view, pathOrCallback, callback)
	if type (pathOrCallback) == "function" then
		callback = pathOrCallback
		pathOrCallback = nil
	end
	callback = callback or GCompute.NullCallback
	
	if not view               then callback (true) return end
	if not view:GetSavable () then callback (true) return end
	
	local path = pathOrCallback
	self:SaveDocument (view:GetSavable (), pathOrCallback, callback)
end

-- Internal, do not call
function self:RegisterDocument (document)
	if not document then return end
	
	self:GetDocumentManager ():AddDocument (document)
	self:HookDocument (document)
end

function self:UnregisterDocument (document)
	if not document then return end
	
	self:GetDocumentManager ():RemoveDocument (document)
	self:UnhookDocument (document)
end

function self:HookDocument (document)
	if not document then return end
	
	document:AddEventListener ("ViewRemoved", tostring (self),
		function (_)
			if document:GetViewCount () == 0 then
				self:UnregisterDocument (document)
			end
		end
	)
end

function self:UnhookDocument (document)
	if not document then return end
	
	document:RemoveEventListener ("ViewRemoved", tostring (self))
end

function self:HookView (view)
	if not view then return end
	
	view:AddEventListener ("DocumentChanged", tostring (self),
		function (_, oldDocument, newDocument)
			-- Do not unregister the old document, this will occur on
			-- Document:ViewRemoved if the document no longer has any views
			if oldDocument then
				oldDocument:RemoveView (view)
			end
			
			self:RegisterDocument (newDocument)
			newDocument:AddView (view)
		end
	)
end

function self:UnhookView (view)
	if not view then return end
	
	view:RemoveEventListener ("DocumentChanged", tostring (self))
end

concommand.Add ("gcompute_show_ide",
	function ()
		GCompute.IDE.GetInstance ():SetVisible (true)
	end
)
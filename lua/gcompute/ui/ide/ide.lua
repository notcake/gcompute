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
	
	self.DocumentManager:AddEventListener ("DocumentRemoved",
		function (_, document)
			document:dtor ()
		end
	)
	
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
--- Opens a new tab for the IFile. Use OpenUri instead if you have a URI only.
-- @param file The IFile to be opened.
-- @param callback A callback function (success, IResource resource, IView view)
function self:OpenFile (file, callback)
	self:OpenResource (VFS.Resource (file), callback)
end

--- Opens a new tab for the IResource. Use OpenUri instead if you have a URI only.
-- @param resource The IResource to be opened.
-- @param callback A callback function (success, IResource resource, IView view)
function self:OpenResource (resource, callback)
	if not resource then return end
	
	local document = self:GetDocumentManager ():GetDocumentByUri (resource:GetUri ())
	if document then
		callback (true, resource, document:GetView (1))
		return
	end
	
	local extension = resource:GetExtension () or ""
	extension = string.lower (extension)
	
	local serializerType = self:GetSerializerRegistry ():FindDeserializerForExtension (extension)
	serializerType = serializerType or self:GetSerializerRegistry ():GetType ("Code")
	
	local documentType   = serializerType and self:GetDocumentTypes ():GetType (serializerType:GetDocumentType ())
	local viewType       = documentType and documentType:GetViewType ()
	
	resource:Open (GLib.GetLocalId (), VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then
				callback (false, resource)
				return
			end
			
			fileStream:Read (fileStream:GetLength (),
				function (returnCode, data)
					if returnCode == VFS.ReturnCode.Progress then return end
					
					fileStream:Close ()
					
					local document = documentType:Create ()
					local serializer = serializerType:Create (document)
					
					local view = self:CreateView (viewType)
					view:SetTitle (resource:GetDisplayName ())
					
					-- TODO: Handle asynchronous serializers
					serializer:Deserialize (GLib.StringInBuffer (data), nil, resource)
					view:SetDocument (document)
					view:GetSavable ():SetResource (resource)
					
					callback (true, resource, view)
				end
			)
		end
	)
end

--- Opens a new tab for the given uri. Use OpenResource instead if you have an IResource.
-- @param uri The uri of the file to be opened
-- @param callback A callback function (success, IResource resource, IView view)
function self:OpenUri (uri, callback)
	callback = callback or GCompute.NullCallback
	
	local document = self:GetDocumentManager ():GetDocumentByUri (uri)
	if document then
		callback (true, document:GetResource (), document:GetView (1))
		return
	end
	
	self:OpenResource (VFS.Resource (uri), callback)
end

-- Documents
--- Prompts for a uri to which to save, then saves a document's contents.
-- @param document The document whose contents are to be saved
-- @param callback A callback function (success, IResource resource)
function self:SaveAsDocument (document, callback)
	callback = callback or GCompute.NullCallback
	if not document then callback (true) return end
	
	VFS.OpenSaveFileDialog ("GCompute.IDE",
		function (uri, resource)
			if not uri then callback (false) return end
			if not self:GetFrame ():IsValid () then callback (false) return end
			
			document:SetUri (uri)
			self:SaveDocument (document, uri, callback)
		end
	)
end

--- Saves a document's contents.
-- @param document The document whose contents are to be saved
-- @param uriOrCallback Optional uri to which to save
-- @param callback A callback function (success, IResource resource)
function self:SaveDocument (document, uriOrCallback, callback)
	if type (uriOrCallback) == "function" then
		callback = uriOrCallback
		uriOrCallback = nil
	end
	callback = callback or GCompute.NullCallback
	
	if not document then callback (true) return end
	
	-- Determine save uri
	local uri = uriOrCallback
	if not uri and document:HasUri () then
		uri = document:GetUri ()
	end
	
	-- If the document has no uri, invoke the save as dialog.
	if not uri then
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
	   not view:GetSavable ():HasUri () and
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
	if not view:CanClose () then
		if view:CanHide () then
			view:SetVisible (false)
		end
		callback (false)
		return
	end

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
-- @param uriOrCallback Optional uri to which to save
-- @param callback A callback function (success, IResource resource)
function self:SaveView (view, uriOrCallback, callback)
	if type (uriOrCallback) == "function" then
		callback = uriOrCallback
		uriOrCallback = nil
	end
	callback = callback or GCompute.NullCallback
	
	if not view               then callback (true) return end
	if not view:GetSavable () then callback (true) return end
	
	self:SaveDocument (view:GetSavable (), uriOrCallback, callback)
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
			
			if newDocument then
				newDocument:AddView (view)
			end
		end
	)
	
	if view:GetSavable () then
		view:GetSavable ():AddEventListener ("ResourceChanged", tostring (self),
			function (_, oldResource, resource)
				view:SetTitle (resource and resource:GetDisplayName () or view:GetSavable ():GetUri ())
				view:SetToolTipText (resource and resource:GetDisplayUri () or nil)
			end
		)
	end
end

function self:UnhookView (view)
	if not view then return end
	
	view:RemoveEventListener ("DocumentChanged", tostring (self))
	
	if view:GetSavable () then
		view:GetSavable ():RemoveEventListener ("FileChanged", tostring (self))
	end
end

concommand.Add ("gcompute_show_ide",
	function ()
		GCompute.IDE.GetInstance ():SetVisible (true)
	end
)
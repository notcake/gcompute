local self = {}
GCompute.IDE.IDE = GCompute.MakeConstructor (self)

function self:ctor ()
	self.DocumentTypes   = GCompute.IDE.DocumentTypes
	self.ViewTypes       = GCompute.IDE.ViewTypes
	
	self.DocumentManager = GCompute.IDE.DocumentManager ()
	self.ViewManager     = GCompute.IDE.ViewManager ()
	
	self.DocumentManager:SetIDE (self)
	self.DocumentManager:SetDocumentTypes (self.DocumentTypes)
	self.ViewManager:SetIDE (self)
	self.ViewManager:SetViewTypes (self.ViewTypes)
	
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

function self:GetViewManager ()
	return self.ViewManager
end

function self:GetFrame ()
	if not self.Panel then
		self.Panel = vgui.Create ("GComputeIDEFrame")
		self.Panel:SetIDE (self)
		self.Panel:LoadWorkspace ()
	end
	return self.Panel
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
	
	local imageExtensions =
	{
		["bmp"] = true,
		["gif"] = true,
		["jpg"] = true,
		["png"] = true
	}
	
	if imageExtensions [extension] then
		local view = self:CreateView ("Image")
		view:SetTitle (file:GetDisplayName ())
		view:SetFile (file)
		self.DockContainer:GetLargestContainer ():AddView (view)
		
		callback (true, file, view)
	else
		file:Open (GLib.GetLocalId (), VFS.OpenFlags.Read,
			function (returnCode, fileStream)
				if returnCode == VFS.ReturnCode.Success then
					fileStream:Read (fileStream:GetLength (),
						function (returnCode, data)
							if returnCode == VFS.ReturnCode.Progress then return end
							
							local file = fileStream:GetFile ()
							local view = self:CreateCodeView ()
							view:SetTitle (file:GetDisplayName ())
							view:SetCode (data)
							view:GetSavable ():SetFile (file)
							fileStream:Close ()
							
							callback (true, file, view)
						end
					)
				else
					callback (false, file)
				end
			end
		)
	end
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
	
	VFS.OpenSaveFileDialog ("GCompute.IDE",
		function (path, file)
			if not path then callback (false) return end
			if not self:GetFrame ():IsValid () then callback (false) return end
			
			view:GetSavable ():SetPath (path)
			self:SaveView (view, path, callback)
		end
	)
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
	
	-- Determine save path
	local path = pathOrCallback
	if not path and view:GetSavable ():HasPath () then
		path = view:GetSavable ():GetPath ()
		view:GetSavable ():SetPath (path)
	end
	
	-- If the view has no path, invoke the save as dialog.
	if not path then
		self:SaveAsView (view, callback)
		return
	end
	
	view:GetSavable ():Save (callback)
end

concommand.Add ("gcompute_show_ide",
	function ()
		GCompute.IDE.GetInstance ():SetVisible (true)
	end
)
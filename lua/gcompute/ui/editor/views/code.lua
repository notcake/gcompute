local self = GCompute.Editor.ViewTypes:CreateType ("Code")

function self:ctor (container)
	self.CodeEditor = vgui.Create ("GComputeCodeEditor", container)
	self.CodeEditor:GetDocument ():AddView (self)
	
	self.ClipboardTarget = GCompute.Editor.EditorClipboardTarget (self.CodeEditor)
	
	self.SavableProxy = GCompute.SavableProxy (self:GetDocument ())
	self.UndoRedoStackProxy = GCompute.UndoRedoStackProxy (self:GetDocument ():GetUndoRedoStack ())
	
	self:GetSavable ():AddEventListener ("FileChanged",
		function (_, oldFile, file)
			self:SetTitle (file and file:GetDisplayName () or self:GetSavable ():GetPath ())
			self:SetToolTipText (file and file:GetDisplayPath () or nil)
		end
	)
	self:GetSavable ():AddEventListener ("UnsavedChanged",
		function (_, unsaved)
			self:SetIcon (unsaved and "icon16/page_red.png" or "icon16/page.png")
		end
	)
	
	self.CodeEditor:AddEventListener ("DocumentChanged",
		function (_, oldDocument, document)
			if oldDocument then
				oldDocument:RemoveView (self)
			end
			if document then
				document:AddView (self)
			end
			self.SavableProxy:SetSavable (document)
			self.UndoRedoStackProxy:SetUndoRedoStack (document and document:GetUndoRedoStack () or nil)
			self:DispatchEvent ("DocumentChanged", oldDocument, document)
		end
	)
	
	self:SetIcon ("icon16/page.png")
end

function self:GetCode ()
	return self.CodeEditor:GetText ()
end

function self:GetEditor ()
	return self.CodeEditor
end

function self:SetCode (code)
	self.CodeEditor:SetText (code)
end

-- Components
function self:GetClipboardTarget ()
	return self.ClipboardTarget
end

function self:GetDocument ()
	return self.CodeEditor:GetDocument ()
end

function self:GetSavable ()
	return self.SavableProxy
end

function self:GetUndoRedoStack ()
	return self.UndoRedoStackProxy
end

-- Persistance
function self:LoadSession (inBuffer)
	local saveMode = inBuffer:UInt8 ()
	if saveMode == 0 then
		local path = inBuffer:String ()
		VFS.Root:OpenFile (GAuth.GetLocalId (), path, VFS.OpenFlags.Read,
			function (returnCode, fileStream)
				if returnCode ~= VFS.ReturnCode.Success then
					self:SetTitle (path)
					self:GetSavable ():SetPath (path)
					return
				end
				self:GetSavable ():SetFile (fileStream:GetFile ())
				fileStream:Read (fileStream:GetLength (),
					function (returnCode, data)
						if returnCode == VFS.ReturnCode.Progress then return end
						fileStream:Close ()
						
						self:SetCode (data)
					end
				)
			end
		)
	else
		self:SetTitle (inBuffer:String ())
		if inBuffer:Boolean () then
			self:GetDocument ():MarkUnsaved ()
		end
		self:SetCode (inBuffer:String ())
	end
end

function self:SaveSession (outBuffer)
	if self:GetSavable ():GetPath () then
		outBuffer:UInt8 (0)
		outBuffer:String (self:GetSavable ():GetPath () or "")
	else
		outBuffer:UInt8 (1)
		outBuffer:String (self:GetTitle ())
		outBuffer:Boolean (self:GetSavable ():IsUnsaved ())
		outBuffer:String (self:GetCode ())
	end
end
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

function self:dtor ()
	self:GetDocument ():RemoveView (self)
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

function self:SetDocument (document)
	if not document then
		GCompute.Error ("Code:SetDocument : document is nil!")
	end
	self.CodeEditor:SetDocument (document)
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
	local title = inBuffer:String ()
	
	local document = self:GetDocumentManager ():GetDocumentById (inBuffer:String ())
	if document then
		self:GetEditor ():SetDocument (document)
	end
	self:SetTitle (title)
end

function self:SaveSession (outBuffer)
	outBuffer:String (self:GetTitle ())
	outBuffer:String (self:GetDocument () and self:GetDocument ():GetId () or "")
end
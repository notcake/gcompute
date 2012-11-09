local self = {}
GCompute.Editor.EditorClipboardTarget = GCompute.MakeConstructor (self, Gooey.IClipboardTarget)

function self:ctor (codeEditor)
	self.CodeEditor = codeEditor
	
	self.CodeEditor:AddEventListener ("SelectionChanged", tostring (self),
		function ()
			self:DispatchEvent ("CanCopyChanged", self:CanCopy ())
		end
	)
end

function self:CanCopy ()
	return not self.CodeEditor:GetSelection ():IsEmpty ()
end

function self:CanPaste ()
	return true
end

function self:Copy ()
	self.CodeEditor:CopySelection ()
end

function self:Cut ()
	self.CodeEditor:CutSelection ()
end

function self:Paste ()
	self.CodeEditor:Paste ()
end
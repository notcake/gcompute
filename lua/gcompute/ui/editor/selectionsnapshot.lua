local self = {}
GCompute.Editor.SelectionSnapshot = GCompute.MakeConstructor (self)

function self:ctor ()
	self.SelectionMode	        = GCompute.Editor.SelectionMode.Regular
	self.SelectionStart         = GCompute.Editor.LineColumnLocation ()
	self.SelectionEnd           = GCompute.Editor.LineColumnLocation ()
	self.CaretPosition          = GCompute.Editor.LineColumnLocation ()
	self.PreferredCaretPosition = GCompute.Editor.LineColumnLocation ()
end

function self:GetCaretPosition ()
	return self.CaretPosition
end

function self:GetPreferredCaretPosition ()
	return self.PreferredCaretPosition
end

function self:GetSelectionMode ()
	return self.SelectionMode
end

function self:GetSelectionEnd ()
	return self.SelectionEnd
end

function self:GetSelectionMode ()
	return self.SelectionMode
end

function self:GetSelectionStart ()
	return self.SelectionStart
end

function self:SetCaretPosition (caretPosition)
	self.CaretPosition:CopyFrom (caretPosition)
end

function self:SetPreferredCaretPosition (preferredCaretPosition)
	self.PreferredCaretPosition:CopyFrom (preferredCaretPosition)
end

function self:SetSelectionEnd (selectionEnd)
	self.SelectionEnd:CopyFrom (selectionEnd)
end

function self:SetSelectionMode (selectionMode)
	self.SelectionMode = selectionMode
end

function self:SetSelectionStart (selectionStart)
	self.SelectionStart:CopyFrom (selectionStart)
end
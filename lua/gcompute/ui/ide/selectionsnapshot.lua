local self = {}
GCompute.IDE.SelectionSnapshot = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Selection              = GCompute.IDE.TextSelection ()
	self.CaretPosition          = GCompute.IDE.LineColumnLocation ()
	self.PreferredCaretPosition = GCompute.IDE.LineColumnLocation ()
end

function self:GetCaretPosition ()
	return self.CaretPosition
end

function self:GetPreferredCaretPosition ()
	return self.PreferredCaretPosition
end

function self:GetSelection ()
	return self.Selection
end

function self:GetSelectionEnd ()
	return self.Selection:GetSelectionEnd ()
end

function self:GetSelectionEndPoints ()
	return self.Selection:GetSelectionEndPoints ()
end

function self:GetSelectionEnumerator ()
	return self.Selection:GetSpanEnumerator ()
end

function self:GetSelectionLineSpan ()
	return self.Selection:GetLineSpan ()
end

function self:GetSelectionMode ()
	return self.Selection:GetSelectionMode ()
end

function self:GetSelectionStart ()
	return self.Selection:GetSelectionStart ()
end

function self:SetCaretPosition (caretPosition)
	self.CaretPosition:CopyFrom (caretPosition)
end

function self:SetPreferredCaretPosition (preferredCaretPosition)
	self.PreferredCaretPosition:CopyFrom (preferredCaretPosition)
end
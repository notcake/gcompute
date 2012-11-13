local self = GCompute.Editor.ViewTypes:CreateType ("Output")

function self:ctor (container)
	self:SetTitle ("Output")
	self:SetIcon ("icon16/application_xp_terminal.png")
	
	self.CodeEditor = vgui.Create ("GComputeCodeEditor", container)
	self.CodeEditor:GetDocument ():AddView (self)
	self.CodeEditor:SetCompilationEnabled (false)
	self.CodeEditor:SetLineNumbersVisible (false)
	self.CodeEditor:SetReadOnly (true)
	
	self.ClipboardTarget = GCompute.Editor.EditorClipboardTarget (self.CodeEditor)
end

function self:Append (text, color)
	local startPos = self:GetEditor ():GetDocument ():GetEnd ()
	self:GetEditor ():Append (text)
	if color then
		self:GetEditor ():GetDocument ():SetColor (color, startPos, self:GetEditor ():GetDocument ():GetEnd ())
	end
end

function self:Clear ()
	self:GetEditor ():Clear ()
end

function self:GetEditor ()
	return self.CodeEditor
end

-- Components
function self:GetClipboardTarget ()
	return self.ClipboardTarget
end
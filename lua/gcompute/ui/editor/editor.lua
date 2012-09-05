GCompute.Editor.CodeEditorKeyboardMap = Gooey.KeyboardMap ()
GCompute.Editor.EditorKeyboardMap = Gooey.KeyboardMap ()

GCompute:AddEventListener ("Unloaded", function ()
	if GCompute.Editor.Panel and GCompute.Editor.Panel:IsValid () then
		GCompute.Editor.Panel:Remove ()
	end
end)

function GCompute.Editor:GetFrame ()
	if not self.Panel then
		self.Panel = vgui.Create ("GComputeEditorFrame")
	end
	return self.Panel
end

concommand.Add ("gcompute_show_editor", function ()
	GCompute.Editor:GetFrame ():SetVisible (true)
end)
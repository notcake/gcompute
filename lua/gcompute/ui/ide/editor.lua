GCompute.IDE.CodeEditorKeyboardMap = Gooey.KeyboardMap ()
GCompute.IDE.EditorKeyboardMap = Gooey.KeyboardMap ()

GCompute:AddEventListener ("Unloaded", function ()
	if GCompute.IDE.Panel and GCompute.IDE.Panel:IsValid () then
		GCompute.IDE.Panel:Remove ()
	end
end)

function GCompute.IDE:GetFrame ()
	if not self.Panel then
		self.Panel = vgui.Create ("GComputeEditorFrame")
	end
	return self.Panel
end

concommand.Add ("gcompute_show_editor", function ()
	GCompute.IDE:GetFrame ():SetVisible (true)
end)
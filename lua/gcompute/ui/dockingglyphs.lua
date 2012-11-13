local function DrawDockButton (image, renderContext, color, x, y, w, h)
	draw.RoundedBox (8, x - w * 0.5, y - w * 0.5, w, h, color)
	renderContext:PushRelativeViewPort (x - w * 0.5, y - h * 0.5)
	
	Gooey.ImageCache:GetImage (image):Draw (renderContext, 0, 0)
	
	renderContext:PopViewPort ()
end

Gooey.Glyphs.Register ("DockContainer.DockMiddle",
	function (renderContext, color, x, y, w, h)
		DrawDockButton ("gui/dockicons/dockmiddle.png", renderContext, color, x, y, w, h)
	end
)

Gooey.Glyphs.Register ("DockContainer.DockTop",
	function (renderContext, color, x, y, w, h)
		DrawDockButton ("gui/dockicons/docktop.png", renderContext, color, x, y, w, h)
	end
)

Gooey.Glyphs.Register ("DockContainer.DockBottom",
	function (renderContext, color, x, y, w, h)
		DrawDockButton ("gui/dockicons/dockbottom.png", renderContext, color, x, y, w, h)
	end
)

Gooey.Glyphs.Register ("DockContainer.DockLeft",
	function (renderContext, color, x, y, w, h)
		DrawDockButton ("gui/dockicons/dockleft.png", renderContext, color, x, y, w, h)
	end
)

Gooey.Glyphs.Register ("DockContainer.DockRight",
	function (renderContext, color, x, y, w, h)
		DrawDockButton ("gui/dockicons/dockright.png", renderContext, color, x, y, w, h)
	end
)
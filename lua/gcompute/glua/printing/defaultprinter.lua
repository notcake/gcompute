GCompute.GLua.Printing.DefaultPrinter = GCompute.GLua.Printing.Printer ()
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("default",     GCompute.GLua.Printing.DefaultTypePrinter)

-- Standard lua types
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("nil",         GCompute.GLua.Printing.NilPrinter        )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("boolean",     GCompute.GLua.Printing.BooleanPrinter    )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("number",      GCompute.GLua.Printing.NumberPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("string",      GCompute.GLua.Printing.StringPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("function",    GCompute.GLua.Printing.FunctionPrinter   )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("table",       GCompute.GLua.Printing.TablePrinter      )

GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Color",       GCompute.GLua.Printing.ColorPrinter      )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Angle",       GCompute.GLua.Printing.AnglePrinter      )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Vector",      GCompute.GLua.Printing.VectorPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("VMatrix",     GCompute.GLua.Printing.VMatrixPrinter    )

-- Entities
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Entity",      GCompute.GLua.Printing.EntityPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("CSEnt",       GCompute.GLua.Printing.EntityPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Vehicle",     GCompute.GLua.Printing.EntityPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Weapon",      GCompute.GLua.Printing.EntityPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("NPC",         GCompute.GLua.Printing.EntityPrinter     )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Player",      GCompute.GLua.Printing.PlayerPrinter     )

-- UI
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("Panel",       GCompute.GLua.Printing.PanelPrinter      )

-- Audio
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("CSoundPatch", GCompute.GLua.Printing.SoundPatchPrinter )

-- Graphics
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("IMaterial",   GCompute.GLua.Printing.MaterialPrinter   )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("IMesh",       GCompute.GLua.Printing.MeshPrinter       )
GCompute.GLua.Printing.DefaultPrinter:RegisterTypePrinter ("ITexture",    GCompute.GLua.Printing.TexturePrinter    )

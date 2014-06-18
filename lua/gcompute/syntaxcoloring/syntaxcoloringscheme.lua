local self = {}
GCompute.SyntaxColoring.SyntaxColoringScheme = GCompute.MakeConstructor (self, GCompute.ColorScheme)

function self:ctor ()
	self:Initialize ()
end

function self:Initialize ()
	self:SetColor ("Default",            GLib.Colors.White       )
	self:SetColor ("Operator",           GLib.Colors.Operator    )
	self:SetColor ("String",             GLib.Colors.Gray        )
	self:SetColor ("Number",             GLib.Colors.SandyBrown  )
	self:SetColor ("Comment",            GLib.Colors.ForestGreen )
	self:SetColor ("Keyword",            GLib.Colors.RoyalBlue   )
	self:SetColor ("Preprocessor",       GLib.Colors.Yellow      )
	self:SetColor ("Identifier",         GLib.Colors.LightSkyBlue)
	self:SetColor ("ResolvedIdentifier", GLib.Colors.SkyBlue     )
	self:SetColor ("Unknown",            GLib.Colors.Tomato      )
end

function self:GetTokenColor (tokenType)
	return self [GCompute.Lexing.TokenType [tokenType]] or self.Default
end

function self:__call ()
	return self:Clone (GCompute.SyntaxColoring.SyntaxColoringScheme ())
end

GCompute.SyntaxColoring.DefaultSyntaxColoringScheme = GCompute.SyntaxColoring.SyntaxColoringScheme ()
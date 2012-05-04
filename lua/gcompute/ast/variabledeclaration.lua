local VariableDeclaration = {}
VariableDeclaration.__Type = "VariableDeclaration"
GCompute.AST.VariableDeclaration = GCompute.AST.MakeConstructor (VariableDeclaration)

function VariableDeclaration:ctor ()
	self.Type = nil
	self.Name = "[unknown]"
	self.Value = nil
end

function VariableDeclaration:ToString ()
	if not self.Type then
		return "[unknown] " .. self.Name
	end
	if not self.Value then
		return self.Type:ToString () .. " " .. self.Name
	end
	return self.Type:ToString () .. " " .. self.Name .. " = " .. self.Value:ToString ()
end
local self = {}
GCompute.GLua.Printing.NullAlignmentController = GCompute.MakeConstructor (self, GCompute.GLua.Printing.AlignmentController)

function self:ctor ()
end

function self:AddAlignment (name, n)
end

function self:GetAlignment (name)
	return 0
end

function self:__call ()
	return self.__ictor ()
end

GCompute.GLua.Printing.NullAlignmentController = GCompute.GLua.Printing.NullAlignmentController ()
local self = {}
GCompute.NullOutputBuffer = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Clear ()
end

function self:DecreaseIndent ()
end

function self:Disable ()
end

function self:Enable ()
end

function self:IncreaseIndent ()
end

function self:OutputLines (outputFunction)
end

function self:Write (message)
end

function self:WriteLine (message)
end

GCompute.NullOutputBuffer = GCompute.NullOutputBuffer ()

abstract type Agent end

struct Trader <: Agent
    id::Int64
end

struct NoiseTrades <: Agent
    id::Int64
end

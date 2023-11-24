
abstract type Agent end

struct Trader <: Agent
    id::Int64
    orders::OrderedSet{Int64}
end

struct NoiseTrader <: Agent
    id::Int64
    orders::OrderedSet{Int64}
end


import DataStructures: OrderedSet

abstract type Agent end

struct Trader <: Agent
    id::Int64
    orders::OrderedSet{Int64}
end

struct NoiseTrader <: Agent
    id::Int64
    orders::OrderedSet{Int64}
    limit_rate::Float64
    market_rate::Float64
    cancel_rate::Float64
    sigma::Float64
end

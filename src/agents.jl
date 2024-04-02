
import DataStructures: OrderedSet

abstract type Agent end

struct Trader <: Agent
    id::Int64
    orders::Dict{Int64, LimitOrder}
end

struct NoiseTrader <: Agent
    id::Int64
    orders::Dict{Int64, LimitOrder}
    limit_rate::Float64
    market_rate::Float64
    cancel_rate::Float64
    sigma::Float64
end

NoiseTrader(
    id::Int64,
    limit_rate::Float64,
    market_rate::Float64,
    cancel_rate::Float64,
    sigma::Float64
    ) = NoiseTrader(id, Dict{Int64, LimitOrder}(), limit_rate, market_rate, cancel_rate, sigma)

struct MarketMaker <: Agent  # TODO: Maybe we could add knowledge about fundamental price?
    id::Int64
    orders::Dict{Int64, LimitOrder}
    rate::Float64
    K::Int64
    q::Float64
    size::Int64
end

MarketMaker(
    id::Int64,
    rate::Float64,
    K::Int64,
    q::Float64,
    size::Int64
    ) = MarketMaker(id, Dict{Int64, LimitOrder}(), rate, K, q, size)

struct MarketTaker <: Agent
    id::Int64
    orders::Dict{Int64, LimitOrder}
    rate::Float64
    exit_time::Int64
    time_sigma::Float64
    size::Int64
    chunk::Int64
    chunk_sigma::Float64
end

MarketTaker(
    id::Int64,
    rate::Float64,
    exit_time::Int64,
    time_sigma::Float64,
    size::Int64,
    chunk::Int64,
    chunk_sigma::Float64
    ) = MarketTaker(id, Dict{Int64, LimitOrder}(), rate, exit_time, time_sigma, size, chunk, chunk_sigma)

struct Chartist <: Agent
    id::Int64
    orders::Dict{Int64, LimitOrder}
    limit_rate::Float64
    market_rate::Float64
    coeff::Float64
    sigma::Float64
    horizon::Int64
    size::Int64
    size_sigma::Float64
end

Chartist(
    id::Int64,
    limit_rate::Float64,
    market_rate::Float64,
    coeff::Float64,
    sigma::Float64,
    horizon::Int64,
    size::Int64,
    size_sigma::Float64
    ) = Chartist(id, Dict{Int64, LimitOrder}(), limit_rate, market_rate, coeff, sigma, horizon, size, size_sigma)

struct Fundamentalist <: Agent
    id::Int64
    orders::Dict{Int64, LimitOrder}
    limit_rate::Float64
    market_rate::Float64
    coeff::Float64
    sigma::Float64
    horizon::Int64
    size::Int64
    size_sigma::Float64
end

Fundamentalist(
    id::Int64,
    limit_rate::Float64,
    market_rate::Float64,
    coeff::Float64,
    sigma::Float64,
    horizon::Int64,
    size::Int64,
    size_sigma::Float64
    ) = Fundamentalist(id, Dict{Int64, LimitOrder}(), limit_rate, market_rate, coeff, sigma, horizon, size, size_sigma)

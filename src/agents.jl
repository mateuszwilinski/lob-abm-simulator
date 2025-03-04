
import DataStructures: OrderedSet

abstract type Agent end

struct Trader{T <: Integer} <: Agent
    id::T
    orders::Dict{T, LimitOrder}
end

struct NoiseTrader{T <: Integer, F <: Real} <: Agent
    id::T
    orders::Dict{T, LimitOrder}
    limit_rate::F
    market_rate::F
    cancel_rate::F
    sigma::F
    size::T
    size_sigma::F
end

include("agents/noise_trader.jl")

struct MarketMaker{T <: Integer, F <: Real} <: Agent
    id::T
    orders::Dict{T, LimitOrder}
    rate::F
    K::T
    q::F
    size::T
end

include("agents/market_maker.jl")

struct MarketTaker{T <: Integer, F <: Real} <: Agent
    id::T
    orders::Dict{T, LimitOrder}
    rate::F
    exit_time::T
    time_sigma::F
    size::T
    chunk::T
    chunk_sigma::F
end

include("agents/market_taker.jl")

struct Chartist{T <: Integer, F <: Real} <: Agent
    id::T
    orders::Dict{T, LimitOrder}
    limit_rate::F
    market_rate::F
    coeff::F
    sigma::F
    horizon::T
    size::T
    size_sigma::F
end

include("agents/chartist.jl")

struct Fundamentalist{T <: Integer, F <: Real} <: Agent
    id::T
    orders::Dict{T, LimitOrder}
    limit_rate::F
    market_rate::F
    coeff::F
    sigma::F
    horizon::T
    size::T
    size_sigma::F
end

include("agents/fundamentalist.jl")


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

function NoiseTrader(  # TODO: Maybe these constructors could go to the separate file as well?
    id::T,
    limit_rate::F,
    market_rate::F,
    cancel_rate::F,
    sigma::F,
    size::T,
    size_sigma::F
    ) where {T <: Integer, F <: Real}
    return NoiseTrader(
        id,
        Dict{Integer, LimitOrder}(),
        limit_rate,
        market_rate,
        cancel_rate,
        sigma,
        size,
        size_sigma
        )
end

struct MarketMaker{T <: Integer, F <: Real} <: Agent
    id::T
    orders::Dict{T, LimitOrder}
    rate::F
    K::T
    q::F
    size::T
end

include("agents/market_maker.jl")

function MarketMaker(
    id::T,
    rate::F,
    K::T,
    q::F,
    size::T
    ) where {T <: Integer, F <: Real}
    return MarketMaker(
        id,
        Dict{Integer, LimitOrder}(),
        rate,
        K,
        q,
        size
        )
end

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

function MarketTaker(
    id::T,
    rate::F,
    exit_time::T,
    time_sigma::F,
    size::T,
    chunk::T,
    chunk_sigma::F
    ) where {T <: Integer, F <: Real}
    return MarketTaker(
        id,
        Dict{Integer, LimitOrder}(),
        rate,
        exit_time,
        time_sigma,
        size,
        chunk,
        chunk_sigma
        )
end

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

function Chartist(
    id::T,
    limit_rate::F,
    market_rate::F,
    coeff::F,
    sigma::F,
    horizon::T,
    size::T,
    size_sigma::F
    ) where {T <: Integer, F <: Real}
    return Chartist(
        id,
        Dict{Integer, LimitOrder}(),
        limit_rate,
        market_rate,
        coeff,
        sigma,
        horizon,
        size,
        size_sigma
        )
end

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

function Fundamentalist(
    id::T,
    limit_rate::F,
    market_rate::F,
    coeff::F,
    sigma::F,
    horizon::T,
    size::T,
    size_sigma::F
    ) where {T <: Integer, F <: Real}
    return Fundamentalist(
        id,
        Dict{Integer, LimitOrder}(),
        limit_rate,
        market_rate,
        coeff,
        sigma,
        horizon,
        size,
        size_sigma
        )
end
 
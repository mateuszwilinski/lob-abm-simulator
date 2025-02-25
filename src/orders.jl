
abstract type Order end

struct MarketOrder{T <: Integer} <: Order
    size::Base.RefValue{T}
    is_bid::Bool
    id::T
    agent::T
    symbol::String
end

function MarketOrder(
    size::T,
    is_bid::Bool,
    id::T,
    agent::T,
    symbol::String
    ) where {T <: Integer}
    if size < one(T)
        throw(ArgumentError("Order size must be at least 1"))
    end
    return MarketOrder(Ref(size), is_bid, id, agent, symbol)
end

struct LimitOrder{T <: Integer, F <: Real} <: Order
    price::F
    size::Base.RefValue{T}
    is_bid::Bool
    id::T
    agent::T
    symbol::String
end

function LimitOrder(
    price::F,
    size::T,
    is_bid::Bool,
    id::T,
    agent::T,
    symbol::String;
    tick_size::F = 0.0
    ) where {T <: Integer, F <: Real}
    if size < one(T)
        throw(ArgumentError("Order size must be at least 1"))
    end
    price = round_to_tick(price, tick_size)
    return LimitOrder(price, Ref(size), is_bid, id, agent, symbol)
end

struct Trade{T <: Integer, F <: Real}  # TODO: consider changing it to execution
    price::F
    size::T
    active_order::T
    passive_order::T
    active_agent::T
    passive_agent::T
end

"""
    get_size(o)

Return size of order "o".
"""
get_size(o::Order) = o.size[]

"""
    round_to_tick(price, tick_size)

Rounds a given `price` to the nearest multiple of `tick_size`. 
This function also rounds to 15 significant digits to mitigate floating-point precision issues.
If tick_size is zero, the function returns the original price.
"""
function round_to_tick(price::F, tick_size::F) where {F <: Real}
    if tick_size == 0.0
        return price
    else
        return round(round(price / tick_size) * tick_size, sigdigits=15)
    end
end

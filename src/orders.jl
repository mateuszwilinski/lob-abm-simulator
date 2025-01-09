
abstract type Order end

tick_size = 0.01

struct MarketOrder <: Order
    size::Base.RefValue{Int64}
    is_bid::Bool
    id::Int64
    agent::Int64
    symbol::String
end

struct LimitOrder <: Order
    price::Float64
    size::Base.RefValue{Int64}
    is_bid::Bool
    id::Int64
    agent::Int64
    symbol::String
end

MarketOrder(
    size::Int64,
    is_bid::Bool,
    id::Int64,
    agent::Int64,
    symbol::String
    ) = MarketOrder(Ref(size), is_bid, id, agent, symbol)

# Constructor with tick_size (price rounding)
LimitOrder(
    price::Float64,
    size::Int64,
    is_bid::Bool,
    id::Int64,
    agent::Int64,
    symbol::String;
    tick_size::Float64
) = LimitOrder(round_to_tick(price, tick_size), Ref(size), is_bid, id, agent, symbol)

# Constructor without tick_size (no price rounding)
LimitOrder(
    price::Float64,
    size::Int64,
    is_bid::Bool,
    id::Int64,
    agent::Int64,
    symbol::String
) = LimitOrder(price, Ref(size), is_bid, id, agent, symbol)

struct Trade
    price::Float64
    size::Int64
    active_order::Int64
    passive_order::Int64
    active_agent::Int64
    passive_agent::Int64
end
    
"""
    get_size(o)

Return size of order "o".
"""
get_size(o::Order) = o.size[]

function round_to_tick(price::Float64, tick_size::Float64)::Float64

    #Alternative implementation (solves problem with floating-point precission)

    #decimal_places = max(-floor(Int, log10(tick_size)), 0)
    #rounded_price = round(price / tick_size) * tick_size
    #rounded_price = round(rounded_price, digits=decimal_places)
    #return rounded_price

    return round(price / tick_size) * tick_size
end

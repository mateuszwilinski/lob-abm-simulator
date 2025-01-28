
abstract type Order end

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
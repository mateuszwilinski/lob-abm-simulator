
import DataStructures: OrderedSet

mutable struct Book
    bids::Dict{Float64, OrderedSet{LimitOrder}}
    asks::Dict{Float64, OrderedSet{LimitOrder}}
    best_bid::Float64
    best_ask::Float64
    time::Int64
    symbol::String
    trades::Vector{Trade}
    ticker_size::Float64
end

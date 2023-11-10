
import DataStructures: OrderedSet

mutable struct Book
    bids::Dict{Float64, OrderedSet}
    asks::Dict{Float64, OrderedSet}
    best_bid::Float64
    best_ask::Float64
    time::Int64
    symbol::String
end

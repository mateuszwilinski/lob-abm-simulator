
import DataStructures: OrderedSet

Base.@kwdef mutable struct Book
    bids::Dict{Float64, OrderedSet{LimitOrder}} = Dict()
    asks::Dict{Float64, OrderedSet{LimitOrder}} = Dict()
    best_bid::Float64 = NaN
    best_ask::Float64 = NaN
    time::Int64 = 0
    symbol::String = ""
    trades::Vector{Trade} = Trade[]
    ticker_size::Union{Float64, Nothing} = nothing
end

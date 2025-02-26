
import DataStructures: OrderedSet

mutable struct Book
    bids::Dict{Float64, OrderedSet{LimitOrder}}
    asks::Dict{Float64, OrderedSet{LimitOrder}}
    best_bid::Float64
    best_ask::Float64
    time::Int64
    symbol::String
    trades::Vector{Trade}
    tick_size::Float64
end

"""
    update_best_ask!(book)

Updates the "best_ask" field in the book according
to the current state.
"""
function update_best_ask!(book::Book)
    if isempty(keys(book.asks))
        book.best_ask = NaN
    else
        book.best_ask = minimum(keys(book.asks))
    end
end

"""
    update_best_bid!(book)

Updates the "best_bid" field in the book according
to the current state.
"""
function update_best_bid!(book::Book)
    if isempty(keys(book.bids))
        book.best_bid = NaN
    else
        book.best_bid = maximum(keys(book.bids))
    end
end


import DataStructures: OrderedSet

mutable struct Book{T <: Real}
    bids::Dict{T, OrderedSet{LimitOrder}}
    asks::Dict{T, OrderedSet{LimitOrder}}
    best_bid::T
    best_ask::T
    symbol::String
    tick_size::T  # TODO: do we really need tick size here?
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

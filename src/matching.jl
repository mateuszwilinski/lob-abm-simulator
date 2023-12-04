
"""
    add_order!(book, order)

Adds "order" (limit order) to the "book".
"""
function add_order!(book::Book, order::LimitOrder)
    if order.is_bid
        while (order.price >= book.best_ask) & (get_size(order) > 0)
            match_order!(book.asks[book.best_ask], order)
            if isempty(book.asks[book.best_ask])
                delete!(book.asks, book.best_ask)
                update_best_ask!(book)
            end
        end
        if get_size(order) > 0
            place_order!(book.bids, order)
            if !(order.price <= book.best_bid)  # This form is in case of best_bid==NaN
                update_best_bid!(book)
            end
        end
    else
        while (order.price <= book.best_bid) & (get_size(order) > 0)
            match_order!(book.bids[book.best_bid], order)
            if isempty(book.bids[book.best_bid])
                delete!(book.bids, book.best_bid)
                update_best_bid!(book)
            end
        end
        if get_size(order) > 0
            place_order!(book.asks, order)
            if !(order.price >= book.best_ask)  # This form is in case of best_bid==NaN
                update_best_ask!(book)
            end
        end
    end
end

"""
    add_order!(book, order)

Adds "order" (market order) to the "book".
"""
function add_order!(book::Book, order::MarketOrder)
    if order.is_bid
        while !isnan(book.best_ask) & (get_size(order) > 0)
            match_order!(book.asks[book.best_ask], order)
            if isempty(book.asks[book.best_ask])
                delete!(book.asks, book.best_ask)
                update_best_ask!(book)
            end
        end
    else
        while !isnan(book.best_bid) & (get_size(order) > 0)
            match_order!(book.bids[book.best_bid], order)
            if isempty(book.bids[book.best_bid])
                delete!(book.bids, book.best_bid)
                update_best_bid!(book)
            end
        end
    end
end


"""
    match_order!(book_level, order, book)

Matches "order" (market or limit) to a specific
"book_level" in a "book". Note that at this point
there are no checks whether the level is on the
correct side and has the correct price.
"""
function match_order!(book_level::OrderedSet{LimitOrder},
                      order::Order)
    for o in book_level
        if o.size[] == order.size[]
            delete!(book_level, o)
            # delete!(book.orders, o.id)  # TODO: move this outside
            order.size[] = 0
            break
        elseif o.size[] > order.size[]
            o.size[] -= order.size[]
            order.size[] = 0
            break
        else
            delete!(book_level, o)
            # delete!(book.orders, o.id)
            order.size[] -= o.size[]
        end
    end
    # TODO: return orders changed in the process!
end

"""
    place_order!(book_side, order)

Places an "order" on "book_side". Note that
at this point there are no checks on whether
the side is correct.
"""
function place_order!(book_side::Dict{Float64, OrderedSet{LimitOrder}},
                      order::LimitOrder)
    if !haskey(book_side, order.price)
        book_side[order.price] = OrderedSet()
    end
    push!(book_side[order.price], order)
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

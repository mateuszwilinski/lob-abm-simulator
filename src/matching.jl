
"""
    add_order!(book, order)

Adds "order" (limit order) to the "book".
"""
function add_order!(book::Book, order::LimitOrder)
    matched_orders = Vector{Tuple{Int64, Int64, Int64, Int64, Int64, Float64, Int64}}()
    if order.is_bid
        while (order.price >= book.best_ask) & (get_size(order) > 0)
            append!(matched_orders, match_order!(book.asks[book.best_ask], order))
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
            append!(matched_orders, match_order!(book.bids[book.best_bid], order))
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
    return matched_orders
end

"""
    add_order!(book, order)

Adds "order" (market order) to the "book".
"""
function add_order!(book::Book, order::MarketOrder)
    matched_orders = Vector{Tuple{Int64, Int64, Int64, Int64, Int64, Float64, Int64}}()
    if order.is_bid
        while !isnan(book.best_ask) & (get_size(order) > 0)
            append!(matched_orders, match_order!(book.asks[book.best_ask], order))
            if isempty(book.asks[book.best_ask])
                delete!(book.asks, book.best_ask)
                update_best_ask!(book)
            end
        end
    else
        while !isnan(book.best_bid) & (get_size(order) > 0)
            append!(matched_orders, match_order!(book.bids[book.best_bid], order))
            if isempty(book.bids[book.best_bid])
                delete!(book.bids, book.best_bid)
                update_best_bid!(book)
            end
        end
    end
    return matched_orders
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
    matched_orders = Vector{Tuple{Int64, Int64, Int64, Int64, Int64, Float64, Int64}}()
    for o in book_level
        if o.size[] == order.size[]
            push!(matched_orders, (o.agent, o.id, order.agent, order.id,
                                   get_size(o), o.price, 0))
            o.size[] = 0
            delete!(book_level, o)
            order.size[] = 0
            break
        elseif o.size[] > order.size[]
            o.size[] -= order.size[]
            push!(matched_orders, (o.agent, o.id, order.agent, order.id,
                                   get_size(order), o.price, get_size(o)))
            order.size[] = 0
            break
        else
            push!(matched_orders, (o.agent, o.id, order.agent, order.id,
                                   get_size(o), o.price, 0))
            order.size[] -= o.size[]
            o.size[] = 0
            delete!(book_level, o)
        end
    end
    return matched_orders
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

"""
    add_trades!(book, matched_orders)

Adds trades to the book.
"""
function add_trades!(book::Book,
                      matched_orders::Vector{Tuple{Int64, Int64, Int64,
                                                   Int64, Int64, Float64, Int64}})
    for (matched_agent, matched_order, active_agent,
         active_order, size, price,) in matched_orders
        push!(book.trades, Trade(price, size, active_order, matched_order,
                                 active_agent, matched_agent))
    end
end

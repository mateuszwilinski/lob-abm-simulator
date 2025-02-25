
"""
    pass_order!(book, order, agent, simulation, save)

Passes an "order" (limit order) to the "book" and save it if necessary.
Returns messages to be sent to affected agents.
"""
function pass_order!(book::Book, order::LimitOrder, agent::Agent, simulation::Dict, save::Bool)
    if save
        save_order!(simulation, order, agent)
    end
    matched_orders = add_order!(book, order)
    add_trades!(book, matched_orders)
    if get_size(order) > 0
        agent.orders[order.id] = order
    end
    msgs = messages_from_match(matched_orders, book)
    return msgs
end

"""
    pass_order!(book, order, agent, simulation, save)

Passes an "order" (market order) to the "book" and save it if necessary.
Returns messages to be sent to affected agents.
"""
function pass_order!(book::Book, order::MarketOrder, agent::Agent, simulation::Dict, save::Bool)
    if save
        save_order!(simulation, order, agent)
    end
    matched_orders = add_order!(book, order)
    add_trades!(book, matched_orders)
    msgs = messages_from_match(matched_orders, book)
    return msgs
end

"""
    add_order!(book, order)

Adds "order" (limit order) to the "book" and returns the matched orders.
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
    match_order!(book_level, order)

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

"""
    messages_from_match(matched_orders, book, params)

Create messages about "matched_orders" for both affected agents and reporting agents.
"""
function messages_from_match(matched_orders::Vector{Tuple{Int64, Int64,
                                                          Int64, Int64,
                                                          Int64, Float64,
                                                          Int64}},
                             book::Book)
    msgs = Vector{Dict}()
    for (matched_agent, matched_order, active_agent, active_order,
         trade_size, price, order_size) in matched_orders
        # send message to affected agent
        msg = Dict{String, Union{String, Int64, Float64, Bool}}()
        msg["recipient"] = matched_agent
        msg["book"] = book.symbol
        msg["activation_time"] = book.time
        msg["activation_priority"] = 0  # TODO: think through how this priority should work(!!!)
        msg["action"] = "UPDATE_ORDER"
        msg["order_id"] = matched_order
        msg["order_size"] = order_size
        push!(msgs, msg)
    end
    return msgs
end

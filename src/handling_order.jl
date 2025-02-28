
"""
    pass_order!(book, order, agents, simulation, parameters)

Passes an "order" to the "book" and save it if necessary.
Returns messages to be sent to affected agents.
"""
function pass_order!(book::Book, order::Order, agents::Dict{Int64, Agent}, simulation::Dict, parameters::Dict)
    # save order if requested
    if parameters["save_events"]
        save_order!(simulation, order)
    end

    # add order to the book and get matched orders
    matched_events = add_order!(book, order, simulation["current_time"])

    # save executions if needed
    if parameters["save_events"]
        save_trades!(book, matched_events)
    end

    # remove the matched orders from the agent's orders
    remove_matched_events!(matched_events, agents)

    # decide what to do with the remaining order
    if get_size(order) > 0
        remaining_order!(order, agents[order.agent], book)
    end

    # create messages for affected agents
    msgs = messages_from_match(matched_events, book, simulation)

    return msgs
end

"""
    remaining_order!(order, agent)

Add remaining limit "order" to the "agent" orders.
"""
function remaining_order!(order::LimitOrder, agent::Agent, book::Book)
    if order.is_bid
        place_order!(book.bids, order)
        if !(order.price <= book.best_bid)  # This form is in case of best_bid==NaN
            update_best_bid!(book)
        end
    else
        place_order!(book.asks, order)
        if !(order.price >= book.best_ask)  # This form is in case of best_bid==NaN
            update_best_ask!(book)
        end
    end
    agent.orders[order.id] = order
end

"""
    remaining_order!(order, agent)

Placeholder for potential actions regarding remaining market order.
"""
function remaining_order!(order::MarketOrder, agent::Agent, book::Book)
    nothing
end

"""
    add_order!(book, order)

Adds (limit) "order" to the "book" and returns the matched orders.
"""
function add_order!(book::Book, order::LimitOrder, time::Int64)
    match_events = Vector{Event}()
    if order.is_bid
        while (order.price >= book.best_ask) & (get_size(order) > 0)
            append!(match_events, match_order!(book.asks[book.best_ask], order, time))
            if isempty(book.asks[book.best_ask])
                delete!(book.asks, book.best_ask)
                update_best_ask!(book)
            end
        end
    else
        while (order.price <= book.best_bid) & (get_size(order) > 0)
            append!(match_events, match_order!(book.bids[book.best_bid], order, time))
            if isempty(book.bids[book.best_bid])
                delete!(book.bids, book.best_bid)
                update_best_bid!(book)
            end
        end
    end
    return match_events
end

"""
    add_order!(book, order)

Adds (market) "order" to the "book" and returns the matched orders.
"""
function add_order!(book::Book, order::MarketOrder, time::Int64)
    matched_events = Vector{Event}()
    if order.is_bid
        while !isnan(book.best_ask) & (get_size(order) > 0)
            append!(matched_events, match_order!(book.asks[book.best_ask], order, time))
            if isempty(book.asks[book.best_ask])
                delete!(book.asks, book.best_ask)
                update_best_ask!(book)
            end
        end
    else
        while !isnan(book.best_bid) & (get_size(order) > 0)
            append!(matched_events, match_order!(book.bids[book.best_bid], order, time))
            if isempty(book.bids[book.best_bid])
                delete!(book.bids, book.best_bid)
                update_best_bid!(book)
            end
        end
    end
    return matched_events
end


"""
    match_order!(book_level, order, time)

Matches "order" (market or limit) to a specific
"book_level" in a "book". Note that at this point
there are no checks whether the level is on the
correct side and has the correct price.
"""
function match_order!(book_level::OrderedSet{LimitOrder}, order::Order, time::Int64)
    match_events = Vector{Event}()
    for o in book_level
        if get_size(o) == get_size(order)
            event = Event(time, 4, o.id, get_size(o), o.price, o.is_bid, o.agent, order.id, order.agent)
            push!(match_events, event)

            o.size[] = 0
            delete!(book_level, o)
            order.size[] = 0
            break
        elseif get_size(o) > get_size(order)
            event = Event(time, 4, o.id, get_size(order), o.price, o.is_bid, o.agent, order.id, order.agent)
            push!(match_events, event)

            o.size[] -= get_size(order)
            order.size[] = 0
            break
        else
            event = Event(time, 4, o.id, get_size(o), o.price, o.is_bid, o.agent, order.id, order.agent)
            push!(match_events, event)

            order.size[] -= get_size(o)
            o.size[] = 0
            delete!(book_level, o)
        end
    end
    return match_events
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
    messages_from_match(matched_events, book, params)

Create messages about "matched_events" for both affected agents and reporting agents.
"""
function messages_from_match(match_events::Vector{Event}, book::Book, simulation::Dict)
    msgs = Vector{Dict}()
    for event in match_events
        # prepare message for affected agent
        msg = Dict{String, Union{String, Int64, Float64, Bool}}()
        msg["recipient"] = event.agent_id
        msg["book"] = book.symbol
        msg["activation_time"] = simulation["current_time"]
        msg["activation_priority"] = 0  # TODO: think through how this priority should work(!!!)
        msg["action"] = "UPDATE_ORDER"
        msg["order_id"] = event.order_id
        msg["order_size"] = event.size  # TODO: traded size should also proabably be passed, maybe the price as well?
        push!(msgs, msg)
    end
    return msgs
end

"""
    remove_matched_events!(matched_events, agents)

Remove matched orders from "agents" orders.
"""
function remove_matched_events!(match_events::Vector{Event}, agents::Dict{Int64, Agent})
    if !isempty(match_events)
        # check whether the last matching was not partial
        event = match_events[end]
        if get_size(agents[event.agent_id].orders[event.order_id]) == 0
            delete!(agents[event.agent_id].orders, event.order_id)
        end
        # remove all other orders
        for event in match_events[1:(end-1)]
            delete!(agents[event.agent_id].orders, event.order_id)
        end
    end
end


import Base.Iterators: take

"""
    pass_order!(book, order, agents, sim, params)

Passes an "order" to the "book" and save it if necessary.
Returns messages to be sent to affected agents.
"""
function pass_order!(book::Book, order::Order, agents::Dict{Int64, Agent}, sim::Dict, params::Dict)
    # add order to the book and get matched orders
    msgs = add_order!(book, order, sim, params)

    # remove the matched orders from the agent's orders
    remove_matched_orders!(msgs, agents)

    # decide what to do with the remaining order
    if get_size(order) > 0
        remaining_order!(order, agents[order.agent], book)
    end

    # save order if requested
    if params["save_events"]
        save_order!(sim, order)
        if params["snapshots"]
            snapshot = take_snapshot(book, params["levels"])
            save_snapshot!(sim, snapshot)
        end
    end
    
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
    add_order!(book, order, sim, params)

Adds (limit) "order" to the "book" and returns the matched orders.
"""
function add_order!(book::Book, order::Order, sim::Dict, params::Dict)
    msgs = Vector{Dict}()
    if order.is_bid
        while is_buy_volume_available(book, order)
            append!(msgs, match_order!(
                                book.asks[book.best_ask],
                                book.asks,
                                book,
                                update_best_ask!,
                                order,
                                sim,
                                params
                                ))
        end
    else
        while is_sell_volume_available(book, order)
            append!(msgs, match_order!(
                                book.bids[book.best_bid],
                                book.bids,
                                book,
                                update_best_bid!,
                                order,
                                sim,
                                params
                                ))
        end
    end
    return msgs
end

"""
    is_buy_volume_available(book, order)

Check whether there is enough volume at the best price to buy in
the book and if the limit order is not fulfilled already.
"""
function is_buy_volume_available(book::Book, order::LimitOrder)
    return (order.price >= book.best_ask) & (get_size(order) > 0)
end

"""
    is_buy_volume_available(book, order)

Check whether there is enough volume at the best price to buy in
the book and if the market order is not fulfilled already.
"""
function is_buy_volume_available(book::Book, order::MarketOrder)
    return !isnan(book.best_ask) & (get_size(order) > 0)
end

"""
    is_sell_volume_available(book, order)

Check whether there is enough volume at the best price to sell in
the book and if the limit order is not fulfilled already.
"""
function is_sell_volume_available(book::Book, order::LimitOrder)
    return (order.price <= book.best_bid) & (get_size(order) > 0)
end

"""
    is_sell_volume_available(book, order)

Check whether there is enough volume at the best price to sell in
the book and if the market order is not fulfilled already.
"""
function is_sell_volume_available(book::Book, order::MarketOrder)
    return !isnan(book.best_bid) & (get_size(order) > 0)
end

"""
    match_order!(book_level, book_side, book, update_side, order, sim, params)

Matches "order" (market or limit) to a specific "book_level",
on a "book.side" in the "book". Note that at this point there are
no checks whether the level is on the correct side and has
the correct price.
"""
function match_order!(
                book_level::OrderedSet{LimitOrder},
                book_side::Dict{Float64, OrderedSet{LimitOrder}},
                book::Book,
                update_side::Function,
                order::Order,
                sim::Dict,
                params::Dict
                )
    time = sim["current_time"]
    msgs = Vector{Dict}()
    while length(book_level) > 1
        o = first(book_level)
        if get_size(o) == get_size(order)
            execution_size = get_size(order)
            o.size[] = 0
            delete!(book_level, o)
            order.size[] = 0

            msg = process_execution_information!(
                                            execution_size,
                                            order,
                                            o,
                                            book,
                                            sim,
                                            params
                                            )
            push!(msgs, msg)
            return msgs
        elseif get_size(o) > get_size(order)
            execution_size = get_size(order)
            o.size[] -= get_size(order)
            order.size[] = 0

            msg = process_execution_information!(
                                            execution_size,
                                            order,
                                            o,
                                            book,
                                            sim,
                                            params
                                            )
            push!(msgs, msg)
            return msgs
        else
            execution_size = get_size(o)
            order.size[] -= get_size(o)
            o.size[] = 0
            delete!(book_level, o)

            msg = process_execution_information!(
                                            execution_size,
                                            order,
                                            o,
                                            book,
                                            sim,
                                            params
                                            )
            push!(msgs, msg)
        end
    end
    # we still need to deal with the last order
    last_order = last(book_level)
    if get_size(last_order) > get_size(order)
        execution_size = get_size(order)
        last_order.size[] -= get_size(order)
        order.size[] = 0

        msg = process_execution_information!(
            execution_size,
            order,
            last_order,
            book,
            sim,
            params
            )
        push!(msgs, msg)
    else
        execution_size = get_size(last_order)
        order.size[] -= get_size(last_order)
        last_order.size[] = 0
        delete!(book_side, last_order.price)
        update_side(book)

        msg = process_execution_information!(
            execution_size,
            order,
            last_order,
            book,
            sim,
            params
            )
        push!(msgs, msg)
    end
    return msgs
end

"""
    process_execution_information!(execution_size, agressive, passive, book, sim, params)

Process information about the execution of "execution_size" of "agressive" order
against "passive" order in the "book". Save the event if requested.
"""
function process_execution_information!(
                            execution_size::Int64,
                            agressive::Order,
                            passive::LimitOrder,
                            book::Book,
                            sim::Dict,
                            params::Dict
                            )
    #create message for affected agent
    msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    msg["recipient"] = passive.agent
    msg["book"] = book.symbol
    msg["activation_time"] = sim["current_time"]
    msg["activation_priority"] = 0  # TODO: think through how this priority should work(!!!)
    msg["action"] = "UPDATE_ORDER"
    msg["order_id"] = passive.id
    msg["order_size"] = get_size(passive)
    msg["is_bid"] = passive.is_bid
    msg["exec_size"] = execution_size
    msg["exec_price"] = passive.price

    # save event if requested
    if params["save_events"]
        event = Event(  # TODO: why not separate function save_execution?
            sim["current_time"],
            4,
            passive.id,
            execution_size,
            passive.price,
            passive.is_bid,
            passive.agent,
            agressive.id,
            agressive.agent
            )
        push!(sim["events"], event)
        if params["snapshots"]
            snapshot = take_snapshot(book, params["levels"])
            save_snapshot!(sim, snapshot)
        end
    end
    return msg
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
    remove_matched_orders!(msgs, agents)

Remove matched orders from "agents" orders.
"""
function remove_matched_orders!(msgs::Vector{Dict}, agents::Dict{Int64, Agent})
    if !isempty(msgs)
        # check whether the last matching was not partial
        msg = msgs[end]
        if get_size(agents[msg["recipient"]].orders[msg["order_id"]]) == 0
            delete!(agents[msg["recipient"]].orders, msg["order_id"])
        end
        # remove all other orders
        for msg in msgs[1:(end-1)]
            delete!(agents[msg["recipient"]].orders, msg["order_id"])
        end
    end
end

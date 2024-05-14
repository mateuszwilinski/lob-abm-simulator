
"""
    cancel_order!(order_id, book, agent)

Delete order with id equal to "order_id" from the "book" and the "agent"'s orders.
"""
function cancel_order!(order_id::Int64, book::Book, agent::Agent)
    if agent.orders[order_id].is_bid
        delete!(book.bids[agent.orders[order_id].price], agent.orders[order_id])
        if isempty(book.bids[agent.orders[order_id].price])
            delete!(book.bids, agent.orders[order_id].price)
            if book.best_bid == agent.orders[order_id].price
                update_best_bid!(book)
            end
        end
    else
        delete!(book.asks[agent.orders[order_id].price], agent.orders[order_id])
        if isempty(book.asks[agent.orders[order_id].price])
            delete!(book.asks, agent.orders[order_id].price)
            if book.best_ask == agent.orders[order_id].price
                update_best_ask!(book)
            end
        end
    end
    delete!(agent.orders, order_id)
end

"""
    modify_order!(order_id, new_size, book, agent)

For the order with id equal to "order_id" in the "book" and the "agent"'s orders,
change order's size into "new_size".
"""
function modify_order!(order_id::Int64, new_size::Int64, book::Book, agent::Agent)
    if agent.orders[order_id].is_bid
        delete!(book.bids[agent.orders[order_id].price], agent.orders[order_id])
        push!(book.bids[agent.orders[order_id].price], agent.orders[order_id])
    else
        delete!(book.asks[agent.orders[order_id].price], agent.orders[order_id])
        push!(book.asks[agent.orders[order_id].price], agent.orders[order_id])
    end
    agent.orders[order_id].size[] = new_size  # TODO: zero should not be allowed
end

"""
    remove_matched_orders!(matched_orders, agents)

Remove "matched_orders" from "agents" orders.
"""
function remove_matched_orders!(matched_orders::Vector{Tuple{Int64, Int64, Int64,
                                                             Int64, Int64, Float64, Int64}},
                                agents::Dict{Int64, Agent})
    # check whether the last matching was not partial
    (agent_id, order_id,) = matched_orders[end]
    if get_size(agents[agent_id].orders[order_id]) == 0
        delete!(agents[agent_id].orders, order_id)
    end
    # remove all other orders
    for (agent_id, order_id,) in matched_orders[1:(end-1)]
        delete!(agents[agent_id].orders, order_id)
    end
end  # TODO: This function is potentially useless and most likely outdated(!!!).

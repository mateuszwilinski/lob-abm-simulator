
"""
    cancel_order!(order_id, book, agent, simulation, parameters)

Cancel order and save the cancellation if needed.
"""
function cancel_order!(order_id::Int64, book::Book, agent::Agent, simulation::Dict, parameters::Dict)
    if parameters["save_events"]
        save_cancel!(simulation, order_id, agent)
    end
    remove_order!(order_id, book, agent)
end

"""
    cancel_inconsistent_orders!(agent, book, is_bid, parameters, simulation, expected_price)

Cancel orders inconsistent with both "is_bid" direction and "expected_price".
"""
function cancel_inconsistent_orders!(
            agent::Agent,
            book::Book,
            is_bid::Bool,
            parameters::Dict,
            simulation::Dict,
            expected_price::F
            ) where {F <: Real}

    for (order_id, o) in agent.orders
        if o.is_bid != is_bid
            if parameters["save_events"]
                save_cancel!(simulation, order_id, agent)
            end
            remove_order!(order_id, book, agent)
        elseif (((o.price > expected_price) && o.is_bid) ||
                ((o.price < expected_price) && !o.is_bid))
            if parameters["save_events"]
                save_cancel!(simulation, order_id, agent)
            end
            remove_order!(order_id, book, agent)
        end
    end
end

"""
    cancel_inconsistent_orders!(agent, book, is_bid)

Cancel orders inconsistent with "is_bid" direction.
"""
function cancel_inconsistent_orders!(agent::Agent, book::Book, is_bid::Bool, parameters::Dict, simulation::Dict)
    for (order_id, o) in agent.orders
        if o.is_bid != is_bid
            if parameters["save_events"]
                save_cancel!(simulation, order_id, agent)
            end
            remove_order!(order_id, book, agent)
        end
    end
end

"""
    remove_order!(order_id, book, agent)

Delete order with id equal to "order_id" from the "book" and the "agent"'s orders.
"""
function remove_order!(order_id::Int64, book::Book, agent::Agent)
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
    if new_size <= 0
        throw(error("Order size must be positive."))
    end
    if agent.orders[order_id].is_bid
        delete!(book.bids[agent.orders[order_id].price], agent.orders[order_id])
        push!(book.bids[agent.orders[order_id].price], agent.orders[order_id])
    else
        delete!(book.asks[agent.orders[order_id].price], agent.orders[order_id])
        push!(book.asks[agent.orders[order_id].price], agent.orders[order_id])
    end
    agent.orders[order_id].size[] = new_size
end

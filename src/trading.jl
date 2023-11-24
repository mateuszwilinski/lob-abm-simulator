
"""
    wake_up!(agent, book, sup_id; market=true, limit=true, cancel=true)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function wake_up!(agent::NoiseTrader, book::Book, sup_id::Int64;
                  market::Bool=true, limit::Bool=true, cancel::Bool=true)
    if market
        side = rand(Bool)
        size = 1
        order = MarketOrder(size, side, sup_id+1, agent.id, book.symbol)
        add_order!(book, order)
        push!(agend.orders, order.id)
    end
    if limit
        side = rand(Bool)
        size = 1
        price = mid_price(book) + randn() * agent.sigma
        order = LimitOrder(price, size, side, sup_id+1, agent.id, book.symbol)
        add_order!(book, order)
        push!(agend.orders, order.id)
    end
    if cancel
        order_id = rand(agent.orders)
        cancel_order!(order_id, book)
    end

    # TODO: You need to generate a message to the simulation here,
    #       so that it can wake up the agent again. (!!!)
end

"""
    cancel_order!(order_id, book)

Delete order with id equal to "order_id" from the "book".
"""
function cancel_order!(order_id::Int64, book::Book)
    if book.orders[order_id].is_bid
        delete!(book.bids[book.orders[order_id].price], book.orders[order_id])
    else
        delete!(book.asks[book.orders[order_id].price], book.orders[order_id])
    end
    delete!(book.orders, order_id)
end

"""
    modify_order!(order_id, new_size, book)

For the order with id equal to "order_id" in the "book", change order's size
into "new_size".
"""
function modify_order!(order_id::Int64, new_size::Int64, book::Book)
    if book.orders[order_id].is_bid
        delete!(book.bids[book.orders[order_id].price], book.orders[order_id])
        push!(book.bids[book.orders[order_id].price], book.orders[order_id])
    else
        delete!(book.asks[book.orders[order_id].price], book.orders[order_id])
        push!(book.asks[book.orders[order_id].price], book.orders[order_id])
    end
    book.orders[order_id] = new_size
end

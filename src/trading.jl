
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

    # TODO: Probably you need to generate a message to the simulation here,
    #       so that it can wake up the agent again.
end

function cancel_order!(order_id::Int64, book::Book)
    if book.orders[order_id].is_bid
        delete!(book.bids[book.orders[order_id].price], book.orders[order_id])
    else
        delete!(book.asks[book.orders[order_id].price], book.orders[order_id])
    end
    delete!(book.orders, order_id)
end

function modify_order!(order_id::Int64, new_size::Book)
    if book.orders[order_id].is_bid
        delete!(book.bids[book.orders[order_id].price], book.orders[order_id])
        push!(book.bids[book.orders[order_id].price], book.orders[order_id])
    else
        delete!(book.asks[book.orders[order_id].price], book.orders[order_id])
        push!(book.asks[book.orders[order_id].price], book.orders[order_id])
    end
    book.orders[order_id] = new_size
end


"""
    initiate!(agent, book, sup_id)

Initiate NoiseTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::NoiseTrader, book::Book, params::Dict)
    mrkt_msg = Dict{String, Union{String, Int64, Float64}}()
    mrkt_msg["recipient"] = agent.id
    mrkt_msg["book"] = book.symbol
    lmt_msg = copy(mrkt_msg)
    cncl_msg = copy(mrkt_msg)

    mrkt_msg["activation_time"] = ceil(Int64, rand(Exponential(agent.market_rate)))
    lmt_msg["activation_time"] = ceil(Int64, rand(Exponential(agent.limit_rate)))
    cncl_msg["activation_time"] = ceil(Int64, rand(Exponential(agent.cancel_rate)))

    mrkt_msg["action"] = "market_order"
    lmt_msg["action"] = "limit_order"
    cncl_msg["action"] = "cancel_order"
    
    return (mrkt_msg, lmt_msg, cncl_msg)
end

"""
    wake_up!(agent, book, sup_id; market=true, limit=true, cancel=true)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function wake_up!(agent::NoiseTrader, book::Book, params::Dict, msg::Dict)
    sup_id = params["ord_id"]
    if msg["action"] == "market_order"
        side = rand(Bool)
        size = 1
        order = MarketOrder(size, side, sup_id+1, agent.id, book.symbol)
        add_order!(book, order)
        push!(agent.orders, order.id)

        rate = agent.limit_rate
    elseif msg["action"] == "limit_order"
        side = rand(Bool)
        size = 1
        price = mid_price(book) + randn() * agent.sigma
        order = LimitOrder(price, size, side, sup_id+1, agent.id, book.symbol)
        add_order!(book, order)
        push!(agent.orders, order.id)

        rate = agent.market_rate
    elseif msg["action"] == "cancel_order"
        order_id = rand(agent.orders)
        cancel_order!(order_id, book)

        rate = agent.cancel_rate
    end

    activation_time_diff = ceil(Int64, rand(Exponential(rate)))
    new_msg = copy(msg)
    new_msg["activation_time"] = msg["activation_time"] + activation_time_diff
    return (new_msg,)
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


import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate NoiseTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::NoiseTrader, book::Book, params::Dict)
    mrkt_msg = Dict{String, Union{String, Int64, Float64}}()
    mrkt_msg["recipient"] = agent.id
    mrkt_msg["book"] = book.symbol
    lmt_msg = copy(mrkt_msg)
    cncl_msg = copy(mrkt_msg)

    mrkt_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                       rand(Exponential(agent.market_rate)))
    lmt_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                      rand(Exponential(agent.limit_rate)))
    cncl_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                       rand(Exponential(agent.cancel_rate)))

    mrkt_msg["action"] = "market_order"
    lmt_msg["action"] = "limit_order"
    cncl_msg["action"] = "cancel_order"
    
    return (mrkt_msg, lmt_msg, cncl_msg)
end

"""
    wake_up!(agent, book, orders, params, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::NoiseTrader, book::Book, orders::Dict{Int64, LimitOrder},
                 params::Dict, msg::Dict)
    if msg["action"] == "market_order"
        side = rand(Bool)
        size = 1
        params["ord_id"] += 1
        order = MarketOrder(size, side, params["ord_id"], agent.id, book.symbol)
        add_order!(book, order)

        rate = agent.market_rate
    elseif msg["action"] == "limit_order"
        side = rand(Bool)
        size = 1
        price = mid_price(book) + randn() * agent.sigma
        if isnan(price)
            price = params["fundamental_price"]
        end
        params["ord_id"] += 1
        order = LimitOrder(price, size, side, params["ord_id"], agent.id, book.symbol)
        add_order!(book, order)
        orders[order.id] = order
        if get_size(order) > 0  # TODO: Should it be done here or in "add_order!" function?
            push!(agent.orders, order.id)
            orders[order.id] = order
        end

        rate = agent.limit_rate
    elseif msg["action"] == "cancel_order"
        if !isempty(agent.orders)
            order_id = rand(agent.orders)
            cancel_order!(order_id, book, orders)
            delete!(agent.orders, order_id)
        end

        rate = agent.cancel_rate
    end

    activation_time_diff = ceil(Int64, rand(Exponential(rate)))
    response = copy(msg)
    response["activation_time"] = msg["activation_time"] + activation_time_diff
    msgs = Vector{Dict}()
    push!(msgs, response)
    return msgs
end

"""
    cancel_order!(order_id, book, orders)

Delete order with id equal to "order_id" from the "book" and the "orders".
"""
function cancel_order!(order_id::Int64, book::Book, orders::Dict{Int64, LimitOrder})
    if orders[order_id].is_bid
        delete!(book.bids[orders[order_id].price], orders[order_id])
    else
        delete!(book.asks[orders[order_id].price], orders[order_id])
    end
    delete!(orders, order_id)
end

"""
    modify_order!(order_id, new_size, book, orders)

For the order with id equal to "order_id" in the "book" and the "orders",
change order's size into "new_size".
"""
function modify_order!(order_id::Int64, new_size::Int64, book::Book,
                       orders::Dict{Int64, LimitOrder})
    if orders[order_id].is_bid
        delete!(book.bids[orders[order_id].price], orders[order_id])
        push!(book.bids[orders[order_id].price], orders[order_id])
    else
        delete!(book.asks[orders[order_id].price], orders[order_id])
        push!(book.asks[orders[order_id].price], orders[order_id])
    end
    orders[order_id] = new_size
end

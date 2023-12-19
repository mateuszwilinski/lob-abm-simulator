
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
    mrkt_msg["activation_priority"] = 1
    lmt_msg["activation_priority"] = 1
    cncl_msg["activation_priority"] = 1
    
    mrkt_msg["action"] = "MARKET_ORDER"
    lmt_msg["action"] = "LIMIT_ORDER"
    cncl_msg["action"] = "CANCEL_ORDER"
    
    msgs = Vector{Dict}()
    append!(msgs, [mrkt_msg, lmt_msg, cncl_msg])
    return msgs
end

"""
    create_mkt_order(agent, symbol, order_id)

Create new market order with "order_id" for "agent" and "symbol".
"""
function create_mkt_order(agent::NoiseTrader, symbol::String, order_id::Int64)
    return MarketOrder(1, rand(Bool), order_id, agent.id, symbol)
end

"""
    create_lmt_order(agent, symbol, order_id, price)

Create new limit order with "order_id" and "price" for "agent" and "symbol".
"""
function create_lmt_order(agent::NoiseTrader, symbol::String,
                          order_id::Int64, price::Float64)
    return LimitOrder(price, 1, rand(Bool), order_id, agent.id, symbol)
end

"""
    messages_from_match(matched_orders, book)

Create messages about "matched_orders".
"""
function messages_from_match(matched_orders::Vector{Tuple{Int64, Int64}}, book::Book)
    msgs = Vector{Dict}()
    for (agent_id, order_id) in matched_orders
        msg = Dict{String, Union{String, Int64, Float64}}()
        msg["recipient"] = agent_id
        msg["book"] = book.symbol
        msg["activation_time"] = book.time
        msg["activation_priority"] = 0  # TODO: think through how this priority should work(!!!)
        msg["action"] = "UPDATE_ORDER"
        msg["order_id"] = order_id
        push!(msgs, msg)
    end
    return msgs
end

"""
    action!(agent, book, agents, params, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::NoiseTrader, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, msg::Dict)  # TODO: agents are useless for noise traders, but might be useful for other traders.
    # Initialise new messages
    msgs = Vector{Dict}()
    
    # Agent trades
    if msg["action"] == "MARKET_ORDER"
        params["last_id"] += 1
        order = create_mkt_order(agent, book.symbol, params["last_id"])
        matched_orders = add_order!(book, order)

        rate = agent.market_rate
        append!(msgs, messages_from_match(matched_orders, book))
    elseif msg["action"] == "LIMIT_ORDER"
        price = mid_price(book) + randn() * agent.sigma  # TODO: maybe we should add rounding to ticks?
        if isnan(price)
            price = params["fundamental_price"]  # TODO: this may depend on time
        end
        params["last_id"] += 1
        order = create_lmt_order(agent, book.symbol, params["last_id"], price)
        matched_orders = add_order!(book, order)
        if get_size(order) > 0
            agent.orders[order.id] = order
        end

        rate = agent.limit_rate
        append!(msgs, messages_from_match(matched_orders, book))
    elseif msg["action"] == "CANCEL_ORDER"
        if !isempty(agent.orders)
            order_id = rand(keys(agent.orders))
            cancel_order!(order_id, book, agent)
            delete!(agent.orders, order_id)
        end

        rate = agent.cancel_rate
    elseif msg["action"] == "UPDATE_ORDER"
        if get_size(agent.orders[msg["order_id"]]) == 0
            delete!(agent.orders, msg["order_id"])
        end
        return msgs
    else
        throw(error("Unknown action for a Noise Trader."))
    end

    # Agent sends new messages
    activation_time_diff = ceil(Int64, rand(Exponential(rate)))
    response = copy(msg)
    response["activation_time"] += activation_time_diff
    push!(msgs, response)

    return msgs
end

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
function remove_matched_orders!(matched_orders::Vector{Tuple{Int64, Int64}}, agents::Dict{Int64, Agent})
    # check whether the last matching was not partial
    (agent_id, order_id) = matched_orders[end]
    if get_size(agents[agent_id].orders[order_id]) == 0
        delete!(agents[agent_id].orders, order_id)
    end
    # remove all other orders
    for (agent_id, order_id) in matched_orders[1:(end-1)]
        delete!(agents[agent_id].orders, order_id)
    end
end  # TODO: This function is potentially useless.

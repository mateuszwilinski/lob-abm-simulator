
import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate MarketMaker "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::MarketMaker, book::Book, params::Dict)
    lmt_msg = Dict{String, Union{String, Int64, Float64}}()
    lmt_msg["recipient"] = agent.id
    lmt_msg["book"] = book.symbol
    cncl_msg = copy(lmt_msg)

    lmt_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                      rand(Exponential(agent.rate)))
    cncl_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                       rand(Exponential(agent.rate)))
    lmt_msg["activation_priority"] = 1
    cncl_msg["activation_priority"] = 1
    
    lmt_msg["action"] = "LIMIT_ORDER"
    cncl_msg["action"] = "CANCEL_ORDER"
    
    msgs = Vector{Dict}()
    append!(msgs, [lmt_msg, cncl_msg])
    return msgs
end

"""
    create_lmt_order(agent, symbol, order_id, price)

Create new limit order with "order_id" and "price" for "agent" and "symbol".
"""
function create_lmt_order(agent::MarketMaker, symbol::String,
                          order_id::Int64, price::Float64)
    return LimitOrder(price, 1, rand(Bool), order_id, agent.id, symbol)
end

"""
    action!(agent, book, agents, params, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::MarketMaker, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, msg::Dict)  # TODO: agents are useless for noise traders, but might be useful for other traders.
    # Initialise new messages
    msgs = Vector{Dict}()
    
    # Agent trades
    if msg["action"] == "LIMIT_ORDER"
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

        rate = agent.rate
        append!(msgs, messages_from_match(matched_orders, book))
    elseif msg["action"] == "CANCEL_ORDER"
        if !isempty(agent.orders)
            order_id = rand(keys(agent.orders))
            cancel_order!(order_id, book, agent)
            delete!(agent.orders, order_id)
        end

        rate = agent.rate
    elseif msg["action"] == "UPDATE_ORDER"
        if get_size(agent.orders[msg["order_id"]]) == 0
            delete!(agent.orders, msg["order_id"])
        end
        return msgs
    else
        throw(error("Unknown action for a Market Maker."))
    end

    # Agent sends new messages
    activation_time_diff = ceil(Int64, rand(Exponential(rate)))
    response = copy(msg)
    response["activation_time"] += activation_time_diff
    push!(msgs, response)

    return msgs
end

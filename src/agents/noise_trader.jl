
import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate NoiseTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::NoiseTrader, book::Book, params::Dict)
    mrkt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
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
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::NoiseTrader, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)  # TODO: agents are useless for noise traders, but might be useful for other traders.
    # initialise new messages
    msgs = Vector{Dict}()
    
    # agent trades
    if msg["action"] == "MARKET_ORDER"
        simulation["last_id"] += 1
        order = create_mkt_order(agent, book.symbol, simulation["last_id"])
        if params["save_orders"]
            save_order!(simulation, order, agent)
        end
        matched_orders = add_order!(book, order)
        # TODO:
        # - Maybe trades should go straight to simulation["trades"]?
        #   - This way we would not have to keep them in book and safe some memory?
        # - Do we use book.trades for anything else then simulation outcome?
        #   - We could potentiallly if some agents would react on trades?
        add_trades!(book, matched_orders)
        append!(msgs, messages_from_match(matched_orders, book))

        rate = agent.market_rate
    elseif msg["action"] == "LIMIT_ORDER"
        price = mid_price(book) + randn() * agent.sigma  # TODO: maybe we should add rounding to ticks?
        if isnan(price)
            price = params["fundamental_price"]  # TODO: this may depend on time
        end
        simulation["last_id"] += 1
        order = create_lmt_order(agent, book.symbol, simulation["last_id"], price)
        if params["save_orders"]
            save_order!(simulation, order, agent)
        end
        matched_orders = add_order!(book, order)
        add_trades!(book, matched_orders)
        append!(msgs, messages_from_match(matched_orders, book))
        if get_size(order) > 0
            agent.orders[order.id] = order
        end

        rate = agent.limit_rate
    elseif msg["action"] == "CANCEL_ORDER"
        if !isempty(agent.orders)
            # TODO: Here is where we could report cancelations to simulation outcome!
            order_id = rand(keys(agent.orders))
            if params["save_cancelattions"]
                save_cancel!(simulation, order_id, agent)
            end
            cancel_order!(order_id, book, agent)
        end

        rate = agent.cancel_rate
    elseif msg["action"] == "UPDATE_ORDER"
        if msg["order_size"] == 0
            delete!(agent.orders, msg["order_id"])
        end
        return msgs
    else
        throw(error("Unknown action for a Noise Trader."))
    end

    # agent sends next messages
    activation_time_diff = ceil(Int64, rand(Exponential(rate)))
    response = copy(msg)
    response["activation_time"] += activation_time_diff
    push!(msgs, response)

    return msgs
end

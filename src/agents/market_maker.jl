
import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate MarketMaker "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::MarketMaker, book::Book, params::Dict)
    msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    msg["recipient"] = agent.id
    msg["book"] = book.symbol

    msg["activation_time"] = params["initial_time"]
    msg["activation_priority"] = 1
    
    msg["action"] = "LADDER_ORDERS"
    
    msgs = Vector{Dict}()
    push!(msgs, msg)
    return msgs
end

"""
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::MarketMaker, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)
    # initialise new messages
    msgs = Vector{Dict}()
    
    # agent trades
    if msg["action"] == "LADDER_ORDERS"
        # cancel previous ladder
        if !isempty(agent.orders)
            for order_id in keys(agent.orders)
                cancel_order!(order_id, book, agent)
                delete!(agent.orders, order_id)
            end
        end
        # build new ladder
        ask = book.best_ask
        bid = book.best_bid
        if isnan(ask) | isnan(bid)
            ask = params["fundamental_price"] + agent.q
            bid = params["fundamental_price"] - agent.q
        end
        for k in 0:agent.K
            # ask ladder step
            simulation["last_id"] += 1
            order = LimitOrder(ask + k * agent.q, agent.size, false, simulation["last_id"], agent.id, book.symbol)
            matched_orders = add_order!(book, order)
            add_trades!(book, matched_orders)
            if get_size(order) > 0
                agent.orders[order.id] = order
            end
            append!(msgs, messages_from_match(matched_orders, book))
            # bid ladder step
            simulation["last_id"] += 1
            order = LimitOrder(bid - k * agent.q, agent.size, true, simulation["last_id"], agent.id, book.symbol)
            matched_orders = add_order!(book, order)
            add_trades!(book, matched_orders)
            if get_size(order) > 0
                agent.orders[order.id] = order
            end
            append!(msgs, messages_from_match(matched_orders, book))
        end

        # agent sends next ladder message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "UPDATE_ORDER"
        if get_size(agent.orders[msg["order_id"]]) == 0
            delete!(agent.orders, msg["order_id"])
        end
    else
        throw(error("Unknown action for a Market Maker."))
    end
    return msgs
end


import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate NoiseTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::Chartist, book::Book, params::Dict)
    msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    msg["recipient"] = agent.id
    msg["book"] = book.symbol

    msg["activation_time"] = ceil(Int64, params["initial_time"] + agent.horizon +
                                  rand(Exponential(agent.rate)))
    msg["activation_priority"] = 1
    
    msg["action"] = "LIMIT_ORDER"
    
    msgs = Vector{Dict}()
    push!(msgs, msg)
    return msgs
end

"""
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::Chartist, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)
    # initialise new messages
    msgs = Vector{Dict}()
    
    # Agent trades
    if msg["action"] == "LIMIT_ORDER"
        # sending limit order
        current_mid_price = mid_price(book)
        previous_mid_price = simulation["mid_price"][simulation["current_time"]-agent.horizon]
        ret = agent.coeff * (current_mid_price - previous_mid_price) +
              randn() * agent.sigma
        if isnan(ret)
            ret = 0.0  # TODO: Is it correct? This should happen for NaN mid price (empty book)
        end
        expected_price = current_mid_price + ret
        is_bid = (ret < 0.0)

        simulation["last_id"] += 1
        order = LimitOrder(expected_price, 1, is_bid, simulation["last_id"], agent.id, book.symbol)
        # TODO: Should the order size be a parameter? Should it be random?
        matched_orders = add_order!(book, order)
        add_trades!(book, matched_orders)
        if get_size(order) > 0
            agent.orders[order.id] = order
        end
        append!(msgs, messages_from_match(matched_orders, book))

        # cancel inconsistent orders
        for (order_id, o) in agent.orders
            if o.is_bid != is_bid
                cancel_order!(order_id, book, agent)
                delete!(agent.orders, order_id)
            elseif (((o.price > expected_price) && o.is_bid) ||
                    ((o.price < expected_price) && !o.is_bid))
                cancel_order!(order_id, book, agent)
                delete!(agent.orders, order_id)
            end
        end

        # sending expiration message
        expire = Dict{String, Union{String, Int64, Float64, Bool}}()
        expire["recipient"] = agent.id
        expire["book"] = book.symbol
        expire["activation_time"] = simulation["current_time"] + agent.horizon
        expire["activation_priority"] = 1
        expire["action"] = "CANCEL_ORDER"
        expire["order_id"] = order.id
        push!(msgs, expire)

        # agent sends next order message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "CANCEL_ORDER"
        order_id = msg["order_id"]
        if order_id in keys(agent.orders)
            cancel_order!(order_id, book, agent)
            delete!(agent.orders, order_id)
        end
    elseif msg["action"] == "UPDATE_ORDER"
        if get_size(agent.orders[msg["order_id"]]) == 0
            delete!(agent.orders, msg["order_id"])
        end
    else
        throw(error("Unknown action for a Chartist Trader."))
    end
    return msgs
end

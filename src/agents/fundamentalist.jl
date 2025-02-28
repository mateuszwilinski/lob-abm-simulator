
import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate NoiseTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::Fundamentalist, book::Book, params::Dict)
    lmt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    lmt_msg["recipient"] = agent.id
    lmt_msg["book"] = book.symbol

    lmt_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                  rand(Exponential(agent.limit_rate)))
    lmt_msg["activation_priority"] = 1
    lmt_msg["action"] = "LIMIT_ORDER"
    
    mkt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    mkt_msg["recipient"] = agent.id
    mkt_msg["book"] = book.symbol

    mkt_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                  rand(Exponential(agent.market_rate)))
    mkt_msg["activation_priority"] = 1
    mkt_msg["action"] = "MARKET_ORDER"
    
    msgs = Vector{Dict}()
    push!(msgs, mkt_msg)
    push!(msgs, lmt_msg)
    return msgs
end

"""
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::Fundamentalist, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)
    # initialise new messages
    msgs = Vector{Dict}()
    
    # Agent trades
    if msg["action"] == "LIMIT_ORDER"
        # build limit order
        current_mid_price = mid_price(book)
        fundamental_price = params["fundamental_dynamics"][simulation["current_time"]]
        if isnan(current_mid_price)
            current_mid_price = fundamental_price
        end
        ret = agent.coeff * (fundamental_price - current_mid_price) + randn() * agent.sigma
        expected_price = current_mid_price + ret

        is_bid = (ret > 0.0)
        simulation["last_id"] += 1
        order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))

        order = LimitOrder(expected_price, order_size, is_bid, simulation["last_id"], agent.id, book.symbol;
                           tick_size=book.tick_size)

        # cancel inconsistent orders
        cancel_inconsistent_orders!(agent, book, is_bid, params, simulation, expected_price)

        # pass new limit order
        matching_msgs = pass_order!(book, order, agents, simulation, params)
        append!(msgs, matching_msgs)

        # send expiration message
        expire = Dict{String, Union{String, Int64, Float64, Bool}}()
        expire["recipient"] = agent.id
        expire["book"] = book.symbol
        expire["activation_time"] = simulation["current_time"] + agent.horizon
        expire["activation_priority"] = 1
        expire["action"] = "CANCEL_ORDER"
        expire["order_id"] = order.id
        push!(msgs, expire)

        # agent sends next order message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.limit_rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "MARKET_ORDER"
        # sending market order
        current_mid_price = mid_price(book)
        fundamental_price = params["fundamental_dynamics"][simulation["current_time"]]
        ret = agent.coeff * (fundamental_price - current_mid_price) + randn() * agent.sigma

        if (book.best_ask - book.best_bid - 2.0 * abs(ret)) < 0.0
            # prepare market order
            is_bid = (ret > 0.0)
            simulation["last_id"] += 1
            order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))

            order = MarketOrder(order_size, is_bid, simulation["last_id"], agent.id, book.symbol)

            # cancel inconsistent orders
            cancel_inconsistent_orders!(agent, book, is_bid, params, simulation)

            # match new market order
            matching_msgs = pass_order!(book, order, agents, simulation, params)
            append!(msgs, matching_msgs)
        end  # TODO: should we cancel inconsistent limit orders in this case?

        # agent sends next order message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.market_rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "CANCEL_ORDER"
        order_id = msg["order_id"]
        if order_id in keys(agent.orders)
            order = agent.orders[order_id]
            cancel_order!(order, book, agent, simulation, params)
        end
    elseif msg["action"] == "UPDATE_ORDER"
        nothing
    else
        throw(error("Unknown action for a Fundamental Trader."))
    end
    return msgs
end

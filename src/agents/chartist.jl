
import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate NoiseTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::Chartist, book::Book, params::Dict)
    lmt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    lmt_msg["recipient"] = agent.id
    lmt_msg["book"] = book.symbol

    lmt_msg["activation_time"] = ceil(Int64, params["initial_time"] + agent.horizon +
                                  rand(Exponential(agent.limit_rate)))
    lmt_msg["activation_priority"] = 1
    lmt_msg["action"] = "LIMIT_ORDER"
    
    mkt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    mkt_msg["recipient"] = agent.id
    mkt_msg["book"] = book.symbol

    mkt_msg["activation_time"] = ceil(Int64, params["initial_time"] + agent.horizon +
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
function action!(agent::Chartist, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)
    # initialise new messages
    msgs = Vector{Dict}()
    
    # Agent trades
    if msg["action"] == "LIMIT_ORDER"
        # prepare limit order
        current_mid_price = mid_price(book)
        previous_mid_price = simulation["mid_price"][simulation["current_time"]-agent.horizon]

        expected_price = predict_price(
            current_mid_price,
            previous_mid_price,
            params["fundamental_price"],
            agent.coeff,
            agent.sigma
            )

        is_bid = (expected_price > current_mid_price)  # TODO: what to do when ret = 0.0 ???
        simulation["last_id"] += 1
        order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))

        order = LimitOrder(expected_price, order_size, is_bid, simulation["last_id"], agent.id, book.symbol;
                           tick_size=book.tick_size)

        # cancel inconsistent orders
        cancel_inconsistent_orders!(agent, book, is_bid, params["save_events"], simulation, expected_price)

        # pass new limit order to the book
        matching_msgs = pass_order!(book, order, agent, simulation, params["save_events"])
        append!(msgs, matching_msgs)

        # sending expiration message
        expiration_time = simulation["current_time"] + agent.horizon
        push!(msgs, expire_msg(agent.id, order.id, expiration_time, book.symbol))

        # prepare next order message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.limit_rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "MARKET_ORDER"
        # sending market order
        current_mid_price = mid_price(book)
        previous_mid_price = simulation["mid_price"][simulation["current_time"]-agent.horizon]
        ret = agent.coeff * (current_mid_price - previous_mid_price) + randn() * agent.sigma

        if (book.best_ask - book.best_bid - 2.0 * abs(ret)) < 0.0
            # prepare market order
            is_bid = (ret > 0.0)
            simulation["last_id"] += 1
            order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))

            order = MarketOrder(order_size, is_bid, simulation["last_id"], agent.id, book.symbol)

            # cancel inconsistent orders
            cancel_inconsistent_orders!(agent, book, is_bid, params["save_events"], simulation)

            # match new market order
            matching_msgs = pass_order!(book, order, agent, simulation, params["save_events"])
            append!(msgs, matching_msgs)
        end

        # prepare next order message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.market_rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "CANCEL_ORDER"
        order_id = msg["order_id"]
        if order_id in keys(agent.orders)
            cancel_order!(order_id, book, agent, simulation, params["save_events"])
        end
    elseif msg["action"] == "UPDATE_ORDER"
        if msg["order_size"] == 0
            delete!(agent.orders, msg["order_id"])
        end
    else
        throw(error("Unknown action for a Chartist Trader."))
    end
    return msgs
end

"""
    predict_price(current_mid_price, previous_mid_price, fundamental_price, coeff, sigma)

Predict future price using the chartist model.
"""
function predict_price(current_mid_price::F, previous_mid_price::F, fundamental_price::F, coeff::F, sigma::F) where {F <: Real}
    if isnan(current_mid_price) | isnan(previous_mid_price)
        ret = randn() * sigma
        expected_price = params["fundamental_price"] + ret
    else
        ret = coeff * (current_mid_price - previous_mid_price) + randn() * sigma
        expected_price = current_mid_price + ret
    end
    return expected_price
end

"""
    expire_msg(agent_id, order_id, time, symbol)

Create a message order expiration.
"""
function expire_msg(agent_id::T, order_id::T, time::T, symbol::String) where {T <: Integer}
    expire = Dict{String, Union{String, Int64, Float64, Bool}}()
    expire["recipient"] = agent_id
    expire["book"] = symbol
    expire["activation_time"] = time
    expire["activation_priority"] = 1
    expire["action"] = "CANCEL_ORDER"
    expire["order_id"] = order_id
    return expire
end

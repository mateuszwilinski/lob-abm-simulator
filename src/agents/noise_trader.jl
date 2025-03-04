
import Distributions: Exponential

"""
    NoiseTrader(id, limit_rate, market_rate, cancel_rate, sigma, size, size_sigma)

Create a Noise Trader agent with given parameters and an empty dictionary of orders.
"""
function NoiseTrader(
    id::T,
    limit_rate::F,
    market_rate::F,
    cancel_rate::F,
    sigma::F,
    size::T,
    size_sigma::F
    ) where {T <: Integer, F <: Real}
    return NoiseTrader(
        id,
        Dict{Integer, LimitOrder}(),
        limit_rate,
        market_rate,
        cancel_rate,
        sigma,
        size,
        size_sigma
        )
end

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
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::NoiseTrader, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)
    # initialise new messages
    msgs = Vector{Dict}()
    
    # agent trades
    if msg["action"] == "MARKET_ORDER"
        simulation["last_id"] += 1
        order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))
        order = MarketOrder(order_size, rand(Bool), simulation["last_id"], agent.id, book.symbol)
        matching_msgs = pass_order!(book, order, agents, simulation, params)
        append!(msgs, matching_msgs)

        rate = agent.market_rate
    elseif msg["action"] == "LIMIT_ORDER"
        price = mid_price(book)
        if isnan(price)
            price = params["fundamental_dynamics"][simulation["current_time"]]
        end
        price += randn() * agent.sigma
        simulation["last_id"] += 1
        order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))
        order = LimitOrder(price, order_size, rand(Bool), simulation["last_id"], agent.id, book.symbol;
                           tick_size=book.tick_size)
        matching_msgs = pass_order!(book, order, agents, simulation, params)
        append!(msgs, matching_msgs)

        rate = agent.limit_rate
    elseif msg["action"] == "CANCEL_ORDER"
        if !isempty(agent.orders)
            order_id = rand(keys(agent.orders))
            order = agent.orders[order_id]
            cancel_order!(order, book, agent, simulation, params)
        end

        rate = agent.cancel_rate
    elseif msg["action"] == "UPDATE_ORDER"
        # that is the only case when noise trades dpes not send new message
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

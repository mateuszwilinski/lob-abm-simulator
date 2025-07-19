
import Distributions: Exponential

"""
    NetTrader(id, limit_rate, market_rate, cancel_rate, sigma, size, size_sigma)

Create a Net Trader agent with given parameters and both empty dictionary of orders
and empty vector of neighbors.
"""
function NetTrader(
    id::T,
    info_rate::F,
    limit_rate::F,
    market_rate::F,
    cancel_rate::F,
    sigma::F,
    size::T,
    size_sigma::F
    ) where {T <: Integer, F <: Real}
    return NetTrader(
        id,
        Dict{Integer, LimitOrder}(),
        Vector{Tuple}(),
        info_rate,
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

Initiate NetTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::NetTrader, book::Book, params::Dict)
    mrkt_msg = Dict{String, Union{String, Int64, Float64, Bool, Nothing}}()  # TODO: think about types
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
    
    mrkt_msg["info"] = nothing
    lmt_msg["info"] = nothing
    
    msgs = Vector{Dict}()
    append!(msgs, [mrkt_msg, lmt_msg, cncl_msg])
    return msgs
end

"""
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::NetTrader, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)
    # initialise new messages
    msgs = Vector{Dict}()
    
    # agent trades
    if msg["action"] == "MARKET_ORDER"
        simulation["last_id"] += 1
        order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))
        if isnothing(msg["info"])
            order = MarketOrder(order_size, rand(Bool), simulation["last_id"], agent.id, book.symbol)
            push!(msgs, self_msg(msg, agent.market_rate))
            msg["is_bid"] = order.is_bid
        else
            order = MarketOrder(order_size, msg["is_bid"], simulation["last_id"], agent.id, book.symbol)
        end
        append!(msgs, msgs_to_neigbors(agent, msg))

        matching_msgs = pass_order!(book, order, agents, simulation, params)
        append!(msgs, matching_msgs)
    elseif msg["action"] == "LIMIT_ORDER"
        simulation["last_id"] += 1
        price = mid_price(book)
        if isnan(price)
            price = params["fundamental_dynamics"][simulation["current_time"]]
        end
        price += randn() * agent.sigma
        order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))
        if isnothing(msg["info"])  # TODO: if the side is known, it should affect the price
            order = LimitOrder(price, order_size, rand(Bool), simulation["last_id"], agent.id, book.symbol;
                               tick_size=book.tick_size)
            push!(msgs, self_msg(msg, agent.limit_rate))
            msg["is_bid"] = order.is_bid
        else
            order = LimitOrder(price, order_size, msg["is_bid"], simulation["last_id"], agent.id, book.symbol;
                               tick_size=book.tick_size)
        end
        append!(msgs, msgs_to_neigbors(agent, msg))

        matching_msgs = pass_order!(book, order, agents, simulation, params)
        append!(msgs, matching_msgs)
    elseif msg["action"] == "CANCEL_ORDER"
        if !isempty(agent.orders)
            order_id = rand(keys(agent.orders))
            order = agent.orders[order_id]
            cancel_order!(order, book, agent, simulation, params)
        end
        push!(msgs, self_msg(msg, agent.cancel_rate))
    elseif msg["action"] == "UPDATE_ORDER"
        # that is the only case when net trader does not send a new message
    else
        throw(error("Unknown action for a Net Trader."))
    end
    return msgs
end

"""
    msgs_to_neigbors(agent, msg)

Send messages to neighbors of the agent, propagating his actions.
"""
function msgs_to_neigbors(agent::NetTrader, msg::Dict)
    msgs = Vector{Dict}()
    if msg["action"] in ["MARKET_ORDER", "LIMIT_ORDER"]
        for (i, w) in agent.neighbors
            if (rand() < w) & (msg["info"] != i)
                response = copy(msg)
                activation_time_diff = ceil(Int64, rand(Exponential(agent.info_rate)))
                response["recipient"] = i
                response["activation_time"] += activation_time_diff
                response["info"] = agent.id
                response["activation_priority"] = rand(2:2000000000000)
                push!(msgs, response)
            end
        end
    end
    return msgs
end

"""
    self_msg(msg, rate)

Create a new message for the agent himself.
"""
function self_msg(msg::Dict, rate::Real)
    response = copy(msg)
    activation_time_diff = ceil(Int64, rand(Exponential(rate)))
    response["activation_time"] += activation_time_diff
    return response
end

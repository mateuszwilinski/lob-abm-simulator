import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate SentimentalistTrader "agent" on the "book", for simulation with "params".
"""

function initiate!(agent::Sentimentalist, book:Book, params::Dict)
    mrkt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    mrkt_msg["recipient"] = agent.id
    mrkt_msg["book"] = book.symbol

    mrkt_msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                       rand(Exponential(agent.market_rate)))
    
end

"""
    create_mkt_order(agent, symbol, order_id)

Create new market order with "order_id" for "agent" and "symbol".
"""

function create_mkt_order(agent::Sentimentalist, symbol::String, order_id::Int64)

    order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))
    #TODO: How to link sentiment with the size and frequency of orders
    id_bid = agent.sentiment < 0

    return MarketOrder(order_size, id_bid, order_id, agent.id, symbol)
end

function action!(agent::Sentimentalist, book::Book, agents::Dict{Int64, Agent}, params::Dict, simulation::Dict, msg::Dict)
    #initialise new messages
    msgs = Vector{Dict}()

        # agent trades
    if msg["action"] == "MARKET_ORDER"
        order = create_mkt_order(agent, msg["book"], msg["order_id"])
        if params["save_orders"]
            save_order!(simulation, order, agent)
        end
        matched_orders = add_order!(book, order)

        add_trades!(book, matched_orders)
        append!(msgs, messages_from_match(matched_orders, book))

    else
        throw(error("Unknown action for Sentimentalist: $(msg["action"])"))
    end

    # agent sends next messages
    activation_time_diff = ceil(Int64, rand(Exponential(agent.market_rate)))
    response = copy(msg)
    response["activation_time"] += activation_time_diff
    push!(msgs, response)

    return msgs
end

import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate MarketTaker "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::MarketTaker, book::Book, params::Dict)
    msg = Dict{String, Union{String, Int64, Float64}}()
    msg["recipient"] = agent.id
    msg["book"] = book.symbol

    msg["activation_time"] = ceil(Int64, params["initial_time"] +
                                  rand(Exponential(agent.rate)))
    msg["activation_priority"] = 1
    
    msg["action"] = "BIG_ORDER"
    
    msgs = Vector{Dict}()
    push!(msgs, msg)
    return msgs
end

"""
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::MarketTaker, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)  # TODO: params are useless here, but are useful for other agents and consistency.
    # initialise new messages
    msgs = Vector{Dict}()
    
    # agent trades
    if msg["action"] == "BIG_ORDER"
        # smaller market orders
        is_bid = rand(Bool)
        K = floor(Int64, agent.size / agent.chunk)
        for k in 1:K
            mrkt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
            mrkt_msg["recipient"] = agent.id
            mrkt_msg["book"] = book.symbol
            mrkt_msg["activation_time"] = msg["activation_time"] + k * agent.exit_time
            mrkt_msg["activation_priority"] = 1
            mrkt_msg["action"] = "MARKET_ORDER"

            mrkt_msg["chunk"] = agent.chunk
            mrkt_msg["is_bid"] = is_bid

            push!(msgs, mrkt_msg)
        end
        last_chunk = agent.size - K * agent.chunk
        if last_chunk > 0
            mrkt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
            mrkt_msg["recipient"] = agent.id
            mrkt_msg["book"] = book.symbol
            mrkt_msg["activation_time"] = msg["activation_time"] + (K+1) * agent.exit_time
            mrkt_msg["activation_priority"] = 1
            mrkt_msg["action"] = "MARKET_ORDER"

            mrkt_msg["chunk"] = last_chunk
            mrkt_msg["is_bid"] = is_bid
            
            push!(msgs, [mrkt_msg])
        end

        # next big order
        activation_time_diff = ceil(Int64, K * agent.exit_time + rand(Exponential(agent.rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "MARKET_ORDER"
        simulation["last_id"] += 1
        order = MarketOrder(msg["chunk"], msg["is_bid"], simulation["last_id"], agent.id, book.symbol)
        matched_orders = add_order!(book, order)
        add_trades!(book, matched_orders)
        append!(msgs, messages_from_match(matched_orders, book))
    else
        throw(error("Unknown action for a Market Taker."))  # TODO: Maybe we should add the specific action here?
    end
    return msgs
end

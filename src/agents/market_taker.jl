
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
    action!(agent, book, agents, params, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::MarketTaker, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, msg::Dict)  # TODO: agents are useless for noise traders, but might be useful for other traders.
    # Initialise new messages
    msgs = Vector{Dict}()
    
    # Agent trades
    if msg["action"] == "BIG_ORDER"
        # Smaller market orders
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

        # Another big order
        activation_time_diff = K * agent.exit_time + ceil(Int64, rand(Exponential(agent.rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "MARKET_ORDER"
        params["last_id"] += 1
        order = MarketOrder(msg["chunk"], msg["is_bid"], params["last_id"], agent.id, book.symbol)
        matched_orders = add_order!(book, order)
        append!(msgs, messages_from_match(matched_orders, book))
    else
        throw(error("Unknown action for a Market Taker."))  # TODO: Maybe we should add the specific action here?
    end
    return msgs
end

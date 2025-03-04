
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
        is_bid = rand(Bool)  # TODO: maybe this should be done at the message creation?
        order_time = 0
        chunk_sum = 0
        while chunk_sum < agent.size
            order_time += round(Int64, max(1, randn()*agent.time_sigma + agent.exit_time))
            chunk_activation_time = msg["activation_time"] + order_time

            chunk_size = round(Int64, max(1, randn()*agent.chunk_sigma + agent.chunk))
            chunk_size = min(agent.size - chunk_sum, chunk_size)
            chunk_sum += chunk_size

            chunk_msg = create_next_chunk_msgs(agent.id, book.symbol, is_bid, chunk_activation_time, chunk_size)
            push!(msgs, chunk_msg)
        end

        # next big order
        activation_time_diff = ceil(Int64, order_time + rand(Exponential(agent.rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "MARKET_ORDER"
        simulation["last_id"] += 1
        order = MarketOrder(msg["chunk"], msg["is_bid"], simulation["last_id"], agent.id, book.symbol)
        matching_msgs = pass_order!(book, order, agents, simulation, params)
        append!(msgs, matching_msgs)
    else
        throw(error("Unknown action for a Market Taker."))  # TODO: Maybe we should add the specific action here?
    end
    return msgs
end

"""
    create_next_chunk_msgs(agent_id, symbol, is_bid, chunk_activation_time, chunk_size)

Create a message for the next chunk of a big order.
"""
function create_next_chunk_msgs(
                        agent_id::T,
                        symbol::String,
                        is_bid::Bool,
                        chunk_activation_time::T,
                        chunk_size::T
                        ) where {T <: Integer}
    msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    msg["recipient"] = agent_id
    msg["book"] = symbol
    msg["activation_priority"] = 1
    msg["action"] = "MARKET_ORDER"
    msg["is_bid"] = is_bid
    msg["activation_time"] = chunk_activation_time
    msg["chunk"] = chunk_size

    return msg
end

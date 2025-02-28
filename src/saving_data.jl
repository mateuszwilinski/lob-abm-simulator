
using CSV

# Custom struct for event data
struct Event{T <: Int, F <: Float64}
    time::T
    type::T
    order_id::T
    size::T
    price::F
    direction::T  # -1 for buy, 1 for sell
    agent_id::T
end

function Event(
    time::T,
    type::T,
    order_id::T,
    size::T,
    price::F,
    is_bid::Bool,
    agent_id::T
    ) where {T <: Int, F <: Float64}
    direction = is_bid ? -1 : 1
    return Event(time, type, order_id, size, price, direction, agent_id)
end

"""
    save_order!(simulation, order)

Save a given market order to the simulation structure.
"""
function save_order!(simulation::Dict, order::MarketOrder)
    push!(simulation["events"],
          Event(
            simulation["current_time"],
            0,  # 0 for market order
            order.id,
            order.size[],
            NaN,
            order.is_bid,  # TODO: change this to -1 for buy, 1 for sell
            order.agent
            ))
end

"""
    save_order!(simulation, order)

Save a given limit order to the simulation structure.
"""
function save_order!(simulation::Dict, order::LimitOrder)
    push!(simulation["events"],
          Event(
            simulation["current_time"],
            1,  # 1 for limit order
            order.id,
            order.size[],
            order.price,
            order.is_bid,
            order.agent
            ))
end

"""
    save_cancel!(simulation, order)

Save a given order cancellation to the simulation structure.
"""
function save_cancel!(simulation::Dict, order::LimitOrder)
    push!(simulation["events"],
          Event(
            simulation["current_time"],
            3,  # 3 for full order cancellation
            order.id,
            order.size[],
            order.price,
            order.is_bid,
            order.agent,
            ))
end

"""
    save_modify!(simulation, order, agent)

Save a given order modification to the simulation structure.
"""
function save_modify!(simulation::Dict, order::LimitOrder)
    push!(simulation["events"],
          Event(
            simulation["current_time"],
            2,  # 2 for order size modification
            order.id,
            order.size[],
            order.price,
            order.is_bid,
            order.agent,
            ))
end

"""
    save_events_to_csv(events, filename)

Save events to a CSV file.
"""
function save_events_to_csv(events::Vector{Event}, filename::String)
    open(filename, "w") do io
        # Write each order directly
        for event in events
            println(io, string(
                "$(event.time),",
                "$(event.type),",
                "$(event.order_id),",
                "$(event.size),",
                "$(event.price),",
                "$(event.direction),",
                "$(event.agent_id)"
            ))
        end
    end
end

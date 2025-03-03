
using CSV

# Custom struct for event data
struct Event{T <: Integer, F <: Real}
    time::T
    type::T  # 0 = market, 1 = limit, 2 = modification, 3 = cancellation, 4 = execution
    order_id::T
    size::T
    price::F
    direction::T  # -1 for buy, 1 for sell
    agent_id::T
    cross_order::T
    cross_agent::T
end

# Construct Event for executions
function Event(
    time::T,
    type::T,
    order_id::T,
    size::T,
    price::F,
    is_bid::Bool,
    agent_id::T,
    cross_order::T,
    cross_agent::T
    ) where {T <: Integer, F <: Real}
    direction = is_bid ? -1 : 1
    return Event(
        time,
        type,
        order_id,
        size,
        price,
        direction,
        agent_id,
        cross_order,
        cross_agent
        )
end

# Construct Event for non-executions
function Event(
    time::T,
    type::T,
    order_id::T,
    size::T,
    price::F,
    is_bid::Bool,
    agent_id::T
    ) where {T <: Int, F <: Real}
    direction = is_bid ? -1 : 1
    return Event(time, type, order_id, size, price, direction, agent_id, -1, -1)
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
            get_size(order),
            NaN,
            order.is_bid,
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
            get_size(order),
            order.price,
            order.is_bid,
            order.agent
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
            get_size(order),
            order.price,
            order.is_bid,
            order.agent,
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
            get_size(order),
            order.price,
            order.is_bid,
            order.agent,
            ))
end

"""
    save_snapshot!(simulation, snapshot)

Save a given snapshot to the simulation structure.
"""
function save_snapshot!(simulation::Dict, snapshot::Snapshot)
    push!(simulation["snapshots"], snapshot)
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
                "$(event.agent_id),",
                "$(event.cross_order),",
                "$(event.cross_agent)"
            ))
        end
    end
end

"""
    save_snapshots_to_csv(snapshots, filename)

Save snapshots to a CSV file.
"""
function save_snapshots_to_csv(snapshots::Vector{Snapshot}, filename::String)
    open(filename, "w") do io
        # Write each order directly
        for s in snapshots
            snapshot_strings = String[]
            for i in 1:5
                push!(
                    snapshot_strings,
                    string(
                        "$(s.ask_prices[i]),",
                        "$(s.ask_volumes[i]),",
                        "$(s.bid_prices[i]),",
                        "$(s.bid_volumes[i])",
                        i == 5 ? "" : ","  # Add comma if not the last element
                        )
                    )
            end
            println(io, snapshot_strings...)
        end
    end
end

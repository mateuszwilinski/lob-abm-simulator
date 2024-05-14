
"""
    save_order!(simulation, order, agent)

Save a given market order to the simulation structure.
"""
function save_order!(simulation::Dict, order::MarketOrder, agent::Agent)
    push!(simulation["orders"],
          Int64[
            order.id,
            agent.id,
            simulation["current_time"],
            order.size[],
            Int64(order.is_bid),
            0,
            0
            ])
end

"""
    save_order!(simulation, order, agent)

Save a given limit order to the simulation structure.
"""
function save_order!(simulation::Dict, order::LimitOrder, agent::Agent)
    push!(simulation["orders"],
          Union{Int64, Float64}[
            order.id,
            agent.id,
            simulation["current_time"],
            order.size[],
            Int64(order.is_bid),
            order.price,
            1
            ])
end

"""
    save_cancel!(simulation, order, agent)

Save a given order cancellation to the simulation structure.
"""
function save_cancel!(simulation::Dict, order_id::Int64, agent::Agent)
    push!(simulation["cancellations"],
          Int64[
            order_id,
            agent.id,
            simulation["current_time"]
            ])
end

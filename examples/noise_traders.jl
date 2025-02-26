
using DelimitedFiles

include("../src/orders.jl")
include("../src/books.jl")
include("../src/agents.jl")
include("../src/saving_data.jl")
include("../src/agents/noise_trader.jl")
include("../src/handling_order.jl")
include("../src/changing_order.jl")
include("../src/market_state.jl")
include("../src/simulation.jl")

"""
    main()

Build and run simulation with noise agents.
"""
function main()
    # Command line parameters
    N = try parse(Int64, ARGS[1]) catch e 10 end  # number of agents
    end_time = try parse(Int64, ARGS[2]) catch e 20 end  # simulation length

    # Simulation parameters
    params = Dict()
    params["end_time"] = end_time
    params["initial_time"] = 1
    params["fundamental_price"] = 10.0
    params["snapshots"] = false
    params["save_orders"] = false
    params["save_cancelattions"] = false

    # Build agents
    limit_rate = 0.6
    market_rate = 4.0
    cancel_rate = 8.0
    sigma = 0.2
    agents = Dict{Int64, Agent}()
    # agents[1] = Trader(1, Dict{Int64, LimitOrder}())  # TODO: make a separate agent for initial orders
    for i in 1:N
        agents[i] = NoiseTrader(
                            i,
                            Dict{Int64, LimitOrder}(),
                            limit_rate,
                            market_rate,
                            cancel_rate,
                            sigma,
                            1,
                            0.0
                            )
    end

    # Build starting orders
    asks = Dict{Float64, OrderedSet}()
    asks[11.0] = OrderedSet()
    push!(asks[11.0], LimitOrder(11.0, 1, false, 1, 1, "ABC"))
    agents[1].orders[asks[11.0][1].id] = asks[11.0][1]
    push!(asks[11.0], LimitOrder(11.0, 2, false, 2, 1, "ABC"))
    agents[1].orders[asks[11.0][2].id] = asks[11.0][2]
    push!(asks[11.0], LimitOrder(11.0, 1, false, 3, 1, "ABC"))
    agents[1].orders[asks[11.0][3].id] = asks[11.0][3]
    
    bids = Dict{Float64, OrderedSet}()
    bids[10.0] = OrderedSet()
    push!(bids[10.0], LimitOrder(10.0, 1, true, 4, 1, "ABC"))
    agents[1].orders[bids[10.0][1].id] = bids[10.0][1]
    push!(bids[10.0], LimitOrder(10.0, 1, true, 5, 1, "ABC"))
    agents[1].orders[bids[10.0][2].id] = bids[10.0][2]
    push!(bids[10.0], LimitOrder(10.0, 2, true, 6, 1, "ABC"))
    agents[1].orders[bids[10.0][3].id] = bids[10.0][3]

    # Initiate Book
    book = Book(
        Dict{Float64, OrderedSet}(),
        Dict{Float64, OrderedSet}(),
        NaN,
        NaN,
        params["initial_time"],
        "ABC",
        Vector{Trade}()
    )
    
    book.bids = bids
    book.asks = asks
    update_best_bid!(book)
    update_best_ask!(book)

    params["first_id"] = 6

    # Run simulation
    messages = PriorityQueue()  # TODO: Add correct types
    simulation_outcome = run_simulation(agents, book, messages, params)
    println(simulation_outcome)
end

main()

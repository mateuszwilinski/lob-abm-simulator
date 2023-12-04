
include("../src/orders.jl")
include("../src/agents.jl")
include("../src/books.jl")
include("../src/trading.jl")
include("../src/matching.jl")
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
    params["initial_time"] = 0
    params["fundamental_price"] = 10.0

    # Build agents
    limit_rate = 1.0
    market_rate = 1000.0
    cancel_rate = 1000.0
    sigma = 0.2
    agents = Dict{Int64, Agent}()
    for i in 1:N
        agents[i] = NoiseTrader(
                            i,
                            OrderedSet{Int64}(),
                            limit_rate,
                            market_rate,
                            cancel_rate,
                            sigma
                            )
    end

    # Build starting orders
    orders = Dict{Int64, LimitOrder}()

    asks = Dict{Float64, OrderedSet}()
    asks[11.0] = OrderedSet()
    push!(asks[11.0], LimitOrder(11.0, 2, false, 1, 1, "ABC"))
    orders[asks[11.0][1].id] = asks[11.0][1]
    push!(asks[11.0], LimitOrder(11.0, 4, false, 2, 2, "ABC"))
    orders[asks[11.0][2].id] = asks[11.0][2]
    push!(asks[11.0], LimitOrder(11.0, 3, false, 3, 1, "ABC"))
    orders[asks[11.0][3].id] = asks[11.0][3]
    
    bids = Dict{Float64, OrderedSet}()
    bids[10.0] = OrderedSet()
    push!(bids[10.0], LimitOrder(10.0, 2, true, 4, 3, "ABC"))
    orders[bids[10.0][1].id] = bids[10.0][1]
    push!(bids[10.0], LimitOrder(10.0, 2, true, 5, 4, "ABC"))
    orders[bids[10.0][2].id] = bids[10.0][2]
    push!(bids[10.0], LimitOrder(10.0, 5, true, 6, 5, "ABC"))
    orders[bids[10.0][3].id] = bids[10.0][3]

    # Initiate Book
    book = Book(
        Dict{Float64, OrderedSet}(),
        Dict{Float64, OrderedSet}(),
        NaN,
        NaN,
        params["initial_time"],
        "ABC"
    )
    
    book.bids = bids
    book.asks = asks
    update_best_bid!(book)
    update_best_ask!(book)

    params["ord_id"] = 6

    # Run simulation
    messages = PriorityQueue()  # TODO: Add correct types
    simulation_outcome = run_simulation(agents, book, orders, messages, params)
    println(simulation_outcome)
end

main()

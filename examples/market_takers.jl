
using DelimitedFiles

include("../src/orders.jl")
include("../src/books.jl")
include("../src/agents.jl")
include("../src/agents/noise_trader.jl")
include("../src/agents/market_maker.jl")
include("../src/agents/market_taker.jl")
include("../src/trading.jl")
include("../src/matching.jl")
include("../src/market_state.jl")
include("../src/simulation.jl")

"""
    main()

Build and run simulation with market makers and noise agents.
"""
function main()
    # Command line parameters
    N = try parse(Int64, ARGS[1]) catch e 10 end  # number of agents
    end_time = try parse(Int64, ARGS[2]) catch e 50 end  # simulation length

    # Simulation parameters
    params = Dict()
    params["end_time"] = end_time
    params["initial_time"] = 1  # TODO: Initial time cannot be zero or negative.
    params["fundamental_price"] = 10.0

    # Build agents
    limit_rate = 0.6
    market_rate = 4.0
    cancel_rate = 8.0
    sigma = 0.2

    mm_rate = 2.0
    K = 4
    q = 0.5

    mt_rate = 5.0
    exit_time = 1
    size = 5
    chunk = 1

    mm_rate = 3.0
    agents = Dict{Int64, Agent}()
    # agents[1] = Trader(1, Dict{Int64, LimitOrder}())  # TODO: make a separate agent for initial orders
    for i in 1:N
        agents[i] = NoiseTrader(
                            i,
                            limit_rate,
                            market_rate,
                            cancel_rate,
                            sigma
                            )
    end
    for i in 1:N
        agents[N+i] = MarketMaker(
                            N+i,
                            mm_rate,
                            K,
                            q,
                            1
                            )
    end
    for i in 1:N
        agents[2*N+i] = MarketTaker(
                            2*N+i,
                            mt_rate,
                            exit_time,
                            size,
                            chunk
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
    # for i in keys(simulation_outcome)
    #     writedlm(string("../results/noise/", i, ".txt"), simulation_outcome[i], ";")
    # end
end

main()

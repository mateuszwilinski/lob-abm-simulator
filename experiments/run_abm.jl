
using DelimitedFiles

include("../src/orders.jl")
include("../src/books.jl")
include("../src/agents.jl")
include("../src/agents/noise_trader.jl")
include("../src/agents/market_maker.jl")
include("../src/agents/market_taker.jl")
include("../src/agents/chartist.jl")
include("../src/agents/fundamentalist.jl")
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
    end_time = try parse(Int64, ARGS[1]) catch e 36000 end  # simulation length
    # setting = try parse(Int64, ARGS[2]) catch e 1 end  # simulation setting

    # Simulation parameters
    params = Dict()
    params["end_time"] = end_time
    params["initial_time"] = 1  # TODO: Initial time cannot be zero or negative.
    params["fundamental_price"] = 100.0
    params["snapshots"] = false

    # Agents
    agents = Dict{Int64, Agent}()
    for i in 1:20
        agents[i] = MarketMaker(
            i,
            300.0,
            5,
            0.25,
            5
        )
    end
    for i in 21:40
        agents[i] = MarketMaker(
            i,
            3000.0,
            10,
            0.5,
            5
        )
    end
    for i in 41:60
        agents[i] = MarketMaker(
            i,
            1500.0,
            15,
            0.25,
            5
        )
    end
    
    for i in 61:65
        agents[i] = MarketTaker(
            i,
            3000.0,
            200,
            20.0,
            100,
            5,
            1.5
        )
    end
    for i in 66:70
        agents[i] = MarketTaker(
            i,
            4500.0,
            100,
            20.0,
            400,
            5,
            1.5
        )
    end
    for i in 71:75
        agents[i] = MarketTaker(
            i,
            1500.0,
            300,
            20.0,
            50,
            5,
            1.5
        )
    end
    for i in 76:175
        agents[i] = Fundamentalist(
            i,
            2000.0,
            1000.0,
            2.0,
            0.1,
            1000,
            5,
            1.5
        )
    end
    for i in 176:275
        agents[i] = Fundamentalist(
            i,
            3000.0,
            2000.0,
            1.0,
            0.1,
            2000,
            5,
            1.5
        )
    end
    for i in 276:375
        agents[i] = Fundamentalist(
            i,
            4000.0,
            2000.0,
            0.5,
            0.1,
            4000,
            5,
            1.5
        )
    end
    for i in 376:475
        agents[i] = Fundamentalist(
            i,
            2000.0,
            1000.0,
            1.0,
            0.1,
            4000,
            5,
            1.5
        )
    end
    for i in 476:575
        agents[i] = Chartist(
            i,
            2000.0,
            1000.0,
            1.5,
            0.1,
            1000,
            5,
            1.5
        )
    end
    for i in 576:675
        agents[i] = Chartist(
            i,
            4000.0,
            2000.0,
            1.0,
            0.1,
            4000,
            5,
            1.5
        )
    end
    for i in 676:775
        agents[i] = Chartist(
            i,
            2000.0,
            1000.0,
            -1.5,
            0.1,
            1000,
            5,
            1.5
        )
    end
    for i in 776:875
        agents[i] = Chartist(
            i,
            4000.0,
            2000.0,
            -1.0,
            0.1,
            4000,
            5,
            1.5
        )
    end
    for i in 876:1875
        agents[i] = NoiseTrader(
            i,
            2000.0,
            1000.0,
            6000.0,
            1.5
        )
    end

    # Build starting orders
    asks = Dict{Float64, OrderedSet}()
    asks[101.0] = OrderedSet()
    push!(asks[101.0], LimitOrder(101.0, 15, false, 1, 1000, "ABC"))
    agents[1000].orders[asks[101.0][1].id] = asks[101.0][1]
    push!(asks[101.0], LimitOrder(101.0, 15, false, 2, 1000, "ABC"))
    agents[1000].orders[asks[101.0][2].id] = asks[101.0][2]
    push!(asks[101.0], LimitOrder(101.0, 20, false, 3, 1000, "ABC"))
    agents[1000].orders[asks[101.0][3].id] = asks[101.0][3]
    
    bids = Dict{Float64, OrderedSet}()
    bids[99.0] = OrderedSet()
    push!(bids[99.0], LimitOrder(99.0, 15, true, 4, 1000, "ABC"))
    agents[1000].orders[bids[99.0][1].id] = bids[99.0][1]
    push!(bids[99.0], LimitOrder(99.0, 15, true, 5, 1000, "ABC"))
    agents[1000].orders[bids[99.0][2].id] = bids[99.0][2]
    push!(bids[99.0], LimitOrder(99.0, 20, true, 6, 1000, "ABC"))
    agents[1000].orders[bids[99.0][3].id] = bids[99.0][3]

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
    
    # Save results
    mid_price = zeros(simulation_outcome["current_time"], 2)
    for (i, p) in enumerate(simulation_outcome["mid_price"])
        mid_price[i, 1] = i
        mid_price[i, 2] = p
    end
    writedlm(string("../plots/results/mid_price.csv"), mid_price, ";")
    transactions = zeros(0, 3)
    for (t, v) in simulation_outcome["trades"]
        for pair in v
            transactions = vcat(transactions, [t pair[1] pair[2]])
        end
    end
    writedlm(string("../plots/results/trades.csv"), transactions, ";")
    if params["snapshots"]
        limit_orders = zeros(0, 3)
        for (t, v) in simulation_outcome["snapshots"]
            for i in 1:size(v)[1]
                limit_orders = vcat(limit_orders, [t v[i, 1] v[i, 2]])
            end
        end
        writedlm(string("../plots/results/orders.csv"), limit_orders, ";")
    end
end

main()

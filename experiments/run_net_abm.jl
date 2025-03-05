
using DelimitedFiles
using Statistics
using ArgParse

import Random

include("../src/orders.jl")
include("../src/books.jl")
include("../src/market_state.jl")
include("../src/agents.jl")
include("../src/saving_data.jl")
include("../src/handling_order.jl")
include("../src/changing_order.jl")
include("../src/simulation.jl")
include("configs/net_abm_params.jl")

"""
    function parse_commandline()

Process command line arguments.
"""
function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--seed"
            help = "seed"
            arg_type = Int
            default = 1
        "--experiment"
            help = "experiment"
            arg_type = Int
            default = 1
        "--tick_size"
            help = "price tick size"
            arg_type = Float64
            default = 0.0
        "--save_events", "-s"
            help = "save events?"
            action = :store_true
        "--snapshots", "-p"
            help = "save snapshots? (only with --save_events)"
            action = :store_true
        "--end_time", "-e"
            help = "simulation length"
            arg_type = Int
            default = 360000
        "--agents"
            help = "number of NetTrader agents"
            arg_type = Int
            default = 1000
        "--net"
            help = "file name of the network to use"
            arg_type = String
            default = "erdos_renyi_1000_2500_1"
    end
    return parse_args(s)
end

"""
    main()

Build and run simulation with market makers and noise agents.
"""
function main()
    # Set simulation parameters
    args = parse_commandline()

    experiment = args["experiment"]
    seed = args["seed"]

    params = Dict()

    params["end_time"] = args["end_time"]
    params["snapshots"] = args["snapshots"]
    params["save_events"] = args["save_events"]
    params["tick_size"] = args["tick_size"]
    if params["snapshots"] & !params["save_events"]
        throw(ArgumentError("Snapshots can be saved only with events."))
    end

    params["initial_time"] = 1  # Initial time cannot be zero or negative.
    params["fundamental_price"] = 100.0
    params["fundamental_dynamics"] = repeat([params["fundamental_price"]], params["end_time"])

    # Initiate agents
    agents_counts = [args["agents"]]
    agents = initiate_agents(agents_params, agents_counts, agents_names)
    n_agents = sum(values(agents_counts))
    agents_net = read_network(string("../data/nets/", args["net"], ".csv"))
    connect_agents!(agents, agents_net)
    for i in 1:20
        println(agents[i].neighbors)
    end

    # Build starting orders
    asks = Dict{Float64, OrderedSet}()
    asks[101.0] = OrderedSet()
    push!(asks[101.0], LimitOrder(101.0, 15, false, 1, 10, "ABC"))
    agents[10].orders[asks[101.0][1].id] = asks[101.0][1]
    push!(asks[101.0], LimitOrder(101.0, 15, false, 2, 10, "ABC"))
    agents[10].orders[asks[101.0][2].id] = asks[101.0][2]
    push!(asks[101.0], LimitOrder(101.0, 20, false, 3, 10, "ABC"))
    agents[10].orders[asks[101.0][3].id] = asks[101.0][3]
    
    bids = Dict{Float64, OrderedSet}()
    bids[99.0] = OrderedSet()
    push!(bids[99.0], LimitOrder(99.0, 15, true, 4, 10, "ABC"))
    agents[10].orders[bids[99.0][1].id] = bids[99.0][1]
    push!(bids[99.0], LimitOrder(99.0, 15, true, 5, 10, "ABC"))
    agents[10].orders[bids[99.0][2].id] = bids[99.0][2]
    push!(bids[99.0], LimitOrder(99.0, 20, true, 6, 10, "ABC"))
    agents[10].orders[bids[99.0][3].id] = bids[99.0][3]

    # Initiate order book
    book = Book(
        Dict{Float64, OrderedSet{LimitOrder}}(),
        Dict{Float64, OrderedSet{LimitOrder}}(),
        NaN,
        NaN,
        "ABC",
        params["tick_size"]
    )
    
    book.bids = bids
    book.asks = asks
    update_best_bid!(book)
    update_best_ask!(book)

    params["first_id"] = 6

    # Run simulation
    Random.seed!(seed)
    messages = PriorityQueue()  # TODO: Add correct types
    simulation_outcome = run_simulation(agents, book, messages, params)
    
    # Save results
    mid_price = zeros(simulation_outcome["current_time"])
    for k in keys(simulation_outcome["mid_price"])
        mid_price[k] = simulation_outcome["mid_price"][k]
    end
    writedlm(string("../results/mid_net_", seed, "_", experiment, ".csv"), mid_price, ";")
    if params["snapshots"]
        filename = string("../results/snapshots_net_", seed, "_", experiment, ".csv")
        save_snapshots_to_csv(simulation_outcome["snapshots"], filename)
    end
    if params["save_events"]
        filename = string("../results/events_net_", seed, "_", experiment, ".csv")
        save_events_to_csv(simulation_outcome["events"], filename)
    end
    println(mid_price[1:1:10])
    # println(mid_price)
end

main()

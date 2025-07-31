
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
            help = "random seed"
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
        "--levels"
            help = "number of levels in the order book"
            arg_type = Int
            default = 5
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
            default = "erdos_renyi_1000_4000_1"
        "--dir"
            help = "directory to save results"
            arg_type = String
            default = "../results/"
        "--setting"
            help = "agents parameters setting"
            arg_type = String
            default = "default"
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
    params["levels"] = args["levels"]
    params["save_events"] = args["save_events"]
    params["tick_size"] = args["tick_size"]
    if params["snapshots"] & !params["save_events"]
        throw(ArgumentError("Snapshots can be saved only with events."))
    end

    params["initial_time"] = 1  # Initial time cannot be zero or negative.
    params["fundamental_price"] = 100.0
    params["fundamental_dynamics"] = repeat([params["fundamental_price"]], params["end_time"])
    params["init_volume"] = 100
    params["init_book_sigma"] = 4.0

    # Initiate agents
    agents_counts = [args["agents"]]
    agents_names = collect(keys(agents_params[args["setting"]]))
    agents = initiate_agents(agents_params[args["setting"]], agents_counts, agents_names)
    n_agents = sum(values(agents_counts))
    agents_net = read_network(string("../data/nets/", args["net"], ".csv"))
    connect_agents!(agents, agents_net)

    # Initiate order book
    Random.seed!(seed)
    book = Book(
        Dict{Float64, OrderedSet{LimitOrder}}(),
        Dict{Float64, OrderedSet{LimitOrder}}(),
        NaN,
        NaN,
        "ABC",
        params["tick_size"]
    )
    
    fill_book!(book, agents, params)
    params["first_id"] = params["init_volume"] + 1

    # Run simulation
    messages = PriorityQueue()  # TODO: Add correct types
    simulation_outcome = run_simulation(agents, book, messages, params)
    
    # Save results
    mid_price = zeros(simulation_outcome["current_time"])
    for k in keys(simulation_outcome["mid_price"])
        mid_price[k] = simulation_outcome["mid_price"][k]
    end
    writedlm(string(args["dir"], "mid_net_", seed, "_", experiment, ".csv"), mid_price, ";")
    if params["snapshots"]
        filename = string(args["dir"], "snapshots_net_", seed, "_", experiment, ".csv")
        save_snapshots_to_csv(simulation_outcome["snapshots"], filename)
    end
    if params["save_events"]
        filename = string(args["dir"], "events_net_", seed, "_", experiment, ".csv")
        save_events_to_csv(simulation_outcome["events"], filename)
    end
end

main()

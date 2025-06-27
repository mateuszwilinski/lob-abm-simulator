
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
include("configs/simple_abm_params.jl")

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
        "--levels"
            help = "number of levels in the order book snapshot"
            arg_type = Int
            default = 5
        "--end_time", "-e"
            help = "simulation length"
            arg_type = Int
            default = 36*10^6
        "--mm1"
            help = "number of MarketMaker(1) agents"
            arg_type = Int
            default = 20
        "--mm2"
            help = "number of MarketMaker(2) agents"
            arg_type = Int
            default = 20
        "--mm3"
            help = "number of MarketMaker(3) agents"
            arg_type = Int
            default = 20
        "--mt1"
            help = "number of MarketTaker(1) agents"
            arg_type = Int
            default = 10
        "--mt2"
            help = "number of MarketTaker(2) agents"
            arg_type = Int
            default = 10
        "--mt3"
            help = "number of MarketTaker(3) agents"
            arg_type = Int
            default = 10
        "--fund1"
            help = "number of Fundamentalist(1) agents"
            arg_type = Int
            default = 10
        "--fund2"
            help = "number of Fundamentalist(2) agents"
            arg_type = Int
            default = 10
        "--fund3"
            help = "number of Fundamentalist(3) agents"
            arg_type = Int
            default = 10
        "--fund4"
            help = "number of Fundamentalist(4) agents"
            arg_type = Int
            default = 10
        "--chart1"
            help = "number of Chartist(1) agents"
            arg_type = Int
            default = 100
        "--chart2"
            help = "number of Chartist(2) agents"
            arg_type = Int
            default = 100
        "--chart3"
            help = "number of Chartist(3) agents"
            arg_type = Int
            default = 100
        "--chart4"
            help = "number of Chartist(4) agents"
            arg_type = Int
            default = 100
        "--nois1"
            help = "number of NoiseTrader(1) agents"
            arg_type = Int
            default = 1060
        "--dir"
            help = "directory to save results"
            arg_type = String
            default = "../results/"
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
    # params["fundamental_dynamics"][Int(params["end_time"] / 4):end] .= 0.7 * params["fundamental_price"]
    # params["fundamental_dynamics"][Int(params["end_time"] / 2):end] .= 1.0 * params["fundamental_price"]
    # params["fundamental_dynamics"][Int(3 * params["end_time"] / 4):end] .= 0.7 * params["fundamental_price"]
    params["init_volume"] = 100
    params["init_book_sigma"] = 4.0

    # Initiate agents
    agents_counts = [
        args["mm1"], args["mm2"], args["mm3"],
        args["mt1"], args["mt2"], args["mt3"],
        args["fund1"], args["fund2"], args["fund3"], args["fund4"],
        args["chart1"], args["chart2"], args["chart3"], args["chart4"],
        args["nois1"]
    ]
    agents = initiate_agents(agents_params, agents_counts, agents_names)
    n_agents = sum(values(agents_counts))

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

    fill_book!(book, agents, agents_counts, params)
    params["first_id"] = params["init_volume"] + 1

    # Run simulation
    messages = PriorityQueue()  # TODO: Add correct types
    simulation_outcome = run_simulation(agents, book, messages, params)
    
    # Save results
    mid_price = zeros(simulation_outcome["current_time"])
    for k in keys(simulation_outcome["mid_price"])
        mid_price[k] = simulation_outcome["mid_price"][k]
    end
    writedlm(string(args["dir"], "mid_simple_", seed, "_", experiment, ".csv"), mid_price, ";")
    if params["snapshots"]
        filename = string(args["dir"], "snapshots_simple_", seed, "_", experiment, ".csv")
        save_snapshots_to_csv(simulation_outcome["snapshots"], filename)
    end
    if params["save_events"]
        filename = string(args["dir"], "events_simple_", seed, "_", experiment, ".csv")
        save_events_to_csv(simulation_outcome["events"], filename)
    end
    println(mid_price[(end-5):end])
    # println(mid_price)
end

main()

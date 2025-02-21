using DelimitedFiles
using Statistics

import Random

include("../src/orders.jl")
include("../src/books.jl")
include("../src/agents.jl")
include("../src/saving_data.jl")
include("../src/trading.jl")
include("../src/matching.jl")
include("../src/market_state.jl")
include("../src/simulation.jl")
include("initiate.jl")

"""
    main()

Build and run simulation with market makers and noise agents.
"""

using Graphs

function connect_agents!(agents::Dict{Int64, Agent}, network_type::String; p=0.1, k=3, m=2)
    n = length(agents)
    graph = nothing

    if network_type == "erdos_renyi"
        println("Creating Erdős–Rényi network with p = $p")
        graph = erdos_renyi(n, p)  # Random connections with probability p
    elseif network_type == "barabasi_albert"
        println("Creating Barabási–Albert network with m = $m")
        graph = barabasi_albert(n, m)  # Preferential attachment
    elseif network_type == "regular"
        println("Creating Regular network with k = $k")
        graph = simple_graph(n)
        for i in 1:n
            for j in 1:k
                neighbor = (i + j - 1) % n + 1
                add_edge!(graph, i, neighbor)
            end
        end
    else
        error("Unknown network type: $network_type")
    end

    # Assign connected traders based on the graph
    for i in 1:n
        neighbors = neighbors(graph, i)
        if haskey(agents, i)
            agents[i] = Trader(agents[i].id, agents[i].orders, collect(neighbors))
        end
    end

    println("Connected agents using $network_type network.")
end


function main()
    # Ensure the results folder exists
    results_dir = "../plots/results/"
    if !isdir(results_dir)
        println("Directory $results_dir does not exist. Creating it...")
        mkpath(results_dir)
    end

    # Command line parameters
    end_time = try parse(Int64, ARGS[1]) catch e 360000 end  # simulation length
    setting = try parse(Int64, ARGS[2]) catch e 1 end  # simulation setting
    mm1 = try parse(Int64, ARGS[3]) catch e 10 end  # number of ...
    mm2 = try parse(Int64, ARGS[4]) catch e 10 end  # number of ...
    mm3 = try parse(Int64, ARGS[5]) catch e 10 end  # number of ...
    mt1 = try parse(Int64, ARGS[6]) catch e 10 end  # number of ...
    mt2 = try parse(Int64, ARGS[7]) catch e 10 end  # number of ...
    mt3 = try parse(Int64, ARGS[8]) catch e 10 end  # number of ...
    fund1 = try parse(Int64, ARGS[9]) catch e 10 end  # number of ...
    fund2 = try parse(Int64, ARGS[10]) catch e 10 end  # number of ...
    fund3 = try parse(Int64, ARGS[11]) catch e 10 end  # number of ...
    fund4 = try parse(Int64, ARGS[12]) catch e 10 end  # number of ...
    chart1 = try parse(Int64, ARGS[13]) catch e 10 end  # number of ...
    chart2 = try parse(Int64, ARGS[14]) catch e 10 end  # number of ...
    chart3 = try parse(Int64, ARGS[15]) catch e 10 end  # number of ...
    chart4 = try parse(Int64, ARGS[16]) catch e 10 end  # number of ...
    nois1 = try parse(Int64, ARGS[17]) catch e 10 end  # number of ...
    seed = try parse(Int64, ARGS[18]) catch e 1 end  # number of ...
    experiment = try parse(Int64, ARGS[19]) catch e 1 end  # number of ...

    # Simulation parameters
    params = Dict()
    params["end_time"] = end_time
    params["initial_time"] = 1  # TODO: Initial time cannot be zero or negative.
    params["fundamental_price"] = 100.0
    params["snapshots"] = false
    params["save_orders"] = true
    params["save_cancelattions"] = true
    params["fundamental_dynamics"] = repeat([params["fundamental_price"]], params["end_time"])
    params["fundamental_dynamics"][Int(end_time / 4):end] .= 0.7 * params["fundamental_price"]
    params["fundamental_dynamics"][Int(end_time / 2):end] .= 1.0 * params["fundamental_price"]
    params["fundamental_dynamics"][Int(3 * end_time / 4):end] .= 0.7 * params["fundamental_price"]

    # Agents
    agents, n_agents = initiate_agents(mm1, mm2, mm3, mt1, mt2, mt3, fund1, fund2, fund3, fund4, chart1, chart2, chart3, chart4, nois1)

    # Connect agents using a specific network type
    connect_agents!(agents, "erdos_renyi", p=0.1)     # Erdős–Rényi
    # connect_agents!(agents, "barabasi_albert", m=2)  # Barabási–Albert
    # connect_agents!(agents, "regular", k=3)          # Regular graph

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
    Random.seed!(seed)
    messages = PriorityQueue()  # TODO: Add correct types
    simulation_outcome = run_simulation(agents, book, messages, params)
    
    # Save results
    mid_price = zeros(simulation_outcome["current_time"])
    for k in keys(simulation_outcome["mid_price"])
        mid_price[k] = simulation_outcome["mid_price"][k]
    end
    writedlm(string(results_dir, "mid_price_", setting, "_", experiment, ".csv"), mid_price, ";")
    writedlm(string(results_dir, "trades_", setting, "_", experiment, ".csv"), simulation_outcome["trades"], ";")
    if params["snapshots"]
        snapshots = zeros(0, 3)
        for (t, v) in simulation_outcome["snapshots"]
            for i in 1:size(v)[1]
                snapshots = vcat(snapshots, [t v[i, 1] v[i, 2]])
            end
        end
        writedlm(string(results_dir, "snapshots_", setting, "_", experiment, ".csv"), snapshots, ";")
    end
    if params["save_cancelattions"]
        cancellations = zeros(Int64, 0, 3)
        for v in simulation_outcome["cancellations"]
            cancellations = vcat(cancellations, [v[1] v[2] v[3]])
        end
        writedlm(string(results_dir, "cancellations_", setting, "_", experiment, ".csv"), cancellations, ";")
    end
    if params["save_orders"]
        all_orders = zeros(Union{Int64, Float64}, 0, 7)
        for v in simulation_outcome["orders"]
            all_orders = vcat(all_orders, [v[1] v[2] v[3] v[4] v[5] v[6] v[7]])
        end
        writedlm(string(results_dir, "orders_", setting, "_", experiment, ".csv"), all_orders, ";")
    end
end

main()

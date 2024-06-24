
using DelimitedFiles
using Statistics

import Random

include("../src/orders.jl")
include("../src/books.jl")
include("../src/agents.jl")
include("../src/saving_data.jl")
include("../src/agents/noise_trader.jl")
include("../src/agents/market_maker.jl")
include("../src/agents/market_taker.jl")
include("../src/agents/chartist.jl")
include("../src/agents/fundamentalist.jl")
include("../src/trading.jl")
include("../src/matching.jl")
include("../src/market_state.jl")
include("../src/simulation.jl")
include("initiate.jl")

"""
    main()

Build and run simulation with market makers and noise agents.
"""
function main()
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

    # Simulation parameters
    params = Dict()
    params["end_time"] = end_time
    params["initial_time"] = 1  # TODO: Initial time cannot be zero or negative.
    params["fundamental_price"] = 100.0
    params["snapshots"] = false
    params["save_orders"] = true
    params["save_cancelattions"] = true
    params["save_features"] = true

    # Agents
    agents, n_agents = initiate_agents(mm1, mm2, mm3, mt1, mt2, mt3, fund1, fund2, fund3, fund4, chart1, chart2, chart3, chart4, nois1)

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
    writedlm(string("../plots/results/mid_price_", setting, "_1.csv"), mid_price, ";")
    writedlm(string("../plots/results/trades_", setting, "_1.csv"), simulation_outcome["trades"], ";")
    if params["snapshots"]
        snapshots = zeros(0, 3)
        for (t, v) in simulation_outcome["snapshots"]
            for i in 1:size(v)[1]
                snapshots = vcat(snapshots, [t v[i, 1] v[i, 2]])
            end
        end
        writedlm(string("../plots/results/snapshots_", setting, "_1.csv"), snapshots, ";")
    end
    if params["save_cancelattions"]
        cancellations = zeros(Int64, 0, 3)
        for v in simulation_outcome["cancellations"]
            cancellations = vcat(cancellations, [v[1] v[2] v[3]])
        end
        writedlm(string("../plots/results/cancellations_", setting, "_1.csv"), cancellations, ";")
    end
    if params["save_orders"]
        all_orders = zeros(Union{Int64, Float64}, 0, 7)
        for v in simulation_outcome["orders"]
            all_orders = vcat(all_orders, [v[1] v[2] v[3] v[4] v[5] v[6] v[7]])
        end
        writedlm(string("../plots/results/orders_", setting, "_1.csv"), all_orders, ";")
    end
    if params["save_features"]
        buy_ratios = zeros(n_agents)
        market_ratios = zeros(n_agents)
        mean_size = zeros(n_agents)
        std_size = zeros(n_agents)
        mean_times = zeros(n_agents)
        std_times = zeros(n_agents)

        cancel_ratios = zeros(n_agents)
        
        trades_num = zeros(n_agents)
        traded_volume = zeros(n_agents)
        
        for i in 1:n_agents
            temp_orders = all_orders[all_orders[:, 2].==float(i), :]
            buy_ratios[i] = sum(temp_orders[:, 5]) / size(temp_orders)[1]
            market_ratios[i] = 1.0 - sum(temp_orders[:, 7]) / size(temp_orders)[1]
            mean_size[i] = mean(temp_orders[:, 4])
            std_size[i] = std(temp_orders[:, 4])
            temp_times = diff(sort(temp_orders[:, 3]))
            mean_times[i] = mean(temp_times)
            std_times[i] = std(temp_times)

            temp_cancels = cancellations[cancellations[:, 2].==float(i), :]
            cancel_ratios[i] = size(temp_cancels)[1] / size(temp_orders)[1]
        
            trades = simulation_outcome["trades"]
            temp_trades_a = trades[trades[:, 6].==float(i), :]
            temp_trades_p = trades[trades[:, 7].==float(i), :]
            trades_num[i] = size(temp_trades_a)[1] + size(temp_trades_p)[1]
            traded_volume[i] = sum(temp_trades_a[:, 3]) + sum(temp_trades_p[:, 3])
        end
        features = hcat(
            buy_ratios,
            market_ratios,
            mean_size,
            std_size,
            mean_times,
            std_times,
            cancel_ratios,
            trades_num,
            traded_volume
            )
        writedlm(string("../plots/results/features_", setting, "_1.csv"), features, ";")
    end
end

main()

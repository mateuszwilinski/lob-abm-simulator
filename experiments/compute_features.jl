
using DelimitedFiles
using Statistics

"""
    main()

Cumpute features based on simulation results.
"""
function main()
    # Parameters
    K = 30
    simulation_type = 2
    n_agents = 1530

    horizon_short = 10000
    horizon = 20000
    horizon_long = 40000

    event_times = [180000, 360000, 540000]
    event_horizon = 20000
    price_horizon = 80000
    long_price_horizon = 160000

    for setting in 1:K
        # Load simulation results
        orders = readdlm(string("../plots/results/orders_", setting, "_", simulation_type, ".csv"), ';')
        cancellations = readdlm(string("../plots/results/cancellations_", setting, "_", simulation_type, ".csv"), ';')
        trades = readdlm(string("../plots/results/trades_", setting, "_", simulation_type, ".csv"), ';')
        mid_price = readdlm(string("../plots/results/mid_price_", setting, "_", simulation_type, ".csv"), ';')

        # Update simulation results
        for i in 1:size(mid_price)[1]
            if isnan(mid_price[i])
                mid_price[i] = mid_price[i-1]
            end
        end

        # Compute features
        buy_ratios = zeros(n_agents)
        market_ratios = zeros(n_agents)
        mean_size = zeros(n_agents)
        std_size = zeros(n_agents)
        mean_times = zeros(n_agents)
        std_times = zeros(n_agents)

        cancel_ratios = zeros(n_agents)

        trades_num = zeros(n_agents)
        traded_volume = zeros(n_agents)
        
        trend_short = zeros(n_agents)
        dir_trend_short = zeros(n_agents)
        trend = zeros(n_agents)
        dir_trend = zeros(n_agents)
        trend_long = zeros(n_agents)
        dir_trend_long = zeros(n_agents)
        
        profits = zeros(n_agents)
        weight_profits = zeros(n_agents)
        long_profits = zeros(n_agents)

        for i in 1:n_agents
            temp_orders = orders[orders[:, 2].==float(i), :]
            buy_ratios[i] = sum(temp_orders[:, 5]) / size(temp_orders)[1]
            market_ratios[i] = 1.0 - sum(temp_orders[:, 7]) / size(temp_orders)[1]
            mean_size[i] = mean(temp_orders[:, 4])
            std_size[i] = std(temp_orders[:, 4])
            temp_times = diff(sort(temp_orders[:, 3]))
            mean_times[i] = mean(temp_times)
            std_times[i] = std(temp_times)

            temp_cancels = cancellations[cancellations[:, 2].==float(i), :]
            cancel_ratios[i] = size(temp_cancels)[1] / size(temp_orders)[1]

            temp_trades_a = trades[trades[:, 6].==float(i), :]
            temp_trades_p = trades[trades[:, 7].==float(i), :]
            trades_num[i] = size(temp_trades_a)[1] + size(temp_trades_p)[1]
            traded_volume[i] = sum(temp_trades_a[:, 3]) + sum(temp_trades_p[:, 3])
            
            temp_time = Int.(temp_orders[:, 3])
            ids = (temp_time .< size(mid_price)[1]) .* (temp_time .> horizon_short)
            trend_short[i] = mean(abs.(mid_price[temp_time[ids]] .- mid_price[temp_time[ids].-horizon_short]))
            dir_trend_short[i] = mean((mid_price[temp_time[ids]] .- mid_price[temp_time[ids].-horizon_short]) .*
                                      (temp_orders[ids, 5]*2.0 .- 1.0))
            ids .*= (temp_time .> horizon)
            trend[i] = mean(abs.(mid_price[temp_time[ids]] .- mid_price[temp_time[ids].-horizon]))
            dir_trend[i] = mean((mid_price[temp_time[ids]] .- mid_price[temp_time[ids].-horizon]) .*
                                (temp_orders[ids, 5]*2.0 .- 1.0))
            ids .*= (temp_time .> horizon_long)
            trend_long[i] = mean(abs.(mid_price[temp_time[ids]] .- mid_price[temp_time[ids].-horizon_long]))
            dir_trend_long[i] = mean((mid_price[temp_time[ids]] .- mid_price[temp_time[ids].-horizon_long]) .*
                                     (temp_orders[ids, 5]*2.0 .- 1.0))
        
            temp_profits = Vector{Float64}()
            temp_long_profits = Vector{Float64}()
            temp_weights = Vector{Float64}()
            temp_time = Int.(temp_orders[:, 3])
            for e in event_times
                temp_ids = (temp_time .> e) .* (temp_time .< (e + event_horizon))
                if size(temp_ids)[1] > 0
                    append!(temp_profits, ((temp_orders[temp_ids, 5] .- 0.5) .*
                                           (mid_price[temp_time[temp_ids] .+ price_horizon] ./
                                            mid_price[temp_time[temp_ids]] .- 1.0)))
                    append!(temp_long_profits, ((temp_orders[temp_ids, 5] .- 0.5) .*
                                            (mid_price[temp_time[temp_ids] .+ long_price_horizon] ./
                                             mid_price[temp_time[temp_ids]] .- 1.0)))
                    append!(temp_weights, temp_orders[temp_ids, 4])
                end
            end
            if size(temp_profits)[1] > 0
                profits[i] = mean(temp_profits)
                weight_profits[i] = mean(temp_profits .* temp_weights) / sum(temp_weights)
                long_profits[i] = mean(temp_long_profits)
            end
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
            traded_volume,
            trend_short,
            dir_trend_short,
            trend,
            dir_trend,
            trend_long,
            dir_trend_long,
            profits,
            long_profits,
            weight_profits
            )
        writedlm(string("../plots/results/features_", setting, "_", simulation_type, ".csv"), features, ";")
    end
end

main()

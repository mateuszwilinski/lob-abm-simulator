
using CSV
using DataFrames

"""
    main()

Converts the events and snapshots data to the LOBSTER format.
"""
function main()
    # Get the names of the files from the command line
    events_name = try ARGS[1] catch e "events_simple_1_1" end
    snapshots_name = try ARGS[2] catch e "snapshots_simple_1_1" end
    directory = try ARGS[3] catch e "../results" end

    # Load the full events data
    events_input = string(directory, events_name, ".csv")
    snapshots_input = string(directory, snapshots_name, ".csv")
    
    events = DataFrame(CSV.File(events_input, delim=',', header=false))
    snapshots = DataFrame(CSV.File(snapshots_input, delim=',', header=false))
    levels = Int64(size(snapshots)[2] / 4)

    # Add the header
    rename!(events, [:time, :type, :id, :size, :price, :dir, :agent, :cross_order, :cross_agent])
    snapshots_columns = String[]
    for i in 1:levels
        push!(snapshots_columns, "ask_$(i)_price")
        push!(snapshots_columns, "ask_$(i)_vol")
        push!(snapshots_columns, "bid_$(i)_price")
        push!(snapshots_columns, "bid_$(i)_vol")
    end
    rename!(snapshots, snapshots_columns)

    # Select only the LOBSTER columns
    events = select(events, [:time, :type, :id, :size, :price, :dir])

    # Get rid of market orders
    snapshots = snapshots[events.type .!= 0, :]
    events = events[events.type .!= 0, :]

    # Get rid of immediately executed limit orders
    executed_limit_orders_id = (events.type .== 1) .& (events.size .== 0)
    snapshots = snapshots[.!executed_limit_orders_id, :]
    events = events[.!executed_limit_orders_id, :]

    # Convert price to Int64
    events.price = round.(Int64, events.price * 10000)
    for i in 1:2:size(snapshots)[2]  # TODO: check efficiency and potential improvements
        ids = isnan.(snapshots[:, i])
        if i % 4 == 1
            snapshots[ids, i] .= 999999.9999
        elseif i % 4 == 3
            snapshots[ids, i] .= -999999.9999
        end
        snapshots[!, i] = round.(Int64, snapshots[!, i] * 10000)
    end

    # Save the LOBSTER version
    events_output = string(directory, events_name, "_lobster.csv")
    snapshots_output = string(directory, snapshots_name, "_lobster.csv")

    CSV.write(events_output, events)
    CSV.write(snapshots_output, snapshots)
end

main()

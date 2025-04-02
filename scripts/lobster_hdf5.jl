
using CSV
using DataFrames
using Tables
using HDF5

"""
    main()

Converts the events and snapshots data to the LOBSTER format and saves it in a single
HDF5 file, together with labels.
"""
function main()
    # Get the names of the files from the command line
    events_name = try ARGS[1] catch e "events_simple_1_1" end
    snapshots_name = try ARGS[2] catch e "snapshots_simple_1_1" end
    name = try ARGS[3] catch e "simple_1_1" end

    # Load the full events data
    events_input = string("../results/", events_name, ".csv")
    snapshots_input = string("../results/", snapshots_name, ".csv")
    
    events = DataFrame(CSV.File(events_input, delim=',', header=false))
    snapshots = DataFrame(CSV.File(snapshots_input, delim=',', header=false))
    levels = Int64(size(snapshots)[2] / 4)

    # Add the header and create column types vectors
    events_columns = [:time, :type, :id, :size, :price, :dir, :agent, :cross_order, :cross_agent]
    rename!(events, events_columns)

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

    # Convert data to NamedTuples
    events = Tables.rowtable(events)
    snapshots = Tables.rowtable(snapshots)

    # Create labels
    labels = zeros(Int64, length(events))

    # Save the LOBSTER version
    h5open(string("../results/", name, ".h5"), "w") do file
        file[joinpath(name, "EVENTS")] = events
        file[joinpath(name, "SNAPSHOTS")] = snapshots
        file[joinpath(name, "LABELS")] = labels
    end
end

main()

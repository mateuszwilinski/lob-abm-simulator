
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

    # Load the full events data
    events_input = string("../results/", events_name, ".csv")
    snapshots_input = string("../results/", snapshots_name, ".csv")
    
    events = DataFrame(CSV.File(events_input, delim=',', header=false))
    snapshots = DataFrame(CSV.File(snapshots_input, delim=',', header=false))

    # Add the header
    rename!(events, [:time, :type, :id, :size, :price, :dir, :agent, :cross_order, :cross_agent])
    rename!(snapshots, [
        :ask_1_price, :ask_1_vol, :bid_1_price, :bid_1_vol,
        :ask_2_price, :ask_2_vol, :bid_2_price, :bid_2_vol,
        :ask_3_price, :ask_3_vol, :bid_3_price, :bid_3_vol,
        :ask_4_price, :ask_4_vol, :bid_4_price, :bid_4_vol,
        :ask_5_price, :ask_5_vol, :bid_5_price, :bid_5_vol
        ])

    # Select only the LOBSTER columns
    events = select(events, [:time, :type, :id, :size, :price, :dir])

    # Get rid of market orders
    snapshots = snapshots[events.type .!= 0, :]
    events = events[events.type .!= 0, :]

    # Save the LOBSTER version
    events_output = string("../results/", events_name, "_lobster.csv")
    snapshots_output = string("../results/", snapshots_name, "_lobster.csv")

    CSV.write(events_output, events)
    CSV.write(snapshots_output, snapshots)
end

main()

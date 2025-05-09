
using CSV
using DataFrames

"""
    main()

Converts the events and snapshots data to the LOBSTER format.
"""
function main()
    # Get the names of the files from the command line
    events_name = try ARGS[1] catch e "events_net_1_1" end

    # Load the full events data
    events_input = string("../results/", events_name, ".csv")
    events = DataFrame(CSV.File(events_input, delim=',', header=false))

    # Add the header
    rename!(events, [:time, :type, :id, :size, :price, :dir, :agent, :cross_order, :cross_agent])

    # Get rid of non-executions
    events = events[events.cross_order .> 0, :]

    # Compute attention data
    attention_data = combine(
                        groupby(events, :cross_order),
                        [:time, :cross_agent, :size, :dir] =>
                        ((t, c, s, d) -> (time=minimum(t), cross_agent=minimum(c), volume=sum(s)*minimum(d))) =>
                        AsTable
                        )
    
    # Add other columns
    attention_data[!, :registration_date] = attention_data.time
    attention_data[!, :isin] .= 1
    attention_data[!, :transaction_basis] .= 1
    attention_data[!, :holding_type] .= 1

    # Rename columns
    rename!(attention_data, [
                        :order_id,
                        :trading_date,
                        :owner_id,
                        :volume,
                        :registration_date,
                        :isin,
                        :transaction_basis,
                        :holding_type
                        ])

    # Reorder columns and drop order_id
    attention_data = attention_data[:, [
                        :trading_date,
                        :registration_date,
                        :owner_id,
                        :volume,
                        :isin,
                        :transaction_basis,
                        :holding_type
                        ]]

    # Save the LOBSTER version
    output = string("../results/", events_name, "_atten.csv")
    CSV.write(output, attention_data)
end

main()

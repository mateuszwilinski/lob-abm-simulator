
using NPZ
using CSV
using DataFrames

"""
    combine_order_executions(i, events)

It checks if the current event is part of a sequence of executions
and returns the total size of the combined order and the number of
preceding events that were part of the same order.
"""
function combine_order_executions(i::Int64, events::DataFrame)
    k = 1
    full_size = events.size[i]
    while (events.cross_order[i-k] == events.id[i]) && (k < i)
        full_size += events.size[i-k]
        k += 1
    end
    return full_size, k-1
end

"""
    add_target_events!(events, snapshots, target)

This function modifies the `events` and `snapshots` DataFrames to mark
events related to a specific target agent. It combines order executions
in order to mark limit and market orders, which triggered executions
and were send by the target agent.
"""
function add_target_events!(events::DataFrame, snapshots::DataFrame, target::Int64)
    e = 1
    while e <= size(events)[1]
        if events.agent[e] == target
            if (events.type[e] == 0) || (events.type[e] == 1)
                full_size, k = combine_order_executions(e, events)
                if k > 0
                    insert!(events, e-k, events[e, :])
                    insert!(snapshots, e-k, snapshots[e-k-1, :])
                    events.size[e-k] = full_size
                    events.target[e-k] = 1
                    e += 1
                else
                    events.target[e] = 1
                end
            elseif (events.type[e] == 2) || (events.type[e] == 3)
                events.target[e] = 1
            end
        end
        e += 1
    end
end

"""
    process_book(b, price_levels)

This function processes the order book data from LOBSTER format into a matrix format
suitable for further analysis, where each row corresponds to a time step and each
column corresponds to a price level. It also calculates the mid-price differences
in ticks and returns a DataFrame with the mid-price differences as the first column
followed by the book data.
"""
function process_book(b::DataFrame, price_levels::Int64)
    # Mid-price rounded to nearest tick (100)
    p_ref = round.((b[:, 1] .+ b[:, 3]) ./ 2, digits=-2)
    
    # Get price indices (every other column starting from 1st)
    b_prices = b[:, 1:2:end]  # columns 1, 3, 5, 7, ...
    b_indices = div.((b_prices .- p_ref), 100)  # TODO: make it dependent on the tick_size
    b_indices = Int64.(b_indices .+ div(price_levels, 2))
    
    # Get volume data (every other column starting from 2nd)
    vol_book = copy(b[:, 2:2:end])  # columns 2, 4, 6, 8, ...
    
    # Convert sell volumes (ask side) to negative - every other column
    for j in 1:2:size(vol_book, 2)  # columns 1, 3, 5, ... (which correspond to ask volumes)
        vol_book[:, j] = -vol_book[:, j]
    end
    
    # Initialize the book matrix
    mybook = zeros(Int32, size(b, 1), price_levels)
    
    # Fill the book matrix
    for i in 1:size(b_indices, 1)
        for j in 1:size(b_indices, 2)
            dist_index = b_indices[i, j] + 1
            if 0 < dist_index <= price_levels
                mybook[i, dist_index] = vol_book[i, j]
            end
        end
    end
    
    # Calculate mid-price differences in ticks
    mid_diff = div.(diff(vcat(p_ref[1], p_ref)), 100)  # Add first element to handle diff
    mid_diff = convert(Vector{Int32}, mid_diff)
    
    # Concatenate mid_diff as first column with mybook
    return hcat(mid_diff, mybook)
end

"""
    get_price_range_for_level(book, lvl)

This function retrieves the price range for a specific level in the order book.
It returns a DataFrame with the maximum and minimum prices for that level.
"""
function get_price_range_for_level(book::DataFrame, lvl::Int)
    @assert lvl > 0 "Level must be greater than 0"
    @assert lvl <= div(size(book, 2), 4) "Level exceeds maximum available levels"
    
    # Calculate column indices (Julia uses 1-based indexing)
    col1 = (lvl - 1) * 4 + 1  # First column: bid price
    col2 = (lvl - 1) * 4 + 3  # Third column: ask price
    
    # Extract the price range columns
    p_range = book[:, [col1, col2]]
    
    # Rename columns
    rename!(p_range, [1 => :p_max, 2 => :p_min])
    
    return p_range
end

"""
    filter_by_lvl(messages, book, lvl)

This function filters the messages and book data by a specific price level.
"""
function filter_by_lvl(messages::DataFrame, book::DataFrame, lvl::Int64)
    @assert size(messages, 1) == size(book, 1) "Messages and book must have same number of rows"
    
    # Get price range for the specified level
    p_range = get_price_range_for_level(book, lvl)
    
    # Create filter mask
    price_filter = (messages.price .<= p_range.p_max) .& (messages.price .>= p_range.p_min)
    
    # Filter messages
    filtered_messages = messages[price_filter, :]
    
    # Filter book to match the filtered messages indices
    filtered_book = book[price_filter, 1:(lvl * 4)]
    
    return filtered_messages, filtered_book
end

"""
    filter_by_type(messages, book; allowed_event_types)

This function filters the messages and book data by allowed event types.
"""
function filter_by_type(messages::DataFrame, book::DataFrame; allowed_event_types::Vector{Int} = [0, 1, 2, 3, 4])
    @assert size(messages, 1) == size(book, 1) "Messages and book must have same number of rows"
    
    # Create filter mask for allowed event types
    type_filter = in.(messages.type, Ref(allowed_event_types))
    
    # Filter messages
    filtered_messages = messages[type_filter, :]
    
    # Filter book to match the filtered messages indices
    filtered_book = book[type_filter, :]
    
    return filtered_messages, filtered_book
end

"""
    process_msgs(messages, book, na_val)

This function processes the messages, adding necessary columns and transforming
the data into a format suitable for further analysis.
"""
function process_msgs(messages::DataFrame, book::DataFrame, na_val::Int64)
    # TIME
    time_diff = diff(vcat(messages.time[1], messages.time))  # Handle first element for diff
    
    # Insert delta_t columns
    insertcols!(messages, 2, :delta_t_ns => time_diff)
    insertcols!(messages, 2, :delta_t_s => floor.(Int64, messages.delta_t_ns))
    
    # Convert delta_t_ns to nanosecond fraction
    messages[!, :delta_t_ns] = floor.(Int64, (messages.delta_t_ns .% 1) .* 1_000_000_000)
    
    # Insert time_s column at beginning
    insertcols!(messages, 1, :time_s => floor.(Int64, messages.time))
    
    # Rename time column to time_ns and convert to nanoseconds
    rename!(messages, :time => :time_ns)
    messages[!, :time_ns] = floor.(Int64, (messages.time_ns .% 1) .* 1_000_000_000)
    
    # SIZE
    messages[messages.size .> 9999, :size] .= 9999
    
    # PRICE
    messages[!, :price_abs] = messages.price  # keep absolute price for later (simulator)
    
    # Mid-price reference, rounded down to nearest tick_size
    tick_size = 100  # TODO: make it dependent on the tick_size
    mid_prices = (book[:, 1] .+ book[:, 3]) ./ 2
    p_ref = vcat(mid_prices[1], mid_prices[1:end-1])  # Shift operation
    p_ref = Int64.(div.(p_ref, tick_size) .* tick_size)  # TODO: Is there a more elegant way?
    
    # Process prices
    messages[!, :price] = process_price(messages.price, p_ref, -99900, 99900)
    
    # Remove first row
    messages = messages[2:end, :]
    messages[!, :price] = Int64.(messages.price)
    
    # DIRECTION
    messages[!, :dir] = Int64.((messages.dir .+ 1) ./ 2)
    
    # Change column order
    col_order = [:target, :id, :type, :dir, :price_abs, :price,
                 :size, :delta_t_s, :delta_t_ns, :time_s, :time_ns]
    messages = messages[:, col_order]

    # return messages
    
    # Add original message as feature for all referential order types (2, 3, 4)
    messages = add_orig_msg_features(
        messages,
        modif_fields = ["price", "size", "time_s", "time_ns"],
        nan_val = na_val
    )
    
    @assert size(messages, 1) + 1 == size(book, 1) "Length of messages (-1) and book states don't align"
    
    return messages
end

"""
    process_price(p, p_ref, p_lower_trunc, p_upper_trunc)

This function processes the price series by encoding prices relative to a reference price,
truncating them to specified limits, and scaling them to tick size differences.
"""
function process_price(
    p::Vector{Int64},
    p_ref::Vector{Int64},
    p_lower_trunc::Int64,
    p_upper_trunc::Int64
)
    # Encode prices relative to (previous) reference price
    p = p .- p_ref
    
    # Truncate price
    p[p .> p_upper_trunc] .= p_upper_trunc
    p[p .< p_lower_trunc] .= p_lower_trunc
    
    # Scale prices to min ticks size differences
    p ./= 100  # TODO: make it dependent on the tick_size

    return p
end

"""
    add_orig_msg_features(m; modif_types, modif_fields, nan_val)

This function modifies messages `m` to include features from the referenced messages
for order modifications (cancellations, deletions, executions). It adds new columns
for the original message's price, size, and time, and fills them with a specified NaN
value if the original message is not available.
"""
function add_orig_msg_features(
    m::DataFrame;
    modif_types::Vector{Int64} = [2, 3, 4],
    modif_fields::Vector{String} = ["price", "size", "time"],
    nan_val::Int64 = -9999
)
    # Create a copy to avoid mutating the original
    m_result = copy(m)
    
    # Create filter for modification types
    modif_mask = in.(m_result.type, Ref(modif_types))
    
    # Get rows with modification types and add row numbers
    m_modif = m_result[modif_mask, :]
    m_modif[!, :original_index] = findall(modif_mask)
    
    # Get reference data (type == 1)
    ref_cols = vcat(["id"], modif_fields)
    m_ref = m_result[m_result.type .== 1, Symbol.(ref_cols)]
    
    # Perform left join
    m_changes = leftjoin(m_modif, m_ref, on = :id, makeunique = true, renamecols = "" => "_ref")
    
    # Create new column names for referenced fields
    modif_cols = [field * "_ref" for field in modif_fields]
    
    # Add empty columns for referenced order data
    for col in modif_cols
        m_result[!, Symbol(col)] .= nan_val
    end

    m_changes_ = select(m_changes, Not(:original_index))
    m_changes_ = coalesce.(m_changes_, -9999)

    m_result[m_changes.original_index, :] = m_changes_
    
    return m_result
end

"""
    main()

Converts the events and snapshots data to the extended LOBSTER format,
which can be used with the S5 architecture for investor imitation.
"""
function main()
    # Get the names of the files from the command line
    events_name = try ARGS[1] catch e "events_simple_1_1" end
    snapshots_name = try ARGS[2] catch e "snapshots_simple_1_1" end
    target = try parse(Int64, ARGS[3]) catch e 0 end
    tick_size = try parse(Float64, ARGS[4]) catch e 0.01 end
    price_levels = try parse(Int64, ARGS[5]) catch e 500 end
    directory = try ARGS[6] catch e "../results/" end
    na_val = try ARGS[7] catch e "-9999" end

    na_val = parse(Int64, na_val)

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

    # Add the target column and mark the events related to the target agent
    events[!, "target"] = zeros(Int64, size(events)[1])
    add_target_events!(events, snapshots, target)

    # Select only the LOBSTER columns
    events = select(events, [:target, :time, :type, :id, :size, :price, :dir])

    # Get rid of market orders (excluding those sent by the target agent)
    market_orders_id = (events.type .== 0) .& (events.target .== 0)
    snapshots = snapshots[.!market_orders_id, :]
    events = events[.!market_orders_id, :]

    # Get rid of immediately executed limit orders
    # TODO: what about not-fully executed limit orders from target agent?
    executed_limit_orders_id = (events.type .== 1) .& (events.size .== 0) .& (events.target .== 0)
    snapshots = snapshots[.!executed_limit_orders_id, :]
    events = events[.!executed_limit_orders_id, :]

    # Convert price to Int64
    replace!(events.price, NaN => na_val / 10000)
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

    # Process messages and book
    # events, snapshots = filter_by_lvl(events, snapshots, 10)
    msgs, book = filter_by_type(events, snapshots; allowed_event_types=[0, 1, 2, 3, 4])
    msgs = process_msgs(msgs, book, na_val)
    book = process_book(book, price_levels)

    # Save the LOBSTER version
    events_output = string(directory, "message", events_name[7:end], "_proc_.npy")
    snapshots_output = string(directory, "orderbook", snapshots_name[10:end], "_proc_.npy")

    npzwrite(events_output, Matrix(msgs))
    npzwrite(snapshots_output, book)
end

main()

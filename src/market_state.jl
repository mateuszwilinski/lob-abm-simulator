
using StaticArrays

# Structure for snapshots
struct Snapshot{N}
    ask_prices::SVector{N, Float64}
    ask_volumes::SVector{N, Int}
    bid_prices::SVector{N, Float64}
    bid_volumes::SVector{N, Int}
end

"""
    mid_price(book)

Return mid price of current state limit order book.
"""
function mid_price(book::Book)
    return (book.best_ask + book.best_bid) / 2.0
end

"""
    take_snapshot(book, levels)

Return snapshot of five best levels of the current limit order book state.
"""
function take_snapshot(book::Book, levels::Int64)
    # Use MVector (mutable static vector) during building
    ask_prices = @MVector fill(NaN, levels)
    ask_volumes = @MVector zeros(Int, levels)
    bid_prices = @MVector fill(NaN, levels)
    bid_volumes = @MVector zeros(Int, levels)
    
    # Get sorted price levels on both sides
    ask_prices_sorted = sort(collect(keys(book.asks)))
    bid_prices_sorted = sort(collect(keys(book.bids)), rev=true)
    
    # Fill in ask side (up to levels limit)
    for i in 1:min(levels, length(ask_prices_sorted))
        price = ask_prices_sorted[i]
        ask_prices[i] = price
        ask_volumes[i] = sum(get_size(o) for o in book.asks[price])
    end
    
    # Fill in bid side (up to levels limit)
    for i in 1:min(levels, length(bid_prices_sorted))
        price = bid_prices_sorted[i]
        bid_prices[i] = price
        bid_volumes[i] = sum(get_size(o) for o in book.bids[price])
    end
    
    # Convert mutable static vectors to immutable ones for the final struct
    return Snapshot(
        SVector(ask_prices),
        SVector(ask_volumes),
        SVector(bid_prices),
        SVector(bid_volumes)
    )
end

"""
    market_depth(book)

Return market depth of current state limit order book.
"""
function market_depth(book::Book)
    bids_size = length(book.bids)
    asks_size = length(book.asks)
    depth = zeros(Float64, bids_size + asks_size, 2)
    for (i, p) in enumerate(keys(book.bids))
        depth[i, 1] = p
        depth[i, 2] = -sum(get_size(o) for o in book.bids[p])
    end
    for (i, p) in enumerate(keys(book.asks))
        depth[i + bids_size, 1] = p
        depth[i + bids_size, 2] = sum(get_size(o) for o in book.asks[p])
    end
    return depth
end


"""
    mid_price(book)

Return mid price of current state limit order book.
"""
function mid_price(book::Book)
    return (book.best_ask + book.best_bid) / 2.0
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

"""
    market_trades(book)

Return all trades in the book.
"""
function market_trades(book::Book)
    ts = zeros(Union{Int64, Float64}, 0, 7)
    for t in book.trades
        ts = vcat(ts, Union{Int64, Float64}[book.time t.price t.size t.active_order t.passive_order t.active_agent t.passive_agent])
    end
    return ts
end

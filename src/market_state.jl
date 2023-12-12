
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
        if length(book.bids[p]) == 0
            println(book.bids)
        end
        depth[i, 2] = sum(get_size(o) for o in book.bids[p])
    end
    for (i, p) in enumerate(keys(book.asks))
        depth[i + bids_size, 1] = p
        if length(book.asks[p]) == 0
            println(book.asks)
        end
        depth[i + bids_size, 2] = sum(get_size(o) for o in book.asks[p])
    end

    return depth
end

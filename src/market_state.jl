
"""
    mid_price(book)

Return mid price of current state limit order book.
"""
function mid_price(book::Book)
    return (book.best_ask + book.best_bid) / 2.0
end

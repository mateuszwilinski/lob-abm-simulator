
function mid_price(book::Book)
    return (book.best_ask + book.best_bid) / 2.0
end

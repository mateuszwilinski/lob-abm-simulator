
mutable struct Budget{T <: Integer, F <: Real}
    shares::T
    money::F
end

"""
    available_budget(budget, is_bid, book, size)

Check available budget for an order of given size and price.
"""
function available_budget(budget::Budget{T,F}, is_bid::Bool, book::Book{F},
                          size::T, price::F) where {T <: Integer, F <: Real}
    if is_bid
        available_money = budget.money
        available_size = 0
        # We compute how many shares can be bought with the available money.
        for (ask_price, ask_orders) in book.asks
            # First check if the order is crossing the spread
            if ask_price > price
                break
            end
            for order in ask_orders
                available_money -= ask_price * order.size[]
                # If we run out of money, return how many shares we can buy
                if available_money < 0
                    available_money += ask_price * order.size[]
                    available_size += floor(Int64, available_money / ask_price)
                    return min(size, available_size)
                end
                available_size += order.size[]
                # If we already have enough shares, return expected size
                if available_size >= size
                    return size
                end
            end
        end
        # If we reach this point, it means that the order is not fully crossing the spread
        # and we can use the remaining money to post at the limit price.
        if available_money > 0
            available_size += floor(Int64, available_money / price)
        end
        return min(size, available_size)
    else
        # For sell orders, we just check how many shares are available.
        return min(size, budget.shares)
    end
end

"""
    update_budget!(budget, order, matching)

Update the budget after a market order is sent.
"""
function update_budget!(budget::Budget{T,F}, order::MarketOrder,
                        matching::Vector{Dict}) where {T <: Integer, F <: Real}
    if order.is_bid
        for msg in matching
            budget.money -= msg["exec_size"] * msg["exec_price"]
            budget.shares += msg["exec_size"]
        end
    else
        for msg in matching
            budget.money += msg["exec_size"] * msg["exec_price"]
            budget.shares -= msg["exec_size"]
        end
    end
end

"""
    update_budget!(budget, order, matching)

Update the budget after a limit order is sent.
"""
function update_budget!(budget::Budget{T,F}, order::LimitOrder,
                        matching::Vector{Dict}) where {T <: Integer, F <: Real}
    if order.is_bid
        for msg in matching
            budget.money -= msg["exec_size"] * msg["exec_price"]
            budget.shares += msg["exec_size"]
        end
        budget.money -= order.size[] * order.price
    else
        for msg in matching
            budget.money += msg["exec_size"] * msg["exec_price"]
            budget.shares -= msg["exec_size"]
        end
        budget.shares -= order.size[]
    end
end

"""
    update_budget!(budget, order, msg)

Update the budget after a limit order was executed or cancelled.
"""
function update_budget!(budget::Budget{T,F}, order::LimitOrder) where {T <: Integer, F <: Real}
    if order.is_bid
        budget.money += order.size[] * order.price
    else
        budget.shares += order.size[]
    end
end

"""
    update_budget!(budget, msg)

Update the budget after a limit order was executed.
"""
function update_budget!(budget::Budget{T,F}, msg::Dict) where {T <: Integer, F <: Real}
    if msg["is_bid"]
        budget.shares += msg["exec_size"]
    else
        budget.money += msg["exec_size"] * msg["exec_price"]
    end
end
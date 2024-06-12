
import Distributions: Exponential

"""
    initiate!(agent, book, params)

Initiate NoiseTrader "agent" on the "book", for simulation with "params".
"""
function initiate!(agent::Chartist, book::Book, params::Dict)
    lmt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    lmt_msg["recipient"] = agent.id
    lmt_msg["book"] = book.symbol

    lmt_msg["activation_time"] = ceil(Int64, params["initial_time"] + agent.horizon +
                                  rand(Exponential(agent.limit_rate)))
    lmt_msg["activation_priority"] = 1
    lmt_msg["action"] = "LIMIT_ORDER"
    
    mkt_msg = Dict{String, Union{String, Int64, Float64, Bool}}()
    mkt_msg["recipient"] = agent.id
    mkt_msg["book"] = book.symbol

    mkt_msg["activation_time"] = ceil(Int64, params["initial_time"] + agent.horizon +
                                  rand(Exponential(agent.market_rate)))
    mkt_msg["activation_priority"] = 1
    mkt_msg["action"] = "MARKET_ORDER"
    
    msgs = Vector{Dict}()
    push!(msgs, mkt_msg)
    push!(msgs, lmt_msg)
    return msgs
end

"""
    action!(agent, book, agents, params, simulation, msg)

Activate an agent, trade or cancel an existing trade and send a new message.
"""
function action!(agent::Chartist, book::Book, agents::Dict{Int64, Agent},
                 params::Dict, simulation::Dict, msg::Dict)
    # initialise new messages
    msgs = Vector{Dict}()
    
    # Agent trades
    if msg["action"] == "LIMIT_ORDER"
        # prepare limit order
        current_mid_price = mid_price(book)
        previous_mid_price = simulation["mid_price"][simulation["current_time"]-agent.horizon]
        if isnan(current_mid_price) | isnan(previous_mid_price)
            ret = randn() * agent.sigma
            expected_price = params["fundamental_price"] + ret
        else
            ret = agent.coeff * (current_mid_price - previous_mid_price) + randn() * agent.sigma
            expected_price = current_mid_price + ret
        end

        is_bid = (ret > 0.0)  # TODO: what to do when ret = 0.0 ???
        simulation["last_id"] += 1
        order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))
        order = LimitOrder(expected_price, order_size, is_bid, simulation["last_id"], agent.id, book.symbol)

        # cancel inconsistent orders
        for (order_id, o) in agent.orders
            if o.is_bid != is_bid
                if params["save_cancelattions"]
                    save_cancel!(simulation, order_id, agent)
                end
                cancel_order!(order_id, book, agent)
            elseif (((o.price > expected_price) && o.is_bid) ||
                    ((o.price < expected_price) && !o.is_bid))
                if params["save_cancelattions"]
                    save_cancel!(simulation, order_id, agent)
                end
                cancel_order!(order_id, book, agent)
            end
        end

        # match new limit order
        if params["save_orders"]
            save_order!(simulation, order, agent)
        end
        matched_orders = add_order!(book, order)
        add_trades!(book, matched_orders)
        if get_size(order) > 0
            agent.orders[order.id] = order
        end
        append!(msgs, messages_from_match(matched_orders, book))

        # sending expiration message
        expire = Dict{String, Union{String, Int64, Float64, Bool}}()
        expire["recipient"] = agent.id
        expire["book"] = book.symbol
        expire["activation_time"] = simulation["current_time"] + agent.horizon
        expire["activation_priority"] = 1
        expire["action"] = "CANCEL_ORDER"
        expire["order_id"] = order.id
        push!(msgs, expire)

        # agent sends next order message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.limit_rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "MARKET_ORDER"
        # sending market order
        current_mid_price = mid_price(book)
        previous_mid_price = simulation["mid_price"][simulation["current_time"]-agent.horizon]
        ret = agent.coeff * (current_mid_price - previous_mid_price) + randn() * agent.sigma

        if (book.best_ask - book.best_bid - 2.0 * abs(ret)) < 0.0
            # prepare market order
            is_bid = (ret > 0.0)
            simulation["last_id"] += 1
            order_size = round(Int64, max(1, randn()*agent.size_sigma + agent.size))
            order = MarketOrder(order_size, is_bid, simulation["last_id"], agent.id, book.symbol)

            # cancel inconsistent orders
            for (order_id, o) in agent.orders
                if o.is_bid != is_bid  # TODO: maybe this should depend on the price of "o" (and the expected price)??
                    if params["save_cancelattions"]
                        save_cancel!(simulation, order_id, agent)
                    end
                    cancel_order!(order_id, book, agent)
                end
            end

            # match new market order
            if params["save_orders"]
                save_order!(simulation, order, agent)
            end
            matched_orders = add_order!(book, order)
            add_trades!(book, matched_orders)
            append!(msgs, messages_from_match(matched_orders, book))
        end

        # agent sends next order message
        activation_time_diff = ceil(Int64, rand(Exponential(agent.market_rate)))
        response = copy(msg)
        response["activation_time"] += activation_time_diff
        push!(msgs, response)
    elseif msg["action"] == "CANCEL_ORDER"
        order_id = msg["order_id"]
        if order_id in keys(agent.orders)
            if params["save_cancelattions"]
                save_cancel!(simulation, order_id, agent)
            end
            cancel_order!(order_id, book, agent)
        end
    elseif msg["action"] == "UPDATE_ORDER"
        if msg["order_size"] == 0
            delete!(agent.orders, msg["order_id"])
        end
    else
        throw(error("Unknown action for a Chartist Trader."))
    end
    return msgs
end

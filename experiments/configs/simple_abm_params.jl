
agents_params = Dict(
                "MarketMaker(1)" => (3e5, 5, 0.25, 5),
                "MarketMaker(2)" => (3e6, 10, 0.5, 5),
                "MarketMaker(3)" => (1.5e6, 15, 0.25, 5),
                "MarketTaker(1)" => (3e6, 2*10^5, 2e4, 100, 5, 1.5),
                "MarketTaker(2)" => (4.5e6, 10^5, 2e4, 400, 5, 1.5),
                "MarketTaker(3)" => (1.5e6, 3*10^5, 2e4, 50, 5, 1.5),
                "Fundamentalist(1)" => (2e6, 1e6, 1.0, 0.1, 10^6, 5, 1.5),
                "Fundamentalist(2)" => (3e6, 2e6, 0.5, 0.1, 2*10^6, 5, 1.5),
                "Fundamentalist(3)" => (4e6, 2e6, 0.2, 0.1, 4*10^6, 5, 1.5),
                "Fundamentalist(4)" => (2e6, 1e6, 0.5, 0.1, 4*10^6, 5, 1.5),
                "Chartist(1)" => (2e6, 1e6, 1.0, 0.1, 10^6, 5, 1.5),
                "Chartist(2)" => (4e6, 2e6, 0.5, 0.1, 4*10^6, 5, 1.5),
                "Chartist(3)" => (2e6, 1e6, -1.0, 0.1, 10^6, 5, 1.5),
                "Chartist(4)" => (4e6, 2e6, -0.5, 0.1, 4*10^6, 5, 1.5),
                "NoiseTrader(1)" => (2e6, 1e6, 6e6, 1.0, 5, 1.5)
                )

agents_names = ["MarketMaker(1)", "MarketMaker(2)", "MarketMaker(3)",
                "MarketTaker(1)", "MarketTaker(2)", "MarketTaker(3)",
                "Fundamentalist(1)", "Fundamentalist(2)", "Fundamentalist(3)", "Fundamentalist(4)",
                "Chartist(1)", "Chartist(2)", "Chartist(3)", "Chartist(4)",
                "NoiseTrader(1)"]

"""
    init_agent(agent_name, id, params)

Initialise an agent with given name, id and parameters.
"""
function init_agent(agent_name::String, id::Int64, params::Tuple)
    agent = getfield(Main, Symbol(agent_name))(id, params...)
    return agent
end

"""
    initiate_agents(agents_params, agents_counts, agents_names)

Initialise agents with given parameters and numbers, using names to conect the two and maintain order.
"""
function initiate_agents(agents_params::Dict, agents_counts::Vector{Int64}, agents_names::Vector{String})
    agents = Dict{Int64, Agent}()

    first_i = 1
    for (j, name) in enumerate(agents_names)
        params = agents_params[name]
        for i in first_i:(first_i + agents_counts[j] - 1)
            agents[i] = init_agent(name[1:(end-3)], i, params)
        end
        first_i += agents_counts[j]
    end
    return agents
end

"""
    fill_book!(book, agents, params)

Fill the order book with initial orders.
"""
function fill_book!(book::Book, agents::Dict{Int64, Agent}, agents_counts::Vector{Int64}, params::Dict)
    asks = Dict{Float64, OrderedSet{LimitOrder}}()
    bids = Dict{Float64, OrderedSet{LimitOrder}}()

    agents_ids = collect(keys(agents))
    # we do not want market makers or takers to place initial orders
    agents_ids = agents_ids[agents_ids .> sum(agents_counts[1:6])]

    for i in 1:params["init_volume"]
        price = params["fundamental_price"] + randn() * params["init_book_sigma"]
        agent = rand(agents_ids)
        size = 1
        order = LimitOrder(
            price,
            size,
            price < params["fundamental_price"],
            i,
            agent,
            book.symbol;
            tick_size=params["tick_size"]
            )
        if order.is_bid
            place_order!(bids, order)
        else
            place_order!(asks, order)
        end
        agents[agent].orders[i] = order
    end

    book.bids = bids
    book.asks = asks
    update_best_bid!(book)
    update_best_ask!(book)
end

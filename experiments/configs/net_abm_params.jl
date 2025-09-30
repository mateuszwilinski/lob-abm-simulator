
agents_params = Dict(
    "default" => Dict( # info_rate, limit_rate, market_rate, cancel_rate, sigma, size, size_sigma, budget
                    "NetTrader" => (1000.0, 5000.0, 20000.0, 40000.0, 2.0, 5, 1.5, Budget(500, 50000.0))
                    ),
    "budget" => Dict(
                    "NetTrader" => (1000.0, 5000.0, 20000.0, 40000.0, 2.0, 5, 1.5, Budget(2, 200.0))
                    ),
    "active" => Dict(
                    "NetTrader" => (1000.0, 500.0, 2000.0, 40000.0, 2.0, 5, 1.5, Budget(100, 10000.0))
                    )
    )

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
            agents[i] = init_agent(name, i, params)
        end
        first_i += agents_counts[j]
    end
    return agents
end

"""
    connect_agents!(agents, net)

Connect agents with their neighbors according to the network edge list.
"""
function connect_agents!(agents::Dict{Int64, Agent}, net::Vector{Tuple})
    for (i, j, w) in net
        push!(agents[i].neighbors, (j, w))
        push!(agents[j].neighbors, (i, w))
    end
end

"""
    read_network(net_file)

Read network from file and return it as a list of tuples.
"""
function read_network(net_file::String)
    net = Vector{Tuple}()
    open(net_file) do f
        for line in eachline(f)
            i, j, w = split(line, ",")
            push!(net, (parse(Int64, i), parse(Int64, j), parse(Float64, w)))
        end
    end
    return net
end

"""
    fill_book!(book, agents, params)

Fill the order book with initial orders.
"""
function fill_book!(book::Book, agents::Dict{Int64, Agent}, params::Dict)
    asks = Dict{Float64, OrderedSet{LimitOrder}}()
    bids = Dict{Float64, OrderedSet{LimitOrder}}()

    for i in 1:params["init_volume"]
        price = params["fundamental_price"] + randn() * params["init_book_sigma"]
        agent = rand(keys(agents))
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

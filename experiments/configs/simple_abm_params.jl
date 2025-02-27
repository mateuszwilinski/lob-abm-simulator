
agents_params = Dict(
                "MarketMaker(1)" => (3000.0, 5, 0.25, 5),
                "MarketMaker(2)" => (30000.0, 10, 0.5, 5),
                "MarketMaker(3)" => (15000.0, 15, 0.25, 5),
                "MarketTaker(1)" => (30000.0, 2000, 200.0, 100, 5, 1.5),
                "MarketTaker(2)" => (45000.0, 1000, 200.0, 400, 5, 1.5),
                "MarketTaker(3)" => (15000.0, 3000, 200.0, 50, 5, 1.5),
                "Fundamentalist(1)" => (20000.0, 10000.0, 1.0, 0.1, 10000, 5, 1.5),
                "Fundamentalist(2)" => (30000.0, 20000.0, 0.5, 0.1, 20000, 5, 1.5),
                "Fundamentalist(3)" => (40000.0, 20000.0, 0.2, 0.1, 40000, 5, 1.5),
                "Fundamentalist(4)" => (20000.0, 10000.0, 0.5, 0.1, 40000, 5, 1.5),
                "Chartist(1)" => (20000.0, 10000.0, 1.0, 0.1, 10000, 5, 1.5),
                "Chartist(2)" => (40000.0, 20000.0, 0.5, 0.1, 40000, 5, 1.5),
                "Chartist(3)" => (20000.0, 10000.0, -1.0, 0.1, 10000, 5, 1.5),
                "Chartist(4)" => (40000.0, 20000.0, -0.5, 0.1, 40000, 5, 1.5),
                "NoiseTrader(1)" => (20000.0, 10000.0, 60000.0, 1.0, 5, 1.5)
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

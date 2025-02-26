
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

agents_counts = Dict(
                "MarketMaker(1)" => 20,
                "MarketMaker(2)" => 20,
                "MarketMaker(3)" => 20,
                "MarketTaker(1)" => 10,
                "MarketTaker(2)" => 10,
                "MarketTaker(3)" => 10,
                "Fundamentalist(1)" => 10,
                "Fundamentalist(2)" => 10,
                "Fundamentalist(3)" => 10,
                "Fundamentalist(4)" => 10,
                "Chartist(1)" => 100,
                "Chartist(2)" => 100,
                "Chartist(3)" => 100,
                "Chartist(4)" => 100,
                "NoiseTrader(1)" => 1060
                )

function init_agent(agent_name::String, id::Int64, params::Tuple)
    agent = getfield(Main, Symbol(agent_name))(id, params...)
    return agent
end

function initiate_agents(agents_params::Dict, agents_counts::Dict)
    agents = Dict{Int64, Agent}()

    first_i = 1
    for (name, params) in agents_params
        for i in first_i:(first_i + agents_counts[name] - 1)
            agents[i] = init_agent(name[1:(end-3)], i, params)
        end
        first_i += agents_counts[name]
    end
    return agents
end

function initiate_agents(mm1, mm2, mm3,
                         mt1, mt2, mt3,
                         fund1, fund2, fund3, fund4,
                         chart1, chart2, chart3, chart4,
                         nois1)
    agents = Dict{Int64, Agent}()
    first_i = 1
    last_i = mm1
    for i in first_i:last_i
        agents[i] = MarketMaker(
            i,
            3000.0,
            5,
            0.25,
            5
        )
    end
    first_i += mm1
    last_i += mm2
    for i in first_i:last_i
        agents[i] = MarketMaker(
            i,
            30000.0,
            10,
            0.5,
            5
        )
    end
    first_i += mm2
    last_i += mm3
    for i in first_i:last_i
        agents[i] = MarketMaker(
            i,
            15000.0,
            15,
            0.25,
            5
        )
    end

    first_i += mm3
    last_i += mt1
    for i in first_i:last_i
        agents[i] = MarketTaker(
            i,
            30000.0,
            2000,
            200.0,
            100,
            5,
            1.5
        )
    end
    first_i += mt1
    last_i += mt2
    for i in first_i:last_i
        agents[i] = MarketTaker(
            i,
            45000.0,
            1000,
            200.0,
            400,
            5,
            1.5
        )
    end
    first_i += mt2
    last_i += mt3
    for i in first_i:last_i
        agents[i] = MarketTaker(
            i,
            15000.0,
            3000,
            200.0,
            50,
            5,
            1.5
        )
    end
    first_i += mt3
    last_i += fund1
    for i in first_i:last_i
        agents[i] = Fundamentalist(
            i,
            20000.0,
            10000.0,
            1.0,
            0.1,
            10000,
            5,
            1.5
        )
    end
    first_i += fund1
    last_i += fund2
    for i in first_i:last_i
        agents[i] = Fundamentalist(
            i,
            30000.0,
            20000.0,
            0.5,
            0.1,
            20000,
            5,
            1.5
        )
    end
    first_i += fund2
    last_i += fund3
    for i in first_i:last_i
        agents[i] = Fundamentalist(
            i,
            40000.0,
            20000.0,
            0.2,
            0.1,
            40000,
            5,
            1.5
        )
    end
    first_i += fund3
    last_i += fund4
    for i in first_i:last_i
        agents[i] = Fundamentalist(
            i,
            20000.0,
            10000.0,
            0.5,
            0.1,
            40000,
            5,
            1.5
        )
    end
    first_i += fund4
    last_i += chart1
    for i in first_i:last_i
        agents[i] = Chartist(
            i,
            20000.0,
            10000.0,
            1.0,
            0.1,
            10000,
            5,
            1.5
        )
    end
    first_i += chart1
    last_i += chart2
    for i in first_i:last_i
        agents[i] = Chartist(
            i,
            40000.0,
            20000.0,
            0.5,
            0.1,
            40000,
            5,
            1.5
        )
    end
    first_i += chart2
    last_i += chart3
    for i in first_i:last_i
        agents[i] = Chartist(
            i,
            20000.0,
            10000.0,
            -1.0,
            0.1,
            10000,
            5,
            1.5
        )
    end
    first_i += chart3
    last_i += chart4
    for i in first_i:last_i
        agents[i] = Chartist(
            i,
            40000.0,
            20000.0,
            -0.5,
            0.1,
            40000,
            5,
            1.5
        )
    end
    first_i += chart4
    last_i += nois1
    for i in first_i:last_i
        agents[i] = NoiseTrader(
            i,
            20000.0,
            10000.0,
            60000.0,
            1.0,
            5,
            1.5
        )
    end
    if last_i < 1000
        agents[1000] = NoiseTrader(
            1000,
            20000.0,
            10000.0,
            60000.0,
            1.0,
            5,
            1.5
        )
    end
    return agents, last_i
end

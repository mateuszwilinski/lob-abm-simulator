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

include("../src/agents.jl")

function init_agents()::Dict{Int64, Agent}

    agents_1 = Dict{Int64, Agent}()
    for i in 1:1000
        agents_1[i] = NetTrader(i)
    end
    return agents_1

   return agents_1
end
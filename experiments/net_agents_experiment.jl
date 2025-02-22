include("../src/orders.jl")
include("../src/books.jl")
include("../src/agents.jl")
include("../src/saving_data.jl")
include("../src/trading.jl")
include("../src/matching.jl")
include("../src/market_state.jl")
include("../src/simulation.jl")
include("init_agents.jl")
include("../src/network.jl")

function print_agents_info(agents::Dict{Int64, Agent})
    println("Total agents: ", length(agents))
    for (id, agent) in agents
        println("Agent ID: $(agent.id)")
    end
end

function main()

    agents = init_agents()

    network, net_agents = create_graph("random_regular", agents)
    # Network
   
    print_agents_info(agents)
    println("Graph: $(network.graph)")
    for (node, agent) in net_agents
        println("Node $node -> Agent: $(agent.id)")
    end
    
end

main()
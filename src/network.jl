using Graphs
using Random
include("agents.jl")

struct Network
    graph::AbstractGraph
    network_type::String
end

function create_graph(network_type::String, agents::Dict{Int64, Agent})
    num_agents = length(agents)

    if network_type == "random_regular"
        degree = 3
        if num_agents * degree % 2 != 0
            error("Number of nodes times degree must be even for a random regular graph.")
        end

        graph = random_regular_graph(num_agents, degree)
        node_agents = Dict(i => agents[i] for i in 1:num_agents)

        network = Network(graph, network_type)
        return network, node_agents
    else
        error("Unsupported network type: $network_type")
    end
end

function get_neighborhood(net::Network, agent::Agent)
    if has_vertex(net.graph, agent.id)
        neighbors = neighbors(net.graph, agent.id)
        return neighbors
    else
        error("Agent ID $(agent.id) not found in the graph.")
    end
end

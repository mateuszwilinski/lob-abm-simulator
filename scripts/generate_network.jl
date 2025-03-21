
using Graphs
using DelimitedFiles
using Random

"""
    main()

Generates a network of a given type and saves it to a file.
"""
function main()
    # Get the network type and parameters from the command line
    network_type = try ARGS[1] catch e "erdos_renyi" end  # name of a Graphs function
    nodes_n = try parse(Int64, ARGS[2]) catch e 100 end
    edges_n = try parse(Int64, ARGS[3]) catch e 200 end
    weight = try parse(Float64, ARGS[4]) catch e 0.5 end
    seed = try parse(Int64, ARGS[5]) catch e 1 end

    # Generate the network
    Random.seed!(seed)
    if network_type == "erdos_renyi"
        g = erdos_renyi(nodes_n, edges_n)
    elseif network_type == "random_regular"
        k = Int64(2 * edges_n / nodes_n)
        g = random_regular(nodes_n, k)
    elseif network_type == "barabasi_albert"
        k = Int64(2 * edges_n / nodes_n)
        m = 2 * k + 1
        g = barabasi_albert(nodes_n, m, k)
    else
        throw(ArgumentError("Network type not recognised"))
    end
    connections = Vector{Tuple}()
    for e in edges(g)
        push!(connections, (src(e), dst(e), weight))
    end

    # Save the network
    output = string(
                "../data/nets/",
                network_type, "_",
                nodes_n, "_",
                edges_n, "_",
                seed, ".csv"
                )
    writedlm(output, connections, ',')
end

main()

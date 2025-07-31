
using Graphs
using DelimitedFiles
using Random

"""
    extended_lattice(Lx, Ly)

Generate a square lattice graph of size `Lx times Ly` with periodic
boundary conditions (2D torus), extended with diagonal connections.

Each site `(x, y)` is connected to:
- Right `(x+1, y)`
- Down `(x, y+1)`
Plus there are diagonal connections:
- Down-right diagonal `(x, y), (x+1, y+1)`
- Up-right diagonal `(x+1, y), (x, y+1)`
"""
function extended_lattice(Lx::Int64, Ly::Int64)
    N = Lx * Ly
    g = SimpleGraph(N)

    # Map (x, y) coordinates to a node index with wrapping
    idx(x, y) = ((y - 1) % Ly) * Lx + ((x - 1) % Lx) + 1

    for y in 1:Ly
        for x in 1:Lx
            v = idx(x, y)

            # Right neighbor
            add_edge!(g, v, idx(x + 1, y))
            # Down neighbor
            add_edge!(g, v, idx(x, y + 1))
            # Down-right diagonal
            add_edge!(g, v, idx(x + 1, y + 1))
            # Up-right diagonal
            add_edge!(g, idx(x + 1, y), idx(x, y + 1))
        end
    end

    return g
end

function find_lattice_dims(N::Int64)
    # Find dimensions Lx and Ly such that Lx * Ly = N
    for Lx in floor(Int64, sqrt(N)):-1:1
        if N % Lx == 0
            return (Lx, div(N, Lx))
        end
    end
    return (N, 1)  # Fallback to a single row if no factors found
end

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
    rewiring_prob = try parse(Float64, ARGS[6]) catch e 0.1 end

    # Generate the network
    Random.seed!(seed)
    if network_type == "erdos_renyi"
        g = erdos_renyi(nodes_n, edges_n)
    elseif network_type == "random_regular"
        k = Int64(2 * edges_n / nodes_n)
        g = random_regular_graph(nodes_n, k)
    elseif network_type == "watts_strogatz"
        k = Int64(2 * edges_n / nodes_n)
        g = watts_strogatz(nodes_n, k, rewiring_prob)
    elseif network_type == "barabasi_albert"
        k = Int64(edges_n / nodes_n)
        m = 2 * k + 1
        g = barabasi_albert(nodes_n, m, k, complete=true)
    elseif network_type == "extended_lattice"
        if edges_n != 4 * nodes_n
            throw(ArgumentError("For extended lattice, edges_n must be 4 times the number of nodes."))
        end
        Lx, Ly = find_lattice_dims(nodes_n)
        g = extended_lattice(Lx, Ly)
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

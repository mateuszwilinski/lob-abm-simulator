
import DataStructures: PriorityQueue, dequeue!, enqueue!

"""
    add_new_msgs(messages, new_msgs)

Add "new_msgs" to the messages queue with priority equal
to "activation_time" field for a given new message.
"""
function add_new_msgs!(messages::PriorityQueue, new_msgs::Vector{Dict})
    for msg in new_msgs
        enqueue!(messages, msg, (msg["activation_time"], msg["activation_priority"]))
    end
end

"""
    run_simulation(agents, book, messages, params)

Run simulation with "params" over the "book" with given "agents"
and initial messages up until "end_time".
"""
function run_simulation(agents::Dict{Int64, Agent}, book::Book,  # TODO: potentially Dict{String, Book} in the future
                        messages::PriorityQueue, params::Dict)
    simulation = Dict()
    simulation["current_time"] = params["initial_time"]
    simulation["last_id"] = params["first_id"]
    previous_time = params["initial_time"]
    println(simulation["current_time"], " - ", mid_price(book))  # TODO: Initial snapshot here
    # TODO:
    # There is a set of tests that could be put here.
    # For example: is the time in book equal to current time?

    # Initiate agents
    for (_, agent) in agents
        new_msgs = initiate!(agent, book, params)
        add_new_msgs!(messages, new_msgs)
    end

    # Start simulation
    snapshots = Dict{Int64, Matrix}()
    simulation["mid_price"] = zeros(params["end_time"])
    while !isempty(messages) & (simulation["current_time"] < params["end_time"])
        msg = dequeue!(messages)

        # check and set times
        if msg["activation_time"] > simulation["current_time"]
            snapshots[simulation["current_time"]] = market_depth(book)
            previous_time = simulation["current_time"]
            simulation["current_time"] = msg["activation_time"]
            book.time = simulation["current_time"]
        elseif msg["activation_time"] < simulation["current_time"]
            throw(error("Message activation time is in the past."))
        end

        # activate agent according to the priority message
        agent = agents[msg["recipient"]]
        new_msgs = action!(agent, book, agents, params, simulation, msg)
        add_new_msgs!(messages, new_msgs)

        println(simulation["current_time"], " - ", mid_price(book))
        simulation["mid_price"][previous_time:(simulation["current_time"]-1)] .=
                                                    simulation["mid_price"][previous_time]
        simulation["mid_price"][simulation["current_time"]] = mid_price(book)
        # println(simulation["current_time"], " - ", mid_price(book))
        # TODO:
        # We could generate book snapshot here.
    end
    # println(simulation["mid_price"])
    return snapshots
end

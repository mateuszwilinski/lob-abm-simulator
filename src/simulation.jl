
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
function run_simulation(agents::Dict{Int64, Agent}, book::Book,  # TODO: potentially Dict{String, Book} in th future
                        messages::PriorityQueue, params::Dict)
    current_time = params["initial_time"]
    println(current_time, " - ", mid_price(book))  # TODO: Initial snapshot here
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
    while !isempty(messages) & (current_time < params["end_time"])
        msg = dequeue!(messages)

        # check and set times
        if msg["activation_time"] > current_time
            snapshots[current_time] = market_depth(book)
            current_time = msg["activation_time"]
            book.time = current_time
        elseif msg["activation_time"] < current_time
            throw(error("Message activation time is in the past."))
        end

        # activate agent according to the priority message
        agent = agents[msg["recipient"]]
        new_msgs = action!(agent, book, agents, params, msg)
        add_new_msgs!(messages, new_msgs)

        println(current_time, " - ", mid_price(book))
        # TODO:
        # We could generate book snapshot here.
    end
    return snapshots
end

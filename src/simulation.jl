
import DataStructures: PriorityQueue, dequeue!, enqueue!

"""
    add_new_msgs(messages, new_msgs)

Add "new_msgs" to the messages queue with priority equal
to "activation_time" field for a given new message.
"""
function add_new_msgs!(messages::PriorityQueue, new_msgs::Tuple{Dict})
    for msg in new_msgs
        enqueue!(messages, msg, msg["activation_time"])
    end
end

"""
    run_simulation(agents, book, end_time, messages, params)

Run simulation with "params" over the "book" with given "agents"
and initial messages up until "end_time".
"""
function run_simulation(agents::Dict{Int64, Agent}, book::Book,  # TODO: potentially Dict{String, Book} in th future
                        end_time::Int64, messages::PriorityQueue, params::Dict)
    params["ord_id"] = 0
    current_time = params["initial_time"]
    for (_, agent) in agents
        new_msgs = initiate!(agent, book, read_params(agent, params))
        add_new_msgs!(messages, new_msgs)
    end
    while !isempty(messages) | (current_time > end_time)
        msg = dequeue!(messages)
        current_time = msg["activation_time"]
        agent = agents[msg["recipient"]]
        new_msgs = wake_up!(agent, book, msg, read_params(agent, params))
        add_new_msgs!(messages, new_msgs)
    end
    return 0
end

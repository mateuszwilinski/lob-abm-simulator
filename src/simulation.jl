
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
    update_mid_price!(simulation, new_time, book)

Update the mid price state in the simulation state dictionary.
"""
function fill_mid_price!(simulation::Dict, new_time::Int64, book::Book)
    simulation["mid_price"][simulation["current_time"]:new_time] .= mid_price(book)
end

"""
    run_simulation(agents, book, messages, params)

Run simulation with "params" over the "book" with given "agents"
and initial messages up until "end_time".
"""
function run_simulation(agents::Dict{Int64, Agent}, book::Book,
                        messages::PriorityQueue, params::Dict)
    # initiate simulation state dictionary
    simulation = Dict()
    simulation["mid_price"] = fill(NaN, params["end_time"])
    simulation["current_time"] = params["initial_time"]
    simulation["last_id"] = params["first_id"]
    if params["save_events"]
        simulation["events"] = Vector{Event}()
        if params["snapshots"]
            simulation["snapshots"] = Vector{Snapshot}()
        end
    end

    # initiate agents
    for (_, agent) in agents
        new_msgs = initiate!(agent, book, params)
        add_new_msgs!(messages, new_msgs)
    end

    # start simulation
    while !isempty(messages) & (simulation["current_time"] < params["end_time"])
        # get the next message
        msg = dequeue!(messages)
        
        # check time and update simulation state if needed
        if msg["activation_time"] > simulation["current_time"]
            # check if the simulation should end already
            if msg["activation_time"] > params["end_time"]
                fill_mid_price!(simulation, params["end_time"], book)
                simulation["current_time"] = params["end_time"]
                break
            end
            # update mid price and current time
            fill_mid_price!(simulation, msg["activation_time"]-1, book)
            simulation["current_time"] = msg["activation_time"]
        elseif msg["activation_time"] < simulation["current_time"]
            throw(error("Message activation time is in the past."))
        end

        # activate agent according to the priority message
        agent = agents[msg["recipient"]]
        new_msgs = action!(agent, book, agents, params, simulation, msg)
        add_new_msgs!(messages, new_msgs)
    end
    # make sure that the last message is included
    fill_mid_price!(simulation, params["end_time"], book)
    
    return simulation
end


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
    update_mid_price!(simulation, previous_time, current_time, book)

Update the mid price state in the simulation state dictionary.
"""
function update_mid_price!(simulation::Dict, previous_time::Int64, new_time::Int64, book::Book)
    # TODO: This part is very confusing. Needs a clear update!
    simulation["mid_price"][previous_time:(simulation["current_time"]-1)] .=
                                                simulation["mid_price"][previous_time]
    if new_time >= size(simulation["mid_price"])[1]
        simulation["mid_price"][simulation["current_time"]:end] .= mid_price(book)
    else
        simulation["mid_price"][simulation["current_time"]:(new_time-1)] .= mid_price(book)
    end
end

"""
    run_simulation(agents, book, messages, params)

Run simulation with "params" over the "book" with given "agents"
and initial messages up until "end_time".
"""
function run_simulation(agents::Dict{Int64, Agent}, book::Book,  # TODO: potentially Dict{String, Book} in the future
                        messages::PriorityQueue, params::Dict)
    # initiate simulation state dictionary
    simulation = Dict()
    simulation["mid_price"] = zeros(params["end_time"])
    simulation["events"] = Vector{Event}()
    simulation["cancellations"] = Set{Vector}()
    simulation["current_time"] = params["initial_time"]
    simulation["last_id"] = params["first_id"]
    previous_time = params["initial_time"]

    # initiate agents
    for (_, agent) in agents
        new_msgs = initiate!(agent, book, params)
        add_new_msgs!(messages, new_msgs)
    end

    # start simulation
    while !isempty(messages) & (simulation["current_time"] < params["end_time"])
        msg = dequeue!(messages)

        # check time and update simulation state if needed
        if msg["activation_time"] > simulation["current_time"]  # TODO: note that this will not save the results at end_time and initial_time
            update_mid_price!(simulation, previous_time, msg["activation_time"], book)
            if params["snapshots"]
                simulation["snapshots"][simulation["current_time"]] = market_depth(book)
            end

            previous_time = simulation["current_time"]
            simulation["current_time"] = msg["activation_time"]
        elseif msg["activation_time"] < simulation["current_time"]
            throw(error("Message activation time is in the past."))
        end

        # activate agent according to the priority message
        agent = agents[msg["recipient"]]
        new_msgs = action!(agent, book, agents, params, simulation, msg)
        add_new_msgs!(messages, new_msgs)
    end
    return simulation
end

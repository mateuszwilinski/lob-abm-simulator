
import DataStructures: PriorityQueue, dequeue!, enqueue!

"""
    messages_from_match(matched_orders, book, params)

Create messages about "matched_orders" for both affected agents and reporting agents.
"""
function messages_from_match(matched_orders::Vector{Tuple{Int64, Int64, Int64,
                                                          Int64, Int64, Float64}},
                             book::Book)
    msgs = Vector{Dict}()
    for (matched_agent, matched_order,) in matched_orders
        # send message to affected agent
        msg = Dict{String, Union{String, Int64, Float64, Bool}}()
        msg["recipient"] = matched_agent
        msg["book"] = book.symbol
        msg["activation_time"] = book.time
        msg["activation_priority"] = 0  # TODO: think through how this priority should work(!!!)
        msg["action"] = "UPDATE_ORDER"
        msg["order_id"] = matched_order  # TODO: seems like we can produce multiple same messages(!!!)
        push!(msgs, msg)
    end
    return msgs
end

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
    update_mid_price!(simulation, previous_time, book)

Update the mid price state in the simulation state dictionary.
"""
function update_mid_price!(simulation::Dict, previous_time::Int64, book::Book)
    simulation["mid_price"][previous_time:(simulation["current_time"]-1)] .=
                                                simulation["mid_price"][previous_time]
    simulation["mid_price"][simulation["current_time"]] = mid_price(book)
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
    simulation["snapshots"] = Dict{Int64, Matrix}()
    simulation["trades"] = Dict{Int64, Vector}()
    simulation["current_time"] = params["initial_time"]
    simulation["last_id"] = params["first_id"]
    previous_time = params["initial_time"]

    # initiate agents
    for (_, agent) in agents
        new_msgs = initiate!(agent, book, params)
        add_new_msgs!(messages, new_msgs)
    end

    # initial tests  # TODO: more tests to add
    if params["initial_time"] != book.time
        throw(error("Book time and initial time inconsistent."))
    end

    # start simulation
    while !isempty(messages) & (simulation["current_time"] < params["end_time"])
        msg = dequeue!(messages)

        # check time and update simulation state if needed
        if msg["activation_time"] > simulation["current_time"]
            update_mid_price!(simulation, previous_time, book)
            simulation["snapshots"][simulation["current_time"]] = market_depth(book)
            simulation["trades"][simulation["current_time"]] = market_trades(book)

            previous_time = simulation["current_time"]
            simulation["current_time"] = msg["activation_time"]
            book.time = simulation["current_time"]
            empty!(book.trades)
        elseif msg["activation_time"] < simulation["current_time"]
            throw(error("Message activation time is in the past."))
        end

        # activate agent according to the priority message
        agent = agents[msg["recipient"]]
        new_msgs = action!(agent, book, agents, params, simulation, msg)
        add_new_msgs!(messages, new_msgs)
    end
    println(simulation["trades"])
    return simulation
end

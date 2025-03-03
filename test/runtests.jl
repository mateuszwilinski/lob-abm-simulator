
using Test

include("../src/orders.jl")
include("../src/books.jl")
include("../src/agents.jl")
include("../src/agents/market_taker.jl")
include("../src/handling_order.jl")
include("../src/changing_order.jl")

# Data and setting

# Create a new limit order book
book = Book(
    Dict{Float64, OrderedSet{LimitOrder}}(),
    Dict{Float64, OrderedSet{LimitOrder}}(),
    NaN,
    NaN,
    "ABC",
    0.0
    )

agents = Dict{Int64, Agent}()
for i in 1:6
    agents[i] = Trader(
                        i,
                        Dict{Int64, LimitOrder}()
                        )
end

# Build ask and bid sides with orders
asks = Dict{Float64, OrderedSet}()
asks[11.0] = OrderedSet()
push!(asks[11.0], LimitOrder(11.0, 20, false, 1, 1, "ABC"))
agents[1].orders[asks[11.0][1].id] = asks[11.0][1]
push!(asks[11.0], LimitOrder(11.0, 210, false, 2, 2, "ABC"))
agents[2].orders[asks[11.0][2].id] = asks[11.0][2]
push!(asks[11.0], LimitOrder(11.0, 20, false, 3, 1, "ABC"))
agents[1].orders[asks[11.0][3].id] = asks[11.0][3]

bids = Dict{Float64, OrderedSet}()
bids[10.0] = OrderedSet()
push!(bids[10.0], LimitOrder(10.0, 20, true, 4, 3, "ABC"))
agents[3].orders[bids[10.0][1].id] = bids[10.0][1]
push!(bids[10.0], LimitOrder(10.0, 200, true, 5, 4, "ABC"))
agents[4].orders[bids[10.0][2].id] = bids[10.0][2]
push!(bids[10.0], LimitOrder(10.0, 100, true, 6, 5, "ABC"))
agents[5].orders[bids[10.0][3].id] = bids[10.0][3]

book.bids = bids
book.asks = asks
update_best_bid!(book)
update_best_ask!(book)

# create an incoming orders
limit_order = LimitOrder(9.0, 400, false, 7, 2, "ABC")
market_order = MarketOrder(200, true, 8, 6, "ABC")

matched_orders = add_order!(book, limit_order)
if get_size(limit_order) > 0
    agents[limit_order.agent].orders[limit_order.id] = limit_order
end
remove_matched_orders!(matched_orders, agents)

# create market taker

agent = MarketTaker(7, 3.4, 3, 0.0, 10, 2, 0.0)
simulation = Dict{String, Int64}()
simulation["last_id"] = 9
params = Dict{String, Int64}()
msg = Dict{String, Union{String, Int64, Float64, Bool}}()
msg["activation_time"] = 1
msg["action"] = "BIG_ORDER"
msgs = action!(agent, book, agents, params, simulation, msg)

#
# LOB Tests
#

@testset verbose=true "match orders" begin
    @testset "limit order" begin
        @test isnan(book.best_bid)
        @test book.best_ask == 9.0

        @test isempty(book.bids)
        @test length(book.asks) == 2
        @test length(book.asks[9.0]) == 1
        @test book.asks[9.0][1].size[] == 80
        @test length(book.asks[11.0]) == 3
        @test book.asks[11.0][1].size[] == 20
        @test book.asks[11.0][2].size[] == 210
        @test book.asks[11.0][3].size[] == 20

        @test length(agents[1].orders) == 2
        @test length(agents[2].orders) == 2
        for i in 3:6
            @test length(agents[i].orders) == 0
        end
        for i in keys(book.asks[11.0])
            @test (book.asks[11.0][i] ===
                   agents[book.asks[11.0][i].agent].orders[book.asks[11.0][i].id])
        end
    end

    matched_orders = add_order!(book, market_order)
    remove_matched_orders!(matched_orders, agents)

    @testset "market order" begin
        @test isnan(book.best_bid)
        @test book.best_ask == 11.0
    
        @test isempty(book.bids)
        @test length(book.asks) == 1
        @test length(book.asks[11.0]) == 2
        @test book.asks[11.0][1].size[] == 110
        @test book.asks[11.0][2].size[] == 20
    
        @test length(agents[1].orders) == 1
        @test length(agents[2].orders) == 1
        for i in 3:6
            @test length(agents[i].orders) == 0
        end
        for i in keys(book.asks[11.0])
            @test (book.asks[11.0][i] ===
                   agents[book.asks[11.0][i].agent].orders[book.asks[11.0][i].id])
        end
    end
end

@testset verbose=true "agents" begin
    @testset "market taker" begin
        expected_time = 1
        taker_size = 0
        for message in msgs
            if message["action"] == "MARKET_ORDER"
                expected_time += 3
                taker_size += 2
                @test message["chunk"] == 2
                @test message["activation_time"] == expected_time
            end
        end
        @test taker_size == 10
    end
end

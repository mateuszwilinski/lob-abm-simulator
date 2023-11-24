
using Test

include("../src/orders.jl")
include("../src/books.jl")
include("../src/matching.jl")

# Data

# Create a new limit order book
book = Book(
    Dict{Float64, OrderedSet}(),
    Dict{Float64, OrderedSet}(),
    NaN,
    NaN,
    Dict{Int64, LimitOrder}(),
    0,
    "ABC"
    )

# Build ask and bid sides with orders
asks = Dict{Float64, OrderedSet}()
asks[11.0] = OrderedSet()
push!(asks[11.0], LimitOrder(11.0, 20, false, 1, 1, "ABC"))
book.orders[asks[11.0][1].id] = asks[11.0][1]
push!(asks[11.0], LimitOrder(11.0, 210, false, 2, 2, "ABC"))
book.orders[asks[11.0][2].id] = asks[11.0][2]
push!(asks[11.0], LimitOrder(11.0, 20, false, 3, 1, "ABC"))
book.orders[asks[11.0][3].id] = asks[11.0][3]

bids = Dict{Float64, OrderedSet}()
bids[10.0] = OrderedSet()
push!(bids[10.0], LimitOrder(10.0, 20, true, 4, 3, "ABC"))
book.orders[bids[10.0][1].id] = bids[10.0][1]
push!(bids[10.0], LimitOrder(10.0, 200, true, 5, 4, "ABC"))
book.orders[bids[10.0][2].id] = bids[10.0][2]
push!(bids[10.0], LimitOrder(10.0, 100, true, 6, 5, "ABC"))
book.orders[bids[10.0][3].id] = bids[10.0][3]

book.bids = bids
book.asks = asks
update_best_bid!(book)
update_best_ask!(book)

# create an incoming orders
limit_order = LimitOrder(9.0, 400, false, 5, 2, "ABC")
market_order = MarketOrder(200, true, 8, 7, "ABC")

add_order!(book, limit_order)
add_order!(book, market_order)

# LOB Tests

@testset "match_order" begin
    @test isnan(book.best_bid)
    @test book.best_ask == 11.0

    @test isempty(book.bids)
    @test length(book.asks) == 1
    @test length(book.asks[11.0]) == 2
    @test book.asks[11.0][1].size[] == 110
    @test book.asks[11.0][2].size[] == 20

    @test length(book.orders) == 2
    for i in keys(book.asks[11.0])
        @test book.asks[11.0][i] === book.orders[book.asks[11.0][i].id]
    end
end

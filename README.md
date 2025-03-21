# lob-abm-simulator

Agent-based simulator of financial stock exchange with a double auction based limit order book. This project is designed to model interactions between various types of market participants in a simulated trading environment.

## Overview

The simulator implements:
- **Agent-Based Modeling:** Different agents interact using defined strategies.
- **Double Auction Market:** Simulates a limit order book where orders are matched based on price and time priority.
- **Modular Design:** Clear separation of simulation logic, experiments, examples, and tests.

## Repository Structure

- **src/:** Source code containing simulation logic, including agent definitions ([src/agents.jl](src/agents.jl)) and order book management ([src/books.jl](src/books.jl)).
- **scripts/:** Utility Julia scripts (e.g., [compute_features.jl](scripts/compute_features.jl)).
- **test/:** Unit tests for verifying simulator functionality.
- **examples/:** Example simulation scripts (e.g., [market_makers.jl](examples/market_makers.jl), [market_takers.jl](examples/market_takers.jl), [noise_traders.jl](examples/noise_traders.jl)).
- **experiments/:** Experimental scripts to initiate and run various simulations (e.g., [run_abm.jl](experiments/run_abm.jl)).
- **.gitignore:** Files and directories to ignore in version control.
- **LICENSE:** License information.

## Installation

Ensure you have [Julia](https://julialang.org) installed. Clone the repository:

```sh
git clone https://github.com/your_username/lob-abm-simulator.git
```

Install the required Julia packages:
- DataStructures
- Distributions
- Test
- DelimitedFiles
- Statistics
- Random
- StaticArrays

You can do the latter by entering Julia REPL and calling `Pkg.add`:

```julia
julia> using Pkg
julia> Pkg.add(["DataStructures", "Distributions", "Test", "DelimitedFiles", "Statistics", "Random", "StaticArrays"])
```

## Agents

The simulator includes the following types of agents:

- **Market Makers:** Agents that provide liquidity to the market by placing both buy and sell orders at different distances from the current mid price.
- **Market Takers:** Agents that consume liquidity by dividing large orders into smaller market orders, placed at different points of time.
- **Noise Traders:** Agents that trade randomly without any specific strategy, often used to simulate market noise.
- **Fundamentalists:** Agents that trade based on the fundamental value of the asset, and external to the market dynamics.
- **Chartists:** Agents that make trading decisions based on technical analysis, in this case based on price trends.
- **Net Traders:** Agents with random strategy, but able to influence other agents connected to them.

### Information Spreading Mechanism

Net traders have the ability to influence other agents connected to them. This mechanism simulates the spread of information or rumors in the market. When a net trader makes a decision to place a market or a limit order, he sends a message to his neighbor with a certain probability. Message triggers the neighbor to trade in the same direction as the net trader. These messages are sent with an exponential rate described by the net traders "info_rate" parameter. This mechanism leads to cascading process of orders appearing in the market.

## Usage

### Running Simulations

- **Examples:**  
  Explore example simulations by running a script from the examples folder. For instance:
  ```sh
  julia examples/market_takers.jl
  ```
  
- **Experiments:**  
  For experimental scenarios, run the simulation scripts from the experiments folder:
  ```sh
  julia experiments/run_abm.jl
  ```

### Testing

Unit tests are located in the test directory.

## Reference

If you find this repository useful, please cite the following article.

```bibtex
@article{wilinski2025classifying,
  title={Classifying and Clustering Trading Agents},
  author={Wilinski, Mateusz and Goel, Anubha and Iosifidis, Alexandros and Kanniainen, Juho},
}
```

## License

This project is licensed under the terms specified in the LICENSE file.

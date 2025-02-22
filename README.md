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

You can do the latter by entering Julia REPL and calling `Pkg.add`:

```julia
julia> using Pkg
julia> Pkg.add(["DataStructures", "Distributions", "Test", "DelimitedFiles", "Statistics", "Random"])
```

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

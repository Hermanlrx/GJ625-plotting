# Stellar Waves - GJ625 Radio Observation Analysis
This is version of `https://github.com/OwenJohnsons/stellar-waves.git` specifically used for radio observations of GJ625.

## Installation

This project uses [uv](https://docs.astral.sh/uv/), a fast Python package installer and resolver. 

For MacOS and Linux Install using:
`curl -LsSf https://astral.sh/uv/install.sh | sh`

```bash
# Clone and setup
git clone <repo>
cd GJ625-plotting
uv sync
```

## Running the Plotter

**Basic usage:**
```bash
uv run sw-filterbank-plot.py <filterbank.fil> -t <time_res> -b <bandwidth>
```

**Example:**
```bash
uv run sw-filterbank-plot.py /path/to/GJ625_2026-02-24T03:00:00_S0.fil -t 15 -b 80
```

**Parameters:**
- `-t`: Time resolution in seconds (default: 4s)
- `-b`: Bandwidth slice in MHz (default: 10 MHz)


## Output

Plots saved to: `dynamic_spectra/GJ625-<timestamp>/`

--




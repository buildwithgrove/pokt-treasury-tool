# POKT Treasury Tool

A shell script that calculates the total POKT balance across multiple POKT addresses, including wallet balances, app staked tokens, and node staked tokens.

## Features

- Parallel processing of multiple addresses for faster results
- Real-time balance updates with progress spinner
- Handles wallet balances, app stakes, and node stakes
- Error handling for invalid or missing data

## Prerequisites

The script requires the following dependencies:

- `bash` (version 4 or later)
- `parallel` - for processing multiple addresses concurrently
- `jq` - for parsing JSON responses
- `bc` - for decimal arithmetic
- `pocket` - https://github.com/pokt-network/pocket-core

## Installation

1. Clone or download the script
2. Make it executable:
```bash
chmod +x pokt-treasury-tool.sh
```

## Usage

Run the script by providing an address file and POKT RPC endpoint (which you can get with a free account at https://portal.grove.city):

```bash
./pokt-treasury-tool.sh <addresses_file> <POKT_URL>
```

### Arguments

- `addresses_file`: Text file containing one POKT address per line
- `POKT_URL`: URL for the POKT RPC endpoint

### Example

```bash
./pokt-treasury-tool addresses.txt https://pocket.rpc.gorve.city/v1/<your_app_id>
```

### Address File Format

Create a text file with one POKT address per line:

```text
addr1...
addr2...
addr3...
```

## Output

The script provides:

- Real-time running total with progress indicator
- Final total balance in POKT with comma formatting
- All balances are converted from uPOKT to POKT automatically

Example output:
```
[✓] Total: 5,169,682.44 POKT
```

## Error Handling

The script includes robust error handling for:
- Invalid or missing addresses
- Network connection issues
- Invalid JSON responses
- Missing or null values in responses
- Non-numeric data

## Troubleshooting

If you encounter issues:

1. Verify your addresses file format
2. Check your RPC endpoint connectivity
3. Ensure the pocket CLI tool is properly configured
4. Verify all dependencies are installed

## License

This script is available under the MIT license.

## Special Thanks
Special thanks to @FredTeumer for making the first version of this script, which was used as inspiration for this final version.
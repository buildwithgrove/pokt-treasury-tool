#!/bin/bash
# pokt-treasury-tool - A script to calculate total POKT balance across multiple addresses
# Usage: ./pokt-treasury-tool <address_file> <pokt_url>

# ANSI color codes for spinner
LIGHT_YELLOW='\033[1;33m'
LIGHT_GREEN='\033[1;32m'
NC='\033[0m'

# Show help message if no arguments provided
show_help() {
    cat << EOF
POKT Treasury Tool

Usage: 
    ./pokt-treasury-tool <addresses_file> <pokt_url>

Arguments:
    address_file    Text file containing one POKT address per line
    pokt_url        URL for the POKT RPC endpoint (e.g. https://pocket.rpc.grove.city/v1/<your_app_id>)

Example:
    ./pokt-treasury-tool addresses.txt https://pocket.rpc.grove.city/v1/<your_app_id>

The script will calculate the total balance including:
- Wallet balance
- App staked tokens
- Node staked tokens
EOF
    exit 1
}

# Check for required arguments
if [ "$#" -ne 2 ]; then
    show_help
fi

# Check if input file exists
if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found"
    exit 1
fi

# conversion factor for uPOKT -> POKT
conversion=1000000

# Configure RPC endpoint from argument
pokt_url="$2"

# Create temporary files for parallel output and running total
temp_file=$(mktemp)
total_file=$(mktemp)
echo "0" > "$total_file"

# Export pokt_url variable so it's available in the subprocess
export pokt_url

# Spinner function with color alternation
spinner() {
    local pid=$1
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        current_total=$(cat "$total_file")
        if [[ "$current_total" =~ ^[0-9]+$ ]]; then
            current_total_POKT=$(echo "scale=2 ; $current_total / $conversion" | bc)
            current_color="${LIGHT_YELLOW}"
            printf "\r${current_color}[%c]${NC} Total: %'0.2f POKT" "${spin:i++%${#spin}:1}" "$current_total_POKT"
        else
            printf "\r${current_color}[%c]${NC} Total: 0.00 POKT" "${spin:i++%${#spin}:1}"
        fi
        sleep 0.1
    done
}

# Process individual POKT addresses
process_address() {
    addr="$1"
    temp_file="$2"
    total_file="$3"
    
    # Fetch wallet balance
    balance_query=$(pocket query balance "$addr" --remoteCLIURL "$pokt_url" 2>/dev/null | sed 1d)
    balance=$(echo "$balance_query" | jq -r '.balance // "0"' 2>/dev/null)
    [[ "$balance" =~ ^[0-9]+$ ]] || balance=0

    # Fetch app staked tokens
    app_stake_query=$(pocket query app "$addr" --remoteCLIURL "$pokt_url" 2>/dev/null | sed 1d)
    appstaked=$(echo "$app_stake_query" | jq -r '.staked_tokens // "0"' 2>/dev/null)
    [[ "$appstaked" =~ ^[0-9]+$ ]] || appstaked=0

    # Fetch node staked tokens
    node_stake_query=$(pocket query node "$addr" --remoteCLIURL "$pokt_url" 2>/dev/null | sed 1d)
    nodestaked=$(echo "$node_stake_query" | jq -r '.tokens // "0"' 2>/dev/null)
    [[ "$nodestaked" =~ ^[0-9]+$ ]] || nodestaked=0

    # Calculate address total
    address_total=$((balance + appstaked + nodestaked))
    
    # Update running total using temporary file with atomic writes
    while true; do
        current_total=$(cat "$total_file")
        [[ "$current_total" =~ ^[0-9]+$ ]] || current_total=0
        new_total=$((current_total + address_total))
        echo "$new_total" > "$total_file.new"
        if mv "$total_file.new" "$total_file" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done
    
    # Output individual balances for final verification
    echo "$balance $appstaked $nodestaked" >> "$temp_file"
}

# Export the function so it can be used by parallel
export -f process_address

# Process addresses in parallel and show progress
cat "$1" | parallel process_address {} "$temp_file" "$total_file" & spinner $!

# Verify total by summing individual balances
total_sum=0
while read -r balance appstaked nodestaked; do
    if [[ "$balance" =~ ^[0-9]+$ ]] && [[ "$appstaked" =~ ^[0-9]+$ ]] && [[ "$nodestaked" =~ ^[0-9]+$ ]]; then
        total_sum=$(echo "$total_sum + $balance + $appstaked + $nodestaked" | bc)
    fi
done < "$temp_file"

# Calculate and display final total on the same line
final_total_POKT=$(echo "scale=2 ; $total_sum / $conversion" | bc)
printf "\r${LIGHT_GREEN}[✓]${NC} Total: %'0.2f POKT\n" "$final_total_POKT"

# Cleanup temporary files
rm "$temp_file" "$total_file" "$total_file.new" 2>/dev/null

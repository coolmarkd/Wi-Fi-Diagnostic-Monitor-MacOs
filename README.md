# Wi-Fi Diagnostic Monitor

A bash script for monitoring and diagnosing Wi-Fi connectivity issues on macOS systems. This tool provides real-time information about your Wi-Fi connection quality, automatically logs diagnostic data, and alerts you when connectivity problems are detected.

## Features

- **Real-time Wi-Fi Metrics**: Monitors signal strength, noise levels, transmission rates, and more
- **Connection Quality Tests**: Runs continuous ping tests to both internet and router targets
- **Performance Alerts**: Provides alerts for weak signals, high packet loss, and other connectivity issues
- **Automatic Diagnostics**: Periodically runs traceroute for deeper network path analysis
- **Comprehensive Logging**: Saves all diagnostic information to a log file for troubleshooting
- **Network Change Tracking**: Logs and alerts when SSID or BSSID changes occur

## Prerequisites

- macOS operating system
- Administrative privileges (for `wdutil` command)
- Basic command line familiarity

## Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/yourusername/wifi-monitor.git
   cd wifi-monitor
   ```

2. Make the script executable:

   ```bash
   chmod +x wifi_monitor.sh
   ```

## Usage

Simply run the script with:

```bash
./wifi_monitor.sh
```

The script will:

- Display real-time Wi-Fi connection information in the terminal
- Log detailed diagnostics to `wifi_diagnostics.log` in the same directory
- Alert you when connection quality degrades beyond specified thresholds
- Log network changes, like SSID or BSSID changes

To run the script in the background:

```bash
./wifi_monitor.sh &
```

Press `Ctrl+C` to stop the script when running in foreground.

## Configuration

You can modify these variables at the top of the script:

- `LOG_FILE`: Path to the log file
- `PING_TARGET`: IP address or hostname for internet connectivity tests
- `ROUTER_IP`: IP address of your router
- `THRESHOLD_SIGNAL`: Signal strength threshold for warnings (in dBm)
- `THRESHOLD_LOSS`: Packet loss percentage threshold for warnings
- `INTERVAL`: Time between checks (in seconds, default: 10)
- `TRACEROUTE_INTERVAL`: Time between traceroute tests (in seconds, default: 300)

## Understanding Wi-Fi Metrics

- **RSSI (Signal Strength)**: Measured in dBm
  - Excellent (100%): > -50 dBm
  - Very Good (80%): -50 to -60 dBm
  - Good (60%): -60 to -67 dBm
  - Fair (40%): -67 to -70 dBm
  - Poor (20%): < -70 dBm
  
- **Noise**: Background interference level (lower is better)
- **TX Rate**: Data transmission rate in Mbps
- **Packet Loss**: Percentage of data packets that fail to reach their destination
- **Latency**: Time for data to travel to destination and back (in milliseconds)
- **DNS Time**: Time to resolve domain names (in milliseconds)

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgements

- Uses macOS built-in `wdutil` utility for Wi-Fi diagnostics
- Uses standard Unix networking tools: ping, traceroute, and dig
- Inspired by the need for better Wi-Fi troubleshooting tools

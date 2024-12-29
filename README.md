# Hysteria 2 Auto Installer

This script automatically installs and configures Hysteria 2 server with secure defaults and automatic configuration.

## Features

- One-command installation
- Automatic IP detection
- Secure default configuration
- TLS certificate generation
- Automatic service configuration
- Client configuration generation

## Quick Start

To install Hysteria 2, run this command on your server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yusefes/Hysteria2/main/setup_hysteria2.sh)
```

## Requirements

- Ubuntu/Debian-based system
- Root access
- Port 443 available

## What it does

1. Installs required packages
2. Installs Hysteria 2
3. Generates TLS certificates
4. Configures the server
5. Sets up the service
6. Generates client configuration

## Security Features

- Automatic password generation
- TLS encryption
- Salamander obfuscation
- Secure default settings

## After Installation

The script will display a client configuration URL that can be used in Hysteria 2 clients.

## Troubleshooting

If you encounter any issues:
1. Check if port 443 is available
2. Verify your system meets the requirements
3. Check the logs with: `journalctl -u hysteria-server.service`

## License

MIT License

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

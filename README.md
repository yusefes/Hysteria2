# Hysteria2 Auto Installer

This script automatically installs and configures Hysteria2 on your VPS with randomly generated ports and passwords for enhanced security.

## Features

- Automatic installation of Hysteria2
- Random port generation
- Secure password generation
- Automatic IP detection
- Self-signed certificate generation
- Systemd service configuration
- Client configuration generation

## Requirements

- Ubuntu/Debian based system
- Root access
- Clean VPS (recommended)

## Quick Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yusefes/Hysteria2/main/setup_hysteria2.sh)
```

## What it does

1. Updates system packages
2. Installs Hysteria2
3. Generates necessary certificates
4. Configures Hysteria2 with secure settings
5. Sets up and starts systemd service
6. Provides ready-to-use client configuration

## Supported Clients

- Hiddify (Android, iOS, macOS, Windows)
- v2rayN (Windows)
- v2rayNG (Android)
- Streisand (iOS)

## Security Considerations

- Random port assignment reduces targeted scanning
- Unique passwords generated for each installation
- Self-signed certificates for encrypted connections
- Automatic service configuration and startup

## License

MIT License

## Disclaimer

This project is for educational purposes only. Users are responsible for ensuring compliance with local laws and regulations regarding VPN usage.

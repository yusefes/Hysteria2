# Hysteria2 Auto Installer

This script automates the installation and configuration of Hysteria2 on a Linux server.

## Prerequisites

- A Linux VPS with SSH access.
- Sudo privileges for the user.
- wget and curl installed on the server.

## Installation

1. Connect to your server via SSH.
2. Run the following command to install and configure Hysteria2:

   ```bash
   wget -O - https://github.com/yusefes/Hysteria2/raw/main/setup_hysteria2.sh | bash

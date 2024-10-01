## Public IP Menu Bar Application

### Motivation

As software engineers, we often find ourselves needing to interact with web applications from different IP addresses, especially when testing or debugging. Constantly checking external websites to verify your public IP can be cumbersome and time-consuming. This application aims to streamline that process by providing an always-visible, automatically updating display of your current public IP address right in your menu bar.

Whether you're working with geolocation features, testing region-specific content, or simply need to keep track of your public IP for security reasons, this tool offers a convenient solution. By eliminating the need to repeatedly visit IP-checking websites, it helps maintain your workflow and productivity.

### Overview

This macOS menu bar application displays your current public IP address and allows you to easily configure proxy settings for your system. It provides a simple and convenient way to monitor your public IP and manage proxy configurations without diving into system preferences.

### Features

- Public IP Display: Shows your current public IP address directly in the menu bar.
- Automatic IP Updates: Refreshes your public IP every 3 minutes to ensure up-to-date information.
- Proxy Configuration: Offers a user-friendly interface to set up and manage proxy settings for your macOS system.
- Multiple Proxy Types: Supports HTTP, HTTPS, and SOCKS5 proxy configurations.
- Network Service Selection: Allows you to choose which network service to configure (e.g., Wi-Fi, Ethernet).
- Proxy Authentication: Provides fields for username and password if your proxy requires authentication.

### How It Works

- The application uses the ipify.com API to fetch your current public IP address.
- It updates the IP address displayed in the menu bar every 3 minutes.
- When configuring proxy settings, the app uses macOS system commands to apply the changes, ensuring they take effect system-wide.

### Usage

- Launch the application. Your public IP will appear in the menu bar.
- Click on the menu bar icon to access the dropdown menu.
- Select "Configure Proxy Settings" to open the configuration window.
- Choose your network service, proxy type, and enter the necessary details.
- Click "Apply" to set the proxy configuration. You'll be prompted for administrator privileges to make system changes.
- Use the "Reset" button to remove the proxy settings when needed.

### Privacy and Security

This application only fetches your public IP address from ipify.com. It does not collect or transmit any personal data. All proxy configurations are applied locally to your system settings.

### License

This project is released into the public domain using The Unlicense.
This means you can use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software without restriction and without need for attribution.

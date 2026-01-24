# Taildrop Plugin

A Tailscale Taildrop plugin for Noctalia that allows you to send and receive files between devices in your tailnet.

> **Disclaimer:** This is a community-created plugin built on top of the great Tailscale CLI tool. It is not affiliated with, endorsed by, or officially connected to Tailscale Inc.

## Features

- **Send Files**: Select devices from your tailnet and send files via drag-and-drop or file picker
- **Receive Files**: Download files sent to you via Taildrop with automatic privilege handling
- **Device Selection**: Visual device picker showing online peers with OS icons
- **Mode Switcher**: Easy toggle between Send and Receive modes
- **Floating Window**: Clean overlay window that appears at the top of your screen
- **File Management**: View, open, and browse received files
- **Bar Widget**: Quick access icon in your menu bar

## Requirements

- Tailscale must be installed on your system
- Tailscale must be set up and authenticated
- `pkexec` for privilege escalation (usually pre-installed on most Linux distributions)

## Settings

| Setting | Default | Description |
|---|---|---|
| `receiveDirectory` | `~/Downloads/Taildrop` | Directory where received files are saved (supports ~ for home) |

## Usage

### Sending Files

1. Click the Taildrop icon in your menu bar
2. Click the "Send" tab (default)
3. Select a device from your tailnet
4. Drag files into the drop zone or click to browse
5. Click "Send Files"

### Receiving Files

1. Click the Taildrop icon in your menu bar
2. Click the "Receive" tab
3. Click the refresh button to download any pending files
4. Files are automatically saved to your configured directory
5. Click on any file to open it, or use the folder icon to browse all received files

## How It Works

### Sending
Files are sent using the `tailscale file cp` command to the selected device's Tailscale IP or hostname.

### Receiving
When you click "Receive", the plugin:
1. Creates the receive directory if it doesn't exist
2. Runs `tailscale file get` with privilege escalation (using `pkexec`)
3. Downloads all pending files to your configured directory
4. Changes ownership of the files from root to your user
5. Scans and displays the files in the UI

## Troubleshooting

### "No online devices available"
- Make sure your Tailscale network is connected
- Check that other devices in your tailnet are online
- Tagged devices are hidden by default (only user devices are shown)

### Privilege escalation dialog appears
This is normal when receiving files. Tailscale's daemon runs as root, so files must be retrieved with elevated privileges. The plugin automatically fixes file ownership after download.

### Files not appearing in receive list
- Click the refresh button to check for new files
- Check the configured receive directory for files
- Verify Tailscale is running and connected

## IPC Commands

You can control the Taildrop window via the command line:

```bash
# Open the Taildrop window
qs -c noctalia-shell ipc call plugin:taildrop open
```

## Integration with Tailscale Plugin

This plugin works independently but pairs well with the Tailscale status plugin. Both plugins can be installed and used together:
- **Tailscale Plugin**: Shows connection status, peer list, IP management
- **Taildrop Plugin**: Handles file sending and receiving

## License

MIT

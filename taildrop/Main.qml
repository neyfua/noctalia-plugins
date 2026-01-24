import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  readonly property string receiveDirectory: {
    var dir = pluginApi?.pluginSettings?.receiveDirectory || "~/Downloads/Taildrop"
    // Expand ~ to home directory
    if (dir.startsWith("~/")) {
      return Quickshell.env("HOME") + dir.substring(1)
    }
    return dir
  }

  property bool tailscaleInstalled: false
  property bool tailscaleRunning: false
  property var peerList: []

  // Helper to filter IPv4 addresses from Tailscale (100.x.x.x range)
  function filterIPv4(ips) {
    if (!ips || !ips.length) return []
    return ips.filter(ip => ip.startsWith("100."))
  }

  Process {
    id: whichProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      root.tailscaleInstalled = (exitCode === 0)
      if (root.tailscaleInstalled) {
        updateTailscaleStatus()
      }
    }
  }

  Process {
    id: statusProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      var stdout = String(statusProcess.stdout.text || "").trim()

      if (exitCode === 0 && stdout && stdout.length > 0) {
        try {
          var data = JSON.parse(stdout)
          root.tailscaleRunning = data.BackendState === "Running"

          if (root.tailscaleRunning && data.Peer) {
            var peers = []
            for (var peerId in data.Peer) {
              var peer = data.Peer[peerId]
              var ipv4s = filterIPv4(peer.TailscaleIPs)
              peers.push({
                "HostName": peer.HostName,
                "DNSName": peer.DNSName,
                "TailscaleIPs": ipv4s,
                "Online": peer.Online,
                "OS": peer.OS,
                "Tags": peer.Tags || []
              })
            }
            root.peerList = peers
          } else {
            root.peerList = []
          }
        } catch (e) {
          root.tailscaleRunning = false
          root.peerList = []
        }
      } else {
        root.tailscaleRunning = false
        root.peerList = []
      }
    }
  }

  function checkTailscaleInstalled() {
    whichProcess.command = ["which", "tailscale"]
    whichProcess.running = true
  }

  function updateTailscaleStatus() {
    if (!root.tailscaleInstalled) {
      root.tailscaleRunning = false
      root.peerList = []
      return
    }

    statusProcess.command = ["tailscale", "status", "--json"]
    statusProcess.running = true
  }

  Timer {
    id: updateTimer
    interval: 10000 // Update every 10 seconds
    repeat: true
    running: true
    triggeredOnStart: true

    onTriggered: {
      if (root.tailscaleInstalled === false) {
        checkTailscaleInstalled()
      } else {
        updateTailscaleStatus()
      }
    }
  }

  Component.onCompleted: {
    checkTailscaleInstalled()
  }

  IpcHandler {
    target: "plugin:taildrop"

    function open() {
      // Note: IPC doesn't have screen context, so this won't work perfectly
      // Users should click the bar widget instead
      console.warn("Taildrop: IPC open() called but no screen context available. Please click the bar widget instead.")
    }
  }
}

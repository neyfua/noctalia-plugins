import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  readonly property var mainInstance: pluginApi?.mainInstance

  // SmartPanel properties
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true
  property real contentPreferredWidth: 500 * Style.uiScaleRatio
  property real contentPreferredHeight: 600 * Style.uiScaleRatio

  anchors.fill: parent

  NFilePicker {
    id: filePicker
    selectionMode: "files"
    title: pluginApi?.tr("select-files") || "Select Files to Send"
    initialPath: Quickshell.env("HOME")
    onAccepted: paths => {
      if (paths.length > 0) {
        root.pendingFiles = paths
      }
    }
  }

  readonly property var sortedPeerList: {
    if (!mainInstance?.peerList) return []
    var peers = mainInstance.peerList.slice()
    
    // Only show online peers that are not tagged
    peers = peers.filter(function(peer) {
      return peer.Online === true && (!peer.Tags || peer.Tags.length === 0)
    })
    
    peers.sort(function(a, b) {
      var nameA = (a.HostName || a.DNSName || "").toLowerCase()
      var nameB = (b.HostName || b.DNSName || "").toLowerCase()
      return nameA.localeCompare(nameB)
    })
    return peers
  }

  function filterIPv4(ips) {
    return mainInstance?.filterIPv4(ips) || []
  }

  function getOSIcon(os) {
    if (!os) return "device-desktop"
    switch (os.toLowerCase()) {
      case "linux":
        return "brand-debian"
      case "macos":
        return "brand-apple"
      case "ios":
        return "device-mobile"
      case "android":
        return "device-mobile"
      case "windows":
        return "brand-windows"
      default:
        return "device-desktop"
    }
  }

  property var selectedPeer: null
  property string selectedPeerHostname: ""
  property var pendingFiles: []
  property bool isTransferring: false
  property string transferStatus: ""
  property string mode: "send" // "send" or "receive"
  property var receivedFiles: []
  property bool isLoadingReceived: false
  readonly property string taildropDir: mainInstance?.receiveDirectory || (Quickshell.env("HOME") + "/Downloads/Taildrop")

  Component.onCompleted: {
    // Reset to send mode when panel is created
    mode = "send"
  }

  Process {
    id: fileTransferProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      root.isTransferring = false
      if (exitCode === 0) {
        var hostname = root.selectedPeer?.HostName || "device"
        var message = (pluginApi?.tr("transfer-success.message") || "Files successfully sent to %1").replace("%1", hostname)
        ToastService.showNotice(
          pluginApi?.tr("transfer-success.title") || "Files Sent",
          message,
          "check"
        )
        root.pendingFiles = []
        root.transferStatus = ""
      } else {
        var stderr = String(fileTransferProcess.stderr.text || "").trim()
        ToastService.showError(
          pluginApi?.tr("transfer-error.title") || "Transfer Failed",
          stderr || (pluginApi?.tr("transfer-error.message") || "Failed to send files"),
          "alert-circle"
        )
        root.transferStatus = ""
      }
    }
  }

  Process {
    id: receiveFilesProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      root.isLoadingReceived = false
      if (exitCode === 0) {
        var output = String(receiveFilesProcess.stdout.text || "").trim()
        // After receiving, scan the directory
        root.scanReceivedFiles()
        
        if (output && output.indexOf("no files") === -1) {
          ToastService.showNotice(
            pluginApi?.tr("receive-success.title") || "Files Received",
            pluginApi?.tr("receive-success.message") || "Files downloaded successfully",
            "inbox"
          )
        }
      } else {
        var stderr = String(receiveFilesProcess.stderr.text || "").trim()
        if (stderr.indexOf("no files") === -1 && stderr.indexOf("nothing") === -1) {
          ToastService.showError(
            pluginApi?.tr("receive-error.title") || "Receive Failed",
            stderr || (pluginApi?.tr("receive-error.message") || "Failed to receive files"),
            "alert-circle"
          )
        }
        root.scanReceivedFiles()
      }
    }
  }

  Process {
    id: scanDirProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        var output = String(scanDirProcess.stdout.text || "").trim()
        if (output) {
          var lines = output.split('\n')
          var files = []
          for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line && line !== root.taildropDir) {
              files.push(line)
            }
          }
          root.receivedFiles = files
        } else {
          root.receivedFiles = []
        }
      } else {
        root.receivedFiles = []
      }
    }
  }

  function sendFiles() {
    if (!selectedPeer || pendingFiles.length === 0) return
    
    isTransferring = true
    transferStatus = pluginApi?.tr("transferring") || "Sending files..."
    
    var target = filterIPv4(selectedPeer.TailscaleIPs)[0] || selectedPeer.HostName
    var args = ["file", "cp"]
    
    for (var i = 0; i < pendingFiles.length; i++) {
      args.push(pendingFiles[i])
    }
    
    args.push(target + ":")
    
    fileTransferProcess.command = ["tailscale"].concat(args)
    fileTransferProcess.running = true
  }

  function loadReceivedFiles() {
    isLoadingReceived = true
    // First ensure the directory exists
    Quickshell.execDetached(["mkdir", "-p", root.taildropDir])
    // Then run sudo tailscale file get to download files to that directory
    receiveFilesProcess.command = ["pkexec", "sh", "-c", "tailscale file get '" + root.taildropDir + "' && chown -R $SUDO_UID:$SUDO_GID '" + root.taildropDir + "'"]
    receiveFilesProcess.running = true
  }

  function scanReceivedFiles() {
    // Scan the Taildrop directory for files
    scanDirProcess.command = ["find", root.taildropDir, "-type", "f"]
    scanDirProcess.running = true
  }

  function openReceivedFile(filePath) {
    Quickshell.execDetached(["xdg-open", filePath])
  }

  function openTaildropFolder() {
    Quickshell.execDetached(["xdg-open", root.taildropDir])
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    Rectangle {
      id: windowContent
      anchors.fill: parent
      anchors.margins: Style.marginL
      color: Color.mSurface
      radius: Style.radiusL
      border.width: 1
      border.color: Color.mOutline

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginL

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: root.mode === "send" ? "send" : "inbox"
          pointSize: Style.fontSizeL
          color: Color.mPrimary
        }

        NText {
          text: root.mode === "send" 
            ? (pluginApi?.tr("title.send") || "Send Files via Taildrop")
            : (pluginApi?.tr("title.receive") || "Receive Files via Taildrop")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "x"
          onClicked: {
            // Panel visibility is managed by the panel system
            // Clicking outside the panel will close it
          }
        }
      }

      // Mode switcher
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NButton {
          text: pluginApi?.tr("mode.send") || "Send"
          icon: "send"
          Layout.fillWidth: true
          backgroundColor: root.mode === "send" ? Color.mPrimary : "transparent"
          textColor: root.mode === "send" ? Color.mOnPrimary : Color.mOnSurface
          onClicked: root.mode = "send"
        }

        NButton {
          text: pluginApi?.tr("mode.receive") || "Receive"
          icon: "inbox"
          Layout.fillWidth: true
          backgroundColor: root.mode === "receive" ? Color.mPrimary : "transparent"
          textColor: root.mode === "receive" ? Color.mOnPrimary : Color.mOnSurface
          onClicked: {
            root.mode = "receive"
            root.loadReceivedFiles()
          }
        }
      }

      // Device selection (Send mode only)
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: 200
        visible: root.mode === "send"

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            text: pluginApi?.tr("select-device") || "Select a device:"
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightMedium
            color: Color.mOnSurface
          }

          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: deviceColumn.height
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: deviceColumn
              width: parent.width
              spacing: Style.marginS

              Repeater {
                model: root.sortedPeerList

                delegate: ItemDelegate {
                  id: deviceDelegate
                  Layout.fillWidth: true
                  height: 48
                  topPadding: Style.marginS
                  bottomPadding: Style.marginS
                  leftPadding: Style.marginM
                  rightPadding: Style.marginM

                  readonly property var peerData: modelData
                  readonly property string peerHostname: peerData.HostName || peerData.DNSName || "Unknown"
                  readonly property bool isSelected: root.selectedPeerHostname === peerHostname

                  background: Rectangle {
                    anchors.fill: parent
                    color: deviceDelegate.isSelected 
                      ? Qt.alpha(Color.mPrimary, 0.2)
                      : (deviceDelegate.hovered ? Qt.alpha(Color.mPrimary, 0.1) : "transparent")
                    radius: Style.radiusM
                    border.width: deviceDelegate.isSelected ? 2 : (deviceDelegate.hovered ? 1 : 0)
                    border.color: deviceDelegate.isSelected ? Color.mPrimary : Qt.alpha(Color.mPrimary, 0.3)
                  }

                  contentItem: RowLayout {
                    spacing: Style.marginM

                    NIcon {
                      icon: root.getOSIcon(deviceDelegate.peerData.OS)
                      pointSize: Style.fontSizeM
                      color: deviceDelegate.isSelected ? Color.mPrimary : Color.mOnSurface
                    }

                    NText {
                      text: deviceDelegate.peerHostname
                      color: deviceDelegate.isSelected ? Color.mPrimary : Color.mOnSurface
                      font.weight: deviceDelegate.isSelected ? Style.fontWeightBold : Style.fontWeightMedium
                      Layout.fillWidth: true
                    }

                    NIcon {
                      icon: "check"
                      pointSize: Style.fontSizeS
                      color: Color.mPrimary
                      visible: deviceDelegate.isSelected
                    }
                  }

                  onClicked: {
                    root.selectedPeer = deviceDelegate.peerData
                    root.selectedPeerHostname = deviceDelegate.peerHostname
                  }
                }
              }

              NText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.marginL
                text: pluginApi?.tr("no-devices") || "No online devices available"
                visible: root.sortedPeerList.length === 0
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }
        }
      }

      // Drop zone (Send mode only)
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.mode === "send"
        color: dropArea.containsDrag ? Qt.alpha(Color.mPrimary, 0.1) : Qt.alpha(Color.mSurfaceVariant, 0.5)
        radius: Style.radiusM
        border.width: 2
        border.color: dropArea.containsDrag ? Color.mPrimary : Qt.alpha(Color.mOutline, 0.3)

        DropArea {
          id: dropArea
          anchors.fill: parent

          onDropped: function(drop) {
            if (drop.hasUrls) {
              var files = []
              for (var i = 0; i < drop.urls.length; i++) {
                var url = drop.urls[i].toString()
                if (url.startsWith("file://")) {
                  files.push(url.substring(7))
                }
              }
              root.pendingFiles = files
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          enabled: !root.isTransferring
          onClicked: {
            filePicker.openFilePicker()
          }
        }

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM
          width: parent.width - Style.marginL * 2

          NIcon {
            icon: root.pendingFiles.length > 0 ? "files" : "upload"
            pointSize: Style.fontSizeXL * 2
            color: dropArea.containsDrag ? Color.mPrimary : Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: {
              if (root.isTransferring) {
                return root.transferStatus
              } else if (root.pendingFiles.length > 0) {
                return (pluginApi?.tr("files-ready") || "%1 file(s) ready to send").replace("%1", root.pendingFiles.length)
              } else if (dropArea.containsDrag) {
                return pluginApi?.tr("drop-here") || "Drop files here"
              } else {
                return pluginApi?.tr("drop-zone") || "Click to browse or drag files here"
              }
            }
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightMedium
            color: dropArea.containsDrag ? Color.mPrimary : Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: root.pendingFiles.length > 0 
              ? root.pendingFiles.join("\n")
              : (pluginApi?.tr("drop-hint") || "Multiple file selection supported")
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            visible: !root.isTransferring
            elide: Text.ElideMiddle
            maximumLineCount: 5
          }

          NButton {
            text: pluginApi?.tr("clear-files") || "Clear Files"
            icon: "x"
            visible: root.pendingFiles.length > 0 && !root.isTransferring
            onClicked: root.pendingFiles = []
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }

      // Received files list (Receive mode only)
      NBox {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.mode === "receive"

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NText {
              text: pluginApi?.tr("received-files") || "Received Files"
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightMedium
              color: Color.mOnSurface
              Layout.fillWidth: true
            }

            NIconButton {
              icon: "folder-open"
              onClicked: root.openTaildropFolder()
            }

            NIconButton {
              icon: "refresh"
              enabled: !root.isLoadingReceived
              onClicked: root.loadReceivedFiles()
            }
          }

          NText {
            Layout.fillWidth: true
            text: (pluginApi?.tr("receive-hint") || "Files are saved to: %1").replace("%1", root.taildropDir)
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.Wrap
          }

          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: receivedFilesColumn.height
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: receivedFilesColumn
              width: parent.width
              spacing: Style.marginS

              Repeater {
                model: root.receivedFiles

                delegate: ItemDelegate {
                  Layout.fillWidth: true
                  height: 48
                  topPadding: Style.marginS
                  bottomPadding: Style.marginS
                  leftPadding: Style.marginM
                  rightPadding: Style.marginM

                  readonly property string fileName: {
                    var filePath = modelData
                    var parts = filePath.split('/')
                    return parts[parts.length - 1]
                  }

                  background: Rectangle {
                    anchors.fill: parent
                    color: parent.hovered ? Qt.alpha(Color.mPrimary, 0.1) : "transparent"
                    radius: Style.radiusM
                    border.width: parent.hovered ? 1 : 0
                    border.color: Qt.alpha(Color.mPrimary, 0.3)
                  }

                  contentItem: RowLayout {
                    spacing: Style.marginM

                    NIcon {
                      icon: "file"
                      pointSize: Style.fontSizeM
                      color: Color.mPrimary
                    }

                    NText {
                      text: parent.parent.fileName
                      color: Color.mOnSurface
                      font.weight: Style.fontWeightMedium
                      elide: Text.ElideMiddle
                      Layout.fillWidth: true
                    }

                    NIcon {
                      icon: "external-link"
                      pointSize: Style.fontSizeS
                      color: Color.mOnSurfaceVariant
                    }
                  }

                  onClicked: root.openReceivedFile(modelData)
                }
              }

              NText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.marginL
                text: root.isLoadingReceived 
                  ? (pluginApi?.tr("loading") || "Loading...")
                  : (pluginApi?.tr("no-received-files") || "No files received yet")
                visible: root.receivedFiles.length === 0
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }
        }
      }

      // Action buttons (Send mode only)
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        visible: root.mode === "send"

        NButton {
          text: pluginApi?.tr("cancel") || "Cancel"
          Layout.fillWidth: true
          enabled: !root.isTransferring
          onClicked: {
            root.pendingFiles = []
            root.selectedPeer = null
            root.selectedPeerHostname = ""
            root.transferStatus = ""
          }
        }

        NButton {
          text: pluginApi?.tr("send") || "Send Files"
          icon: "send"
          backgroundColor: Color.mPrimary
          textColor: Color.mOnPrimary
          Layout.fillWidth: true
          enabled: root.selectedPeer !== null && root.pendingFiles.length > 0 && !root.isTransferring
          onClicked: root.sendFiles()
        }
      }
    }
    }
  }
}

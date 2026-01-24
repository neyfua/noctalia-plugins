import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property bool pillDirection: BarService.getPillDirection(root)
  readonly property var mainInstance: pluginApi?.mainInstance

  implicitWidth: Style.capsuleHeight
  implicitHeight: Style.capsuleHeight

  color: Style.capsuleColor
  radius: Style.radiusL

  NIcon {
    anchors.centerIn: parent
    icon: "send"
    pointSize: Style.fontSizeL
    color: {
      if (!(mainInstance?.tailscaleRunning ?? false)) {
        return mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurfaceVariant
      }
      return Color.mPrimary
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("actions.widget-settings") || "Widget Settings",
        "action": "widget-settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
      var popupMenuWindow = PanelService.getPopupMenuWindow(screen)
      if (popupMenuWindow) {
        popupMenuWindow.close()
      }

      if (action === "widget-settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest)
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: {
      root.color = Color.mHover
    }

    onExited: {
      root.color = Style.capsuleColor
    }

    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) {
          pluginApi.openPanel(root.screen, root)
        }
      } else if (mouse.button === Qt.RightButton) {
        var popupMenuWindow = PanelService.getPopupMenuWindow(screen)
        if (popupMenuWindow) {
          popupMenuWindow.showContextMenu(contextMenu)
          contextMenu.openAtItem(root, screen)
        }
      }
    }
  }
}

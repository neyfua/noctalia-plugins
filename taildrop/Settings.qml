import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  // Local state - initialized from saved settings or defaults
  property string editReceiveDirectory:
    pluginApi?.pluginSettings?.receiveDirectory ||
    pluginApi?.manifest?.metadata?.defaultSettings?.receiveDirectory ||
    "~/Downloads/Taildrop"

  spacing: Style.marginL

  NText {
    text: pluginApi?.tr("settings.title") || "Taildrop Settings"
    pointSize: Style.fontSizeXL
    font.weight: Style.fontWeightBold
    color: Color.mOnSurface
  }

  NText {
    text: pluginApi?.tr("settings.description") || "Configure Taildrop file transfer settings"
    pointSize: Style.fontSizeM
    color: Color.mOnSurfaceVariant
    Layout.bottomMargin: Style.marginM
  }

  // Receive Directory
  NText {
    text: pluginApi?.tr("settings.receive-directory") || "Receive Directory"
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightMedium
    color: Color.mOnSurface
  }

  NTextField {
    Layout.fillWidth: true
    placeholderText: "~/Downloads/Taildrop"
    text: root.editReceiveDirectory
    onTextChanged: {
      root.editReceiveDirectory = text
    }
  }

  NText {
    text: pluginApi?.tr("settings.receive-directory-desc") || "Directory where received files are saved (supports ~ for home)"
    pointSize: Style.fontSizeS
    color: Color.mOnSurfaceVariant
    Layout.bottomMargin: Style.marginL
  }

  Item {
    Layout.fillHeight: true
  }

  // Action buttons
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    Item { Layout.fillWidth: true }

    NButton {
      text: pluginApi?.tr("settings.reset") || "Reset to Defaults"
      onClicked: {
        root.editReceiveDirectory = pluginApi?.manifest?.metadata?.defaultSettings?.receiveDirectory || "~/Downloads/Taildrop"
      }
    }

    NButton {
      text: pluginApi?.tr("settings.save") || "Save"
      backgroundColor: Color.mPrimary
      textColor: Color.mOnPrimary
      onClicked: {
        if (pluginApi) {
          pluginApi.updatePluginSettings({
            "receiveDirectory": root.editReceiveDirectory
          })
        }
      }
    }
  }
}

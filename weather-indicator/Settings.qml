import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property bool showTempValue: pluginApi?.pluginSettings?.showTempValue ?? true
  property bool showConditionIcon: pluginApi?.pluginSettings?.showConditionIcon ?? true
  property bool showTempUnit: pluginApi?.pluginSettings?.showTempUnit ?? true

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("WeatherIndicator", "Settings UI loaded");
  }

  NToggle {
    id: toggleIcon
    label: pluginApi?.tr("settings.showConditionIcon.label") || "showConditionIcon"
    description: pluginApi?.tr("settings.showConditionIcon.desc") || "Show the condition icon"
    checked: root.showConditionIcon
    onToggled: checked => {
      root.showConditionIcon = checked;
      root.showTempValue = true;
    }
  }

  NToggle {
    id: toggleTempText
    label: pluginApi?.tr("settings.showTempValue.label") || "showTempValue"
    description: pluginApi?.tr("settings.showTempValue.desc") || "Show the temperature"
    checked: root.showTempValue
    onToggled: checked => {
      root.showTempValue = checked;
      root.showConditionIcon = true;
    }
  }

  NToggle {
    id: toggleTempLetter
    label: pluginApi?.tr("settings.showTempUnit.label") || "showTempUnit"
    description: pluginApi?.tr("settings.showTempUnit.desc") || "Show temperature letter (°F or °C)"
    checked: root.showTempUnit
    visible: root.showTempValue
    onToggled: checked => {
      root.showTempUnit = checked;
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("WeatherIndicator", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.showTempValue = root.showTempValue;
    pluginApi.pluginSettings.showConditionIcon = root.showConditionIcon;
    pluginApi.pluginSettings.showTempUnit = root.showTempUnit;

    pluginApi.saveSettings();

    Logger.i("WeatherIndicator", "Settings saved successfully");
    pluginApi.closePanel(root.screen);
  }
}

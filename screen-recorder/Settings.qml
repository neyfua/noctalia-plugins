import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root
    spacing: Style.marginL

    property var pluginApi: null

    property string editDirectory: 
        pluginApi?.pluginSettings?.directory || 
        pluginApi?.manifest?.metadata?.defaultSettings?.directory || 
        ""

    property string editFilenamePattern: 
        pluginApi?.pluginSettings?.filenamePattern || 
        pluginApi?.manifest?.metadata?.defaultSettings?.filenamePattern || 
        "recording_yyyyMMdd_HHmmss"

    property string editFrameRate: 
        pluginApi?.pluginSettings?.frameRate || 
        pluginApi?.manifest?.metadata?.defaultSettings?.frameRate || 
        "60"

    property string editAudioCodec: 
        pluginApi?.pluginSettings?.audioCodec || 
        pluginApi?.manifest?.metadata?.defaultSettings?.audioCodec || 
        "opus"

    property string editVideoCodec: 
        pluginApi?.pluginSettings?.videoCodec || 
        pluginApi?.manifest?.metadata?.defaultSettings?.videoCodec || 
        "h264"

    property string editQuality: 
        pluginApi?.pluginSettings?.quality || 
        pluginApi?.manifest?.metadata?.defaultSettings?.quality || 
        "very_high"

    property string editColorRange: 
        pluginApi?.pluginSettings?.colorRange || 
        pluginApi?.manifest?.metadata?.defaultSettings?.colorRange || 
        "limited"

    property bool editShowCursor: 
        pluginApi?.pluginSettings?.showCursor ?? 
        pluginApi?.manifest?.metadata?.defaultSettings?.showCursor ?? 
        true

    property bool editCopyToClipboard: 
        pluginApi?.pluginSettings?.copyToClipboard ?? 
        pluginApi?.manifest?.metadata?.defaultSettings?.copyToClipboard ?? 
        false

    property string editAudioSource: 
        pluginApi?.pluginSettings?.audioSource || 
        pluginApi?.manifest?.metadata?.defaultSettings?.audioSource || 
        "default_output"

    property string editVideoSource: 
        pluginApi?.pluginSettings?.videoSource || 
        pluginApi?.manifest?.metadata?.defaultSettings?.videoSource || 
        "portal"

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("ScreenRecorder", "Cannot save: pluginApi is null")
            return
        }

        pluginApi.pluginSettings.directory = root.editDirectory
        pluginApi.pluginSettings.filenamePattern = root.editFilenamePattern
        pluginApi.pluginSettings.frameRate = root.editFrameRate
        pluginApi.pluginSettings.audioCodec = root.editAudioCodec
        pluginApi.pluginSettings.videoCodec = root.editVideoCodec
        pluginApi.pluginSettings.quality = root.editQuality
        pluginApi.pluginSettings.colorRange = root.editColorRange
        pluginApi.pluginSettings.showCursor = root.editShowCursor
        pluginApi.pluginSettings.copyToClipboard = root.editCopyToClipboard
        pluginApi.pluginSettings.audioSource = root.editAudioSource
        pluginApi.pluginSettings.videoSource = root.editVideoSource

        pluginApi.saveSettings()

        Logger.i("ScreenRecorder", "Settings saved successfully")
    }
    NTextInputButton {
        label: I18n.tr("panels.screen-recorder.general-output-folder-label")
        description: I18n.tr("panels.screen-recorder.general-output-folder-description")
        placeholderText: Quickshell.env("HOME") + "/Videos"
        text: root.editDirectory
        buttonIcon: "folder-open"
        buttonTooltip: I18n.tr("panels.screen-recorder.general-output-folder-label")
        onInputEditingFinished: root.editDirectory = text
        onButtonClicked: folderPicker.openFilePicker()
    }

    // Filename Pattern
    NTextInput {
        label: pluginApi?.tr("settings.filename_pattern.label") || "Filename pattern"
        description: pluginApi?.tr("settings.filename_pattern.description") || "Pattern for generated filenames. Supported: yyyy, yy, MM, M, dd, d, HH, H, mm, m, ss, s (e.g., mycool-recording_yyyyMMdd_HHmmss)"
        placeholderText: "recording_yyyyMMdd_HHmmss"
        text: root.editFilenamePattern
        onTextChanged: root.editFilenamePattern = text
        Layout.fillWidth: true
    }

    NDivider {
        Layout.fillWidth: true
    }

    // Show Cursor
    NToggle {
        label: I18n.tr("panels.screen-recorder.general-show-cursor-label")
        description: I18n.tr("panels.screen-recorder.general-show-cursor-description")
        checked: root.editShowCursor
        onToggled: root.editShowCursor = checked
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showCursor ?? true
    }

    // Copy to Clipboard
    NToggle {
        label: I18n.tr("panels.screen-recorder.general-copy-to-clipboard-label")
        description: I18n.tr("panels.screen-recorder.general-copy-to-clipboard-description")
        checked: root.editCopyToClipboard
        onToggled: root.editCopyToClipboard = checked
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.copyToClipboard ?? false
    }

    NDivider {
        Layout.fillWidth: true
    }

    // Video Settings
    ColumnLayout {
        spacing: Style.marginL
        Layout.fillWidth: true

        // Source
        NComboBox {
            label: I18n.tr("panels.screen-recorder.video-video-source-label")
            description: I18n.tr("panels.screen-recorder.video-video-source-description")
            model: [
                {
                    "key": "portal",
                    "name": I18n.tr("options.screen-recording.sources-portal")
                },
                {
                    "key": "screen",
                    "name": I18n.tr("options.screen-recording.sources-screen")
                }
            ]
            currentKey: root.editVideoSource
            onSelected: key => root.editVideoSource = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.videoSource || "portal"
        }

        // Frame Rate
        NComboBox {
            label: I18n.tr("panels.audio.media-frame-rate-label")
            description: I18n.tr("panels.screen-recorder.video-frame-rate-description")
            model: [
                {
                    "key": "30",
                    "name": I18n.tr("options.frame-rates-fps", {"fps": "30"})
                },
                {
                    "key": "60",
                    "name": I18n.tr("options.frame-rates-fps", {"fps": "60"})
                },
                {
                    "key": "100",
                    "name": I18n.tr("options.frame-rates-fps", {"fps": "100"})
                },
                {
                    "key": "120",
                    "name": I18n.tr("options.frame-rates-fps", {"fps": "120"})
                },
                {
                    "key": "144",
                    "name": I18n.tr("options.frame-rates-fps", {"fps": "144"})
                },
                {
                    "key": "165",
                    "name": I18n.tr("options.frame-rates-fps", {"fps": "165"})
                },
                {
                    "key": "240",
                    "name": I18n.tr("options.frame-rates-fps", {"fps": "240"})
                }
            ]
            currentKey: root.editFrameRate
            onSelected: key => root.editFrameRate = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.frameRate || "60"
        }

        // Video Quality
        NComboBox {
            label: I18n.tr("panels.screen-recorder.video-video-quality-label")
            description: I18n.tr("panels.screen-recorder.video-video-quality-description")
            model: [
                {
                    "key": "medium",
                    "name": I18n.tr("options.screen-recording.quality-medium")
                },
                {
                    "key": "high",
                    "name": I18n.tr("options.screen-recording.quality-high")
                },
                {
                    "key": "very_high",
                    "name": I18n.tr("options.screen-recording.quality-very-high")
                },
                {
                    "key": "ultra",
                    "name": I18n.tr("options.screen-recording.quality-ultra")
                }
            ]
            currentKey: root.editQuality
            onSelected: key => root.editQuality = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.quality || "very_high"
        }

        // Video Codec
        NComboBox {
            label: I18n.tr("panels.screen-recorder.video-video-codec-label")
            description: I18n.tr("panels.screen-recorder.video-video-codec-description")
            model: {
                let options = [
                    {"key": "h264", "name": "H264"},
                    {"key": "hevc", "name": "HEVC"},
                    {"key": "av1", "name": "AV1"},
                    {"key": "vp8", "name": "VP8"},
                    {"key": "vp9", "name": "VP9"}
                ]
                // Only add HDR options if source is 'screen'
                if (root.editVideoSource === "screen") {
                    options.push({"key": "hevc_hdr", "name": "HEVC HDR"})
                    options.push({"key": "av1_hdr", "name": "AV1 HDR"})
                }
                return options
            }
            currentKey: root.editVideoCodec
            onSelected: key => {
                root.editVideoCodec = key
                // If an HDR codec is selected, change the colorRange to full
                if (key.includes("_hdr")) {
                    root.editColorRange = "full"
                }
            }
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.videoCodec || "h264"

            Connections {
                target: root
                function onEditVideoSourceChanged() {
                    if (root.editVideoSource !== "screen" && (root.editVideoCodec === "av1_hdr" || root.editVideoCodec === "hevc_hdr")) {
                        root.editVideoCodec = "h264"
                    }
                }
            }
        }

        // Color Range
        NComboBox {
            label: I18n.tr("panels.screen-recorder.video-color-range-label")
            description: I18n.tr("panels.screen-recorder.video-color-range-description")
            model: [
                {
                    "key": "limited",
                    "name": I18n.tr("options.screen-recording.color-range-limited")
                },
                {
                    "key": "full",
                    "name": I18n.tr("options.screen-recording.color-range-full")
                }
            ]
            currentKey: root.editColorRange
            onSelected: key => root.editColorRange = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.colorRange || "limited"
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    // Audio Settings
    ColumnLayout {
        spacing: Style.marginL
        Layout.fillWidth: true

        // Audio Source
        NComboBox {
            label: I18n.tr("panels.screen-recorder.audio-audio-source-label")
            description: I18n.tr("panels.screen-recorder.audio-audio-source-description")
            model: [
                {
                    "key": "none",
                    "name": I18n.tr("options.screen-recording.audio-sources-none")
                },
                {
                    "key": "default_output",
                    "name": I18n.tr("options.screen-recording.audio-sources-system-output")
                },
                {
                    "key": "default_input",
                    "name": I18n.tr("options.screen-recording.audio-sources-microphone-input")
                },
                {
                    "key": "both",
                    "name": I18n.tr("options.screen-recording.audio-sources-both")
                }
            ]
            currentKey: root.editAudioSource
            onSelected: key => root.editAudioSource = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.audioSource || "default_output"
        }

        // Audio Codec
        NComboBox {
            label: I18n.tr("panels.screen-recorder.audio-audio-codec-label")
            description: I18n.tr("panels.screen-recorder.audio-audio-codec-description")
            model: [
                {
                    "key": "opus",
                    "name": "Opus"
                },
                {
                    "key": "aac",
                    "name": "AAC"
                }
            ]
            currentKey: root.editAudioCodec
            onSelected: key => root.editAudioCodec = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.audioCodec || "opus"
        }
    }

    Item {
        Layout.fillHeight: true
    }

    NFilePicker {
        id: folderPicker
        selectionMode: "folders"
        title: I18n.tr("panels.screen-recorder.general-select-output-folder")
        initialPath: root.editDirectory || Quickshell.env("HOME") + "/Videos"
        onAccepted: paths => {
            if (paths.length > 0) {
                root.editDirectory = paths[0]
            }
        }
    }
}

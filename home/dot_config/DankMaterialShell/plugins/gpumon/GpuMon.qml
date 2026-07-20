import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property int util: 0
    property int temp: 0
    property real memUsed: 0
    property real memTotal: 0
    property real power: 0
    property int clock: 0
    readonly property real memPct: memTotal > 0 ? memUsed / memTotal * 100 : 0

    // nvidia-smi is the only source with util/vram/power (dgop has temp only)
    Process {
        id: smi
        command: ["nvidia-smi",
            "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,clocks.gr",
            "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",").map(s => parseFloat(s.trim()));
                if (f.length >= 6 && !isNaN(f[0])) {
                    root.util = Math.round(f[0]);
                    root.temp = Math.round(f[1]);
                    root.memUsed = f[2];
                    root.memTotal = f[3];
                    root.power = f[4];
                    root.clock = Math.round(f[5]);
                }
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: smi.running = true
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: row.implicitWidth
            implicitHeight: row.implicitHeight
            StyledTextMetrics {
                id: base
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                text: "100%"
            }
            StyledTextMetrics {
                id: tbase
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                text: "100°"
            }
            Row {
                id: row
                anchors.centerIn: parent
                spacing: Theme.spacingS
                DankIcon {
                    name: "developer_board"
                    size: Theme.barIconSize(root.barThickness, undefined, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    text: root.util + "%"
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    width: base.width
                }
                StyledText {
                    text: root.temp + "°"
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: root.temp >= 80 ? Theme.error : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    width: tbase.width
                }
            }
        }
    }

    popoutWidth: 340
    popoutContent: Component {
        Column {
            spacing: Theme.spacingM

            StyledText {
                text: "GPU"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            // labelled progress bar helper via repeater of rows
            Repeater {
                model: [
                    {label: "Utilization", val: root.util, max: 100, txt: root.util + " %"},
                    {label: "VRAM", val: root.memPct, max: 100, txt: Math.round(root.memUsed) + " / " + Math.round(root.memTotal) + " MiB"}
                ]
                Column {
                    required property var modelData
                    width: parent.width
                    spacing: 2
                    Row {
                        width: parent.width
                        StyledText {
                            text: modelData.label
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            width: parent.width / 2
                        }
                        StyledText {
                            text: modelData.txt
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                            horizontalAlignment: Text.AlignRight
                            width: parent.width / 2
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 10
                        radius: 5
                        color: Theme.surfaceVariant
                        Rectangle {
                            width: parent.width * Math.max(0.02, Math.min(1, modelData.val / modelData.max))
                            height: parent.height
                            radius: 5
                            color: Theme.primary
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.3 }

            Repeater {
                model: [
                    {label: "Temperature", txt: root.temp + " °C"},
                    {label: "Power draw", txt: root.power.toFixed(0) + " W"},
                    {label: "Core clock", txt: root.clock + " MHz"}
                ]
                Row {
                    required property var modelData
                    width: parent.width
                    StyledText {
                        text: modelData.label
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        width: parent.width / 2
                    }
                    StyledText {
                        text: modelData.txt
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        horizontalAlignment: Text.AlignRight
                        width: parent.width / 2
                    }
                }
            }
        }
    }
}

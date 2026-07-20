import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    function fmtGiB(kb) {
        return (kb / 1048576).toFixed(0);
    }
    // dgop diskMounts: {mount, percent, used, total} (used/total in KB)
    function rootMount() {
        const m = DgopService.diskMounts || [];
        return m.find(x => x.mount === "/") || m[0] || null;
    }
    // real mounts only: skip pseudo/huge network fs (gcsfuse reports petabytes)
    function realMounts() {
        return (DgopService.diskMounts || []).filter(x => x.total > 0 && x.total < 1e11);
    }

    Component.onCompleted: DgopService.addRef(["disk"])
    Component.onDestruction: DgopService.removeRef(["disk"])

    horizontalBarPill: Component {
        Item {
            implicitWidth: row.implicitWidth
            implicitHeight: row.implicitHeight
            Row {
                id: row
                anchors.centerIn: parent
                spacing: Theme.spacingS
                DankIcon {
                    name: "hard_drive"
                    size: Theme.barIconSize(root.barThickness, undefined, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    text: (root.rootMount()?.percent ?? 0).toFixed(0) + "%"
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: (root.rootMount()?.percent ?? 0) >= 90 ? Theme.error : Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    popoutWidth: 380
    popoutContent: Component {
        Column {
            spacing: Theme.spacingM

            StyledText {
                text: "Storage"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Repeater {
                model: root.realMounts()
                Column {
                    required property var modelData
                    width: parent.width
                    spacing: 2
                    Row {
                        width: parent.width
                        StyledText {
                            text: modelData.mount
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            width: parent.width / 2
                            elide: Text.ElideMiddle
                        }
                        StyledText {
                            text: root.fmtGiB(modelData.used) + " / " + root.fmtGiB(modelData.total) + " GiB"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                            horizontalAlignment: Text.AlignRight
                            width: parent.width / 2
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Theme.surfaceVariantAlpha
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, (modelData.percent || 0) / 100))
                            height: parent.height
                            radius: 3
                            color: (modelData.percent || 0) >= 90 ? Theme.error : Theme.primary
                        }
                    }
                }
            }

            StyledText {
                visible: root.realMounts().length === 0
                text: "no mounts reported yet"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.3 }

            DankButton {
                text: "Analyze with gdu"
                onClicked: Quickshell.execDetached(["kitty", "-e", "gdu", "/"])
            }
        }
    }
}

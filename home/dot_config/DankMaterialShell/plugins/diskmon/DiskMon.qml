import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // dgop diskmounts objects: {device, mount, fstype, size, used, avail, percent}
    // all human-readable strings, e.g. percent "76%", size "1.7T"
    function pctNum(m) {
        return m && m.percent ? parseInt(String(m.percent).replace("%", "")) || 0 : 0;
    }
    function rootMount() {
        const m = DgopService.diskMounts || [];
        return m.find(x => x.mount === "/") || m[0] || null;
    }
    // real local filesystems only (drop fuse/gcsfuse, tmpfs, efivars, overlay)
    function realMounts() {
        return (DgopService.diskMounts || []).filter(x => {
            const fs = String(x.fstype || "");
            return !/^(fuse|tmpfs|devtmpfs|overlay|squashfs|efivarfs|ramfs)/.test(fs);
        });
    }

    Component.onCompleted: DgopService.addRef(["diskmounts"])
    Component.onDestruction: DgopService.removeRef(["diskmounts"])

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
                    text: root.pctNum(root.rootMount()) + "%"
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: root.pctNum(root.rootMount()) >= 90 ? Theme.error : Theme.widgetTextColor
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
                            text: (modelData.used || "?") + " / " + (modelData.size || "?")
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
                            width: parent.width * Math.max(0, Math.min(1, root.pctNum(modelData) / 100))
                            height: parent.height
                            radius: 3
                            color: root.pctNum(modelData) >= 90 ? Theme.error : Theme.primary
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

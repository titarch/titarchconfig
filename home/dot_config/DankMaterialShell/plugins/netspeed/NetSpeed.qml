import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    popoutWidth: 380

    function fmt(bytesPerSec) {
        if (bytesPerSec < 1024)
            return bytesPerSec.toFixed(0) + " B/s";
        if (bytesPerSec < 1048576)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        if (bytesPerSec < 1073741824)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
        return (bytesPerSec / 1073741824).toFixed(2) + " GB/s";
    }

    Component.onCompleted: DgopService.addRef(["network"])
    Component.onDestruction: DgopService.removeRef(["network"])

    horizontalBarPill: Component {
        Item {
            implicitWidth: contentRow.implicitWidth
            implicitHeight: contentRow.implicitHeight

            StyledTextMetrics {
                id: baseline
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                text: "888.8 MB/s"
            }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankIcon {
                    name: "network_check"
                    size: Theme.barIconSize(root.barThickness, undefined, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "↓"
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        color: Theme.info
                    }

                    StyledText {
                        text: root.fmt(DgopService.networkRxRate)
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        color: Theme.widgetTextColor
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideNone
                        wrapMode: Text.NoWrap
                        width: baseline.width
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "↑"
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        color: Theme.error
                    }

                    StyledText {
                        text: root.fmt(DgopService.networkTxRate)
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        color: Theme.widgetTextColor
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideNone
                        wrapMode: Text.NoWrap
                        width: baseline.width
                    }
                }
            }
        }
    }

    popoutContent: Component {
        Column {
            spacing: Theme.spacingM

            StyledText {
                text: "Network"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                StyledText {
                    visible: DMSNetworkService.ethernetConnected
                    text: "ethernet  " + DMSNetworkService.ethernetInterface + "  " + DMSNetworkService.ethernetIP
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    visible: DMSNetworkService.wifiConnected
                    text: "wifi  " + DMSNetworkService.currentWifiSSID + "  " + DMSNetworkService.wifiIP
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    visible: !DMSNetworkService.ethernetConnected && !DMSNetworkService.wifiConnected
                    text: "disconnected"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.error
                }

                Row {
                    spacing: Theme.spacingS

                    StyledText {
                        text: "↓ " + root.fmt(DgopService.networkRxRate)
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.info
                    }

                    StyledText {
                        text: "↑ " + root.fmt(DgopService.networkTxRate)
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.error
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outline
                opacity: 0.3
            }

            StyledText {
                text: "VPN"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Repeater {
                model: DMSNetworkService.profiles

                DankToggle {
                    required property var modelData
                    width: parent.width
                    text: modelData.name + (modelData.typeLabel ? "  (" + modelData.typeLabel + ")" : "")
                    checked: DMSNetworkService.activeUuids.indexOf(modelData.uuid) !== -1
                    onToggled: isChecked => {
                        if (isChecked)
                            DMSNetworkService.connectVpn(modelData.uuid);
                        else
                            DMSNetworkService.disconnectVpn(modelData.uuid);
                    }
                }
            }

            StyledText {
                visible: DMSNetworkService.profiles.length === 0
                text: "no VPN profiles (import via nmcli or settings)"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            DankButton {
                text: "All network settings"
                onClicked: {
                    Quickshell.execDetached(["dms", "ipc", "call", "settings", "openWith", "network"]);
                }
            }
        }
    }
}

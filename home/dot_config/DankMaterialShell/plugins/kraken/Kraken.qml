import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property real coolant: 0
    property int pump: 0
    property int fan: 0
    property real cpuTemp: 0
    property real tccd1: 0
    property real tccd2: 0
    property real ambient: 0
    property real power: 0
    property bool haveData: false
    property bool havePower: false
    // energy_uj is monotonic (wraps at max); watts = dE/dt across two samples
    property var _lastE: null
    property real _lastT: 0

    readonly property real deltaT: coolant - ambient
    // AIO thermal resistance; only meaningful under load with coolant above board air
    readonly property bool haveCW: havePower && power > 15 && deltaT > 0
    readonly property real cW: haveCW ? deltaT / power : 0

    function coolantColor(t) {
        return t >= 52 ? Theme.error : t >= 45 ? Theme.warning : t >= 38 ? Theme.surfaceText : Theme.info;
    }
    function cpuColor(t) {
        return t >= 85 ? Theme.error : t >= 70 ? Theme.warning : Theme.surfaceText;
    }
    function pumpColor(rpm) {
        return rpm < 300 ? Theme.error : rpm < 600 ? Theme.warning : Theme.primary;
    }
    // bolt = performance, keyed on sustained power not temp: near-max power is good even
    // at ~91C. red only when hot AND power throttled (overheating). Tctl limit ~95-96
    function powerColor() {
        if (!havePower) return Theme.surfaceVariantText;
        if (power >= 190) return Theme.info;      // sustaining near-max (>=190 of ~200W) -> excellent
        if (cpuTemp >= 93) return Theme.error;    // hot but power not near-max -> throttling/overheating
        if (power >= 70) return Theme.success;    // solid load, temp in check -> good
        if (cpuTemp >= 85) return Theme.warning;  // warm under light load -> watch
        return Theme.surfaceVariantText;          // idle
    }

    Process {
        id: sensors
        command: [Quickshell.env("HOME") + "/.local/bin/kraken-sensors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim();
                if (!s)
                    return;
                let d;
                try {
                    d = JSON.parse(s);
                } catch (e) {
                    return;
                }
                if (d.coolant !== null) root.coolant = d.coolant;
                if (d.pump !== null) root.pump = d.pump;
                if (d.fan !== null) root.fan = d.fan;
                if (d.cpu_temp !== null) root.cpuTemp = d.cpu_temp;
                if (d.tccd1 !== null) root.tccd1 = d.tccd1;
                if (d.tccd2 !== null) root.tccd2 = d.tccd2;
                if (d.ambient !== null) root.ambient = d.ambient;
                root.haveData = true;
                const now = Date.now();
                if (d.energy_uj !== null) {
                    if (root._lastE !== null && now > root._lastT) {
                        let de = d.energy_uj - root._lastE;
                        if (de < 0 && d.energy_max_uj) de += d.energy_max_uj;
                        const dt = (now - root._lastT) / 1000;
                        if (dt > 0 && de >= 0) {
                            root.power = de / 1e6 / dt;
                            root.havePower = true;
                        }
                    }
                    root._lastE = d.energy_uj;
                    root._lastT = now;
                }
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sensors.running = true
    }

    horizontalBarPill: Component {
        Item {
            id: pill
            readonly property real fs: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            readonly property real isz: Theme.barIconSize(root.barThickness, undefined, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)
            implicitWidth: outer.implicitWidth
            implicitHeight: outer.implicitHeight

            // reserve widest 1-decimal temp and 3-digit watt (peak ~200W), so the pill
            // width never changes; the number keeps its natural width -> never elides
            StyledTextMetrics { id: tbase; font.pixelSize: pill.fs; text: "88.8°" }
            StyledTextMetrics { id: pbase; font.pixelSize: pill.fs; text: "200 W" }

            Row {
                id: outer
                anchors.centerIn: parent
                spacing: Theme.spacingM

                // icon hugs its number (group anchored right), slack falls between groups
                Item {
                    implicitWidth: pill.isz + Theme.spacingXS + tbase.width
                    implicitHeight: cg.implicitHeight
                    Row {
                        id: cg
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS
                        DankIcon {
                            name: "water_drop"
                            size: pill.isz
                            color: root.coolantColor(root.coolant)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: root.coolant.toFixed(1) + "°"
                            font.pixelSize: pill.fs
                            color: Theme.widgetTextColor
                            elide: Text.ElideNone
                            wrapMode: Text.NoWrap
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Item {
                    implicitWidth: pill.isz + Theme.spacingXS + pbase.width
                    implicitHeight: pg.implicitHeight
                    Row {
                        id: pg
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS
                        DankIcon {
                            name: "bolt"
                            size: pill.isz
                            color: root.powerColor()
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: root.havePower ? Math.round(root.power) + " W" : "-- W"
                            font.pixelSize: pill.fs
                            color: Theme.widgetTextColor
                            elide: Text.ElideNone
                            wrapMode: Text.NoWrap
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 360
    popoutContent: Component {
        Column {
            spacing: Theme.spacingM

            Row {
                spacing: Theme.spacingS
                DankIcon {
                    name: "water_drop"
                    size: Theme.fontSizeLarge
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    text: "Liquid cooling"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM
                Repeater {
                    model: [
                        {big: root.coolant.toFixed(1) + "°", sub: "coolant", col: root.coolantColor(root.coolant)},
                        {big: root.havePower ? Math.round(root.power) + " W" : "-- W", sub: "CPU package", col: root.powerColor()}
                    ]
                    Rectangle {
                        required property var modelData
                        width: (parent.width - Theme.spacingM) / 2
                        height: 88
                        radius: Theme.spacingM
                        color: Theme.surfaceContainerHigh
                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXXS
                            StyledText {
                                text: modelData.big
                                font.pixelSize: 30
                                font.weight: Font.DemiBold
                                color: modelData.col
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            StyledText {
                                text: modelData.sub
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.3 }

            Repeater {
                model: [
                    {label: "Pump", val: root.pump, max: 3000, txt: root.pump + " rpm", col: root.pumpColor(root.pump)},
                    {label: "Fan", val: root.fan, max: 2000, txt: root.fan + " rpm", col: Theme.primary}
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
                            color: modelData.col
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.3 }

            Repeater {
                model: [
                    {label: "CPU (Tctl)", txt: root.cpuTemp.toFixed(1) + " °C", col: root.cpuColor(root.cpuTemp)},
                    {label: "CCD1", txt: root.tccd1.toFixed(1) + " °C", col: Theme.surfaceVariantText},
                    {label: "CCD2", txt: root.tccd2.toFixed(1) + " °C", col: Theme.surfaceVariantText},
                    {label: "Board air (SYSTIN)", txt: root.ambient.toFixed(1) + " °C", col: Theme.surfaceVariantText}
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
                        color: modelData.col
                        horizontalAlignment: Text.AlignRight
                        width: parent.width / 2
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.3 }

            Repeater {
                model: [
                    {label: "Coolant vs board air", txt: (root.deltaT >= 0 ? "+" : "") + root.deltaT.toFixed(1) + " °C"},
                    {label: "Thermal resistance", txt: root.haveCW ? root.cW.toFixed(3) + " °C/W" : "--"}
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

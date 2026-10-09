// TIME // LOCAL: the Hackmachine clock.
//   on the desktop: a big VT323 clock, one pastel per digit, with the date and ISO week
//   in a panel:     a compact colourful line (day · date · HH:MM:SS); click for a calendar
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar

PlasmoidItem {
    id: root
    readonly property var hues: ["#f5a8c9", "#f7a59a", "#f9c49a", "#f2e29b", "#a6e6bf", "#94dcd6", "#a3cdf5", "#c4b2f5", "#e2b5f0"]
    readonly property string mono: Kirigami.Theme.fixedWidthFont.family
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                    || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property date now: new Date()

    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    Plasmoid.backgroundHints: inPanel ? PlasmaCore.Types.NoBackground
                                      : PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: Qt.formatDate(now, "dddd, d MMMM yyyy")
    toolTipSubText: "week " + isoWeek(now)

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

    function pad(n) { return String(n).padStart(2, "0") }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        const day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        return Math.ceil(((t - new Date(Date.UTC(t.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7)
    }
    function span(text, color) { return "<font color='" + color + "'>" + text + "</font>" }
    // HH:MM with the digits walking through the rainbow
    function rainbowTime() {
        const t = pad(now.getHours()) + pad(now.getMinutes())
        return span(t[0], hues[0]) + span(t[1], hues[1])
            + span(":", now.getSeconds() % 2 ? "#7d6d62" : "#bfae9f")
            + span(t[2], hues[4]) + span(t[3], hues[5])
    }

    // ── panel: fri 09.10 · 16:34 :26 ──
    compactRepresentation: MouseArea {
        id: compact
        readonly property real fs: Math.max(11, Math.min(height * 0.42, 18))
        Layout.minimumWidth: line.implicitWidth + 16
        Layout.preferredWidth: line.implicitWidth + 16
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Rectangle {  // hover tile + bar, like the task buttons
            anchors.fill: parent; anchors.margins: 2
            radius: 3
            color: "#372f2a"
            opacity: compact.containsMouse || root.expanded ? 1 : 0
        }
        Rectangle {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
            width: root.expanded ? 28 : 0; height: 3
            color: "#c4b2f5"
        }
        Text {
            id: line
            anchors.centerIn: parent
            textFormat: Text.StyledText
            font { family: root.mono; pixelSize: compact.fs; bold: true }
            text: root.span(Qt.formatDate(root.now, "ddd").toLowerCase(), "#e2b5f0") + " "
                + root.span(Qt.formatDate(root.now, "dd.MM"), "#f9c49a")
                + root.span("  ·  ", "#7d6d62")
                + root.rainbowTime()
                + "<small>" + root.span(" " + root.pad(root.now.getSeconds()), "#c4b2f5") + "</small>"
        }
    }

    // ── desktop card / panel popup ──
    fullRepresentation: ColumnLayout {
        id: col
        spacing: 0
        Layout.preferredWidth: root.inPanel ? Kirigami.Units.gridUnit * 22 : -1
        Layout.preferredHeight: root.inPanel ? Kirigami.Units.gridUnit * 26 : -1
        readonly property real big: root.inPanel ? Kirigami.Units.gridUnit * 4.5
                                                 : Math.min(width / 4.2, (height - 60) * 0.95)

        RowLayout {
            Layout.fillWidth: true
            Text { text: "TIME // LOCAL"; color: "#f9c49a"; font { family: root.mono; pixelSize: Math.max(10, col.big * 0.09); bold: true; letterSpacing: 1.4 } }
            Item { Layout.fillWidth: true }
            Text { text: Qt.formatDate(root.now, "dddd").toLowerCase(); color: "#7d6d62"; font { family: root.mono; pixelSize: Math.max(10, col.big * 0.09) } }
        }
        Item { Layout.fillHeight: true; Layout.minimumHeight: 6 }
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Repeater {
                model: (root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes())).split("")
                Text {
                    required property string modelData
                    required property int index
                    text: modelData
                    color: modelData === ":" ? (root.now.getSeconds() % 2 ? "#7d6d62" : "#bfae9f") : root.hues[index * 2 % 9]
                    font { family: "VT323"; pixelSize: col.big }
                }
            }
            Text {
                text: " " + root.pad(root.now.getSeconds())
                color: "#c4b2f5"
                font { family: "VT323"; pixelSize: col.big * 0.38 }
            }
        }
        Item { Layout.fillHeight: true; Layout.minimumHeight: 4 }
        Text {
            Layout.alignment: Qt.AlignHCenter
            textFormat: Text.StyledText
            text: root.span(Qt.formatDate(root.now, "dd.MM.yyyy"), "#bfae9f")
                + root.span("  ·  ", "#7d6d62") + root.span("week " + root.isoWeek(root.now), "#f9c49a")
                + root.span("  ·  ", "#7d6d62") + root.span("day " + Qt.formatDate(root.now, "d") + "/"
                    + new Date(root.now.getFullYear(), root.now.getMonth() + 1, 0).getDate(), "#bfae9f")
            font { family: root.mono; pixelSize: Math.max(11, col.big * 0.12) }
        }
        PlasmaCalendar.MonthView {
            visible: root.inPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.minimumHeight: visible ? Kirigami.Units.gridUnit * 14 : 0
            today: root.now
            showWeekNumbers: true
        }
    }
}

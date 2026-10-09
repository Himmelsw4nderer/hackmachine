// TIME // LOCAL: a big VT323 clock, one pastel per digit, with the date and ISO week.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    readonly property var hues: ["#f5a8c9", "#f7a59a", "#f9c49a", "#f2e29b", "#a6e6bf", "#94dcd6", "#a3cdf5", "#c4b2f5", "#e2b5f0"]
    readonly property string mono: Kirigami.Theme.fixedWidthFont.family
    property date now: new Date()

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

    function pad(n) { return String(n).padStart(2, "0") }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        const day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        return Math.ceil(((t - new Date(Date.UTC(t.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7)
    }

    fullRepresentation: ColumnLayout {
        id: col
        spacing: 0
        readonly property real big: Math.min(width / 4.2, (height - 60) * 0.95)

        RowLayout {
            Layout.fillWidth: true
            Text { text: "TIME // LOCAL"; color: "#f9c49a"; font { family: root.mono; pixelSize: Math.max(10, col.big * 0.09); bold: true; letterSpacing: 1.4 } }
            Item { Layout.fillWidth: true }
            Text { text: Qt.formatDate(root.now, "dddd").toLowerCase(); color: "#7d6d62"; font { family: root.mono; pixelSize: Math.max(10, col.big * 0.09) } }
        }
        Item { Layout.fillHeight: true }
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
                anchors.baseline: parent.children[0] ? parent.children[0].baseline : undefined
                text: " " + root.pad(root.now.getSeconds())
                color: "#c4b2f5"
                font { family: "VT323"; pixelSize: col.big * 0.38 }
            }
        }
        Item { Layout.fillHeight: true }
        Text {
            Layout.alignment: Qt.AlignHCenter
            textFormat: Text.StyledText
            text: "<font color='#bfae9f'>" + Qt.formatDate(root.now, "dd.MM.yyyy") + "</font>"
                + "<font color='#7d6d62'>  ·  </font><font color='#f9c49a'>week " + root.isoWeek(root.now) + "</font>"
                + "<font color='#7d6d62'>  ·  </font><font color='#bfae9f'>day " + Qt.formatDate(root.now, "d")
                + "/" + new Date(root.now.getFullYear(), root.now.getMonth() + 1, 0).getDate() + "</font>"
            font { family: root.mono; pixelSize: Math.max(11, col.big * 0.12) }
        }
    }
}

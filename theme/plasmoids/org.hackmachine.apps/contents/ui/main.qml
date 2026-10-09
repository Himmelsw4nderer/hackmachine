// APPS // PINNED: a desktop card of app tiles, styled like the Hackmachine taskbar.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property color bg300: "#372f2a"
    readonly property color line: "#4a3f38"
    readonly property color ink: "#f6ece4"
    readonly property color muted: "#bfae9f"
    readonly property color faint: "#7d6d62"
    readonly property color lavender: "#c4b2f5"
    readonly property color mint: "#a6e6bf"
    readonly property string mono: Kirigami.Theme.fixedWidthFont.family

    readonly property var apps: {
        try { return JSON.parse(Plasmoid.configuration.apps) } catch (e) { return [] }
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    P5Support.DataSource {
        id: shell
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }

    function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function launch(app) {
        shell.connectSource("gtk-launch " + quote(app.id) + " || kioclient exec " + quote(app.path))
    }

    fullRepresentation: ColumnLayout {
        spacing: 8
        Layout.minimumWidth: grid.implicitWidth
        Layout.minimumHeight: implicitHeight

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "APPS // PINNED"
                color: root.lavender
                font { family: root.mono; pixelSize: 10; bold: true; letterSpacing: 1.4 }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "[" + String(root.apps.length).padStart(2, "0") + "]"
                color: root.faint
                font { family: root.mono; pixelSize: 10 }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

        GridLayout {
            id: grid
            columns: 3
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: root.apps
                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index
                    implicitWidth: 96
                    implicitHeight: 88

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: mouse.pressed ? Qt.rgba(0.77, 0.70, 0.96, 0.22) : root.bg300
                        opacity: mouse.containsMouse || mouse.pressed ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                    Text {
                        x: 6; y: 4
                        text: "[" + String(tile.index + 1).padStart(2, "0") + "]"
                        color: mouse.containsMouse ? tile.modelData.hue : root.faint
                        font { family: root.mono; pixelSize: 9 }
                    }
                    Kirigami.Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 14
                        width: 40; height: 40
                        source: tile.modelData.icon
                        scale: mouse.containsMouse ? 1.08 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 60
                        text: tile.modelData.name
                        color: tile.modelData.hue
                        font { family: root.mono; pixelSize: 11; bold: mouse.containsMouse }
                    }
                    Rectangle {  // focus bar, like the taskbar
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: mouse.containsMouse ? 28 : 0
                        height: 3
                        color: tile.modelData.hue
                        Behavior on width { NumberAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(tile.modelData)
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

        Text {
            Layout.fillWidth: true
            text: "<font color='" + root.mint + "'>λ</font> ~/ > meta+space · more apps"
            textFormat: Text.StyledText
            color: footer.containsMouse ? root.ink : root.muted
            font { family: root.mono; pixelSize: 10 }
            MouseArea {
                id: footer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: Plasmoid.configuration.menuCommand !== ""
                onClicked: shell.connectSource(Plasmoid.configuration.menuCommand)
            }
        }
    }
}

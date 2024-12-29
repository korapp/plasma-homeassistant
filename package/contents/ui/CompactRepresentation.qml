import QtQuick

import "./mdi"

MouseArea {
    onClicked: root.expanded = !root.expanded

    MdiIcon {
        name: "home-assistant"
        anchors.fill: parent
        anchors.centerIn: parent
    }
}
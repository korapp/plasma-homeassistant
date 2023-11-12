import QtQuick 2.0

import "./mdi"

MouseArea {
    onClicked: root.expanded = !root.expanded

    MdiIcon {
        name: "home-assistant"
        anchors.fill: parent
        anchors.centerIn: parent
    }
}
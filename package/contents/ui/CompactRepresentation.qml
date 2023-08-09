import QtQuick 2.0

import "./mdi"

MouseArea {
    onClicked: plasmoid.expanded = !plasmoid.expanded

    MdiIcon {
        name: "home-assistant"
        anchors.fill: parent
        anchors.centerIn: parent
    }
}
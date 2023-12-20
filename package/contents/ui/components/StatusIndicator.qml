import QtQuick 2.0
import QtQuick.Controls 2.5

import org.kde.plasma.core 2.1 as PlasmaCore

PlasmaCore.IconItem {
    property var icon
    property int size
    property string message

    width: size
    source: icon
    visible: icon && message

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        ToolTip.visible: containsMouse
        ToolTip.text: message
    }
}
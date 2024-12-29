import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami

Kirigami.Icon {
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
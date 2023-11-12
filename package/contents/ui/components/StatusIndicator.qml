import QtQuick 2.0
import QtQuick.Controls 2.5

import org.kde.kirigami 2.4 as Kirigami

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
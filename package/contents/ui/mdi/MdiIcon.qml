import QtQuick

import org.kde.kirigami as Kirigami

import "."

Item {
    required property string name
    readonly property var size: Mdi.scaleIconForPlasma(name, Qt.size(width, height))
    Kirigami.Icon {
        color: Kirigami.Theme.textColor
        isMask: true
        source: name && Mdi.image(size, name)
        height: size.height
        width: size.width
        anchors.centerIn: parent
    }
}
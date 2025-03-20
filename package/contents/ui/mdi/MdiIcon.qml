import QtQuick 2.0
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore

import "."

PlasmaCore.ColorScope {
    property string name
    PlasmaCore.IconItem {
        readonly property var size: Mdi.scaleIconForPlasma(name, Qt.size(parent.width, parent.height))
        height: size.height
        width: size.width
        source: Mdi.get(name, size)
        anchors.centerIn: parent
        ColorOverlay {
            anchors.fill: parent
            source: parent
            color: PlasmaCore.ColorScope.textColor
        }
    }
}
import QtQuick 2.0
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore

import "."

PlasmaCore.ColorScope {
    property string name
    PlasmaCore.SvgItem {
        readonly property var size: Mdi.scaleIconForPlasma(name, Qt.size(parent.width, parent.height))
        height: size.height
        width: size.width
        svg: Mdi
        elementId: name
        anchors.centerIn: parent
        layer.enabled: true
        layer.effect: ColorOverlay {
            color: PlasmaCore.ColorScope.textColor
            cached: true
        }
    }
}
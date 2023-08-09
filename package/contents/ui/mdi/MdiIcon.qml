import QtQuick 2.0
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore

import "."

PlasmaCore.IconItem {
    property string name
    onNameChanged: source = name ? Mdi.get(name, Qt.size(width, height)) : null
    ColorOverlay {
        anchors.fill: parent
        source: parent
        color: PlasmaCore.Theme.textColor
    }
}
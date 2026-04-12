import QtQuick
import QtQuick.Effects

import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

import "."

Item {
    required property string name
    readonly property var size: Mdi.scaleIconForPlasma(name, Qt.size(width, height))
    
    KSvg.SvgItem {
        height: size.height
        width: size.width
        svg: Mdi
        elementId: name
        anchors.centerIn: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 1
            colorization: 1
            colorizationColor: Kirigami.Theme.textColor
        }
    }
}
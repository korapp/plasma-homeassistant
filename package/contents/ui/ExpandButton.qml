import QtQuick 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

import "./mdi"

MouseArea {  
    property var size: Math.min(width, height)
    MdiIcon {
        visible: !trayMode
        name: "home-assistant"
        anchors.fill: parent
    }

    PlasmaCore.SvgItem {
        visible: trayMode
        anchors.centerIn: parent
        width: size
        height: size

        rotation: plasmoid.expanded ? 180 : 0
        Behavior on rotation {
            RotationAnimation {
                duration: 100
            }
        }
        svg: PlasmaCore.Svg {
            imagePath: "widgets/arrows"
        }
        elementId: {
            switch(plasmoid.location) {
                case PlasmaCore.Types.TopEdge: return "down-arrow";
                case PlasmaCore.Types.LeftEdge: return "right-arrow";
                case PlasmaCore.Types.RightEdge: return "left-arrow";
                default: return "up-arrow";
            }
        }
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: plasmoid.title
        subText: plasmoid.expanded ? i18n("Hide entities") : i18n("Show entities")
    }
}
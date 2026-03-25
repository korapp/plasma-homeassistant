import QtQuick

import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "./mdi"

MouseArea {
    MdiIcon {
        visible: !trayMode
        name: "home-assistant"
        anchors.fill: parent
    }

    Kirigami.Icon {
        visible: trayMode
        anchors.fill: parent
        source: {
            switch(plasmoid.location) {
                case PlasmaCore.Types.TopEdge: return "arrow-down";
                case PlasmaCore.Types.LeftEdge: return "arrow-right";
                case PlasmaCore.Types.RightEdge: return "arrow-left";
                default: return "arrow-up";
            }
        }
        rotation: root.expanded ? 180 : 0
        Behavior on rotation {
            RotationAnimation {
                duration: 100
            }
        }
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: plasmoid.title
        subText: root.expanded ? i18n("Hide entities") : i18n("Show entities")
    }
}
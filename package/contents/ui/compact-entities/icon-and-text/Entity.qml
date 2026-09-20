import QtQuick

import org.kde.plasma.components as PlasmaComponents3

import "../../"

Grid {
    id: entityLayout
    columns: 2
    spacing: 0
    verticalItemAlignment: alignment
    DynamicIcon {
        name: model.icon
        height: grid.itemSize
        width: grid.itemSize
        opacity: model.default_action && !model.active ? 0.6 : 1
    }
    PlasmaComponents3.Label {
        id: value
        text: model.value
    }
    states: [
        State {
            name: "vertical"
            when: grid.vertical
            PropertyChanges {
                entityLayout.columns: 1
                entityLayout.horizontalItemAlignment: alignment
                value.elide: Text.ElideRight
                value.width: Math.min(value.implicitWidth, grid.gridThickness)
            }
        }
    ]
}
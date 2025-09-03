import QtQuick 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.components 3.0 as PlasmaComponents3

import "../../"

GridLayout {
    id: entityLayout
    columns: 2
    DynamicIcon {
        name: model.icon
        Layout.preferredHeight: grid.itemSize
        Layout.preferredWidth: grid.itemSize
        Layout.alignment: alignment
        opacity: model.default_action.service && !model.active ? 0.6 : 1
    }
    PlasmaComponents3.Label {
        id: value
        text: model.value
        Layout.alignment: alignment
        elide: Text.ElideRight
    }
    states: [
        State {
            name: "vertical"
            when: grid.vertical
            changes: [
                PropertyChanges {
                    target: entityLayout
                    columns: 1
                    width: grid.gridThickness
                },
                PropertyChanges {
                    target: value
                    Layout.maximumWidth: entityLayout.width
                }
            ]
        }
    ]
}
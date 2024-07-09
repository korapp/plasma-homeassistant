import QtQuick 2.15
import QtQuick.Controls 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.4 as Kirigami

PlasmaComponents3.Button {
    id: control
    down: model.active
    flat: plasmoid.configuration.flat
    enabled: !!actions.length
    clip: true
    readonly property var actions: getActiveActions()

    PlasmaComponents3.ToolTip {
        visible: control.hovered && text
        text: actions.map(c => c.item.tip).join("\n")
    }

    function format(underscoredText) {
        return underscoredText && underscoredText.replace(/_/g, ' ')
    }

    function getActiveActions() {
        const actions = []
        for (let a in actionLoaders) {
            if (actionLoaders[a].item) actions.push(actionLoaders[a])
        }
        return actions
    }

    readonly property list<Loader> actionLoaders: [
        Loader {
            active: !!default_action.service
            sourceComponent: Component {
                Connections {
                    readonly property string tip: `Click to ${format(default_action.service)}`
                    target: control
                    function onClicked() {
                        ha.callService(default_action)
                    }
                }
            }
        },
        Loader {
            active: model.active && !!scroll_action.service
            anchors.fill: parent
            parent: control
            sourceComponent: Component {
                Item {
                    readonly property string tip: `Scroll to adjust ${format(scroll_action.data_field)}`
                    readonly property var scrollAttributeField: fields[scroll_action.domain + scroll_action.service + scroll_action.data_field]
                    readonly property var max: scrollAttributeField && scrollAttributeField.number.max || 1
                    readonly property var min: scrollAttributeField && scrollAttributeField.number.min || 0
                    property real position: (attributes[scroll_action.data_field] - min) / (max - min)
                    
                    WheelHandler {               
                        acceptedDevices: PointerDevice.TouchPad | PointerDevice.Mouse
                        orientation: Qt.Vertical
                        onWheel: e => {
                            const p = position + e.angleDelta.y / 3600
                            position = p > 1 ? 1 : p < 0 ? 0 : p
                        }
                        onActiveChanged: !active && ha.callService(scroll_action, { [scroll_action.data_field]: position * (max - min) + min })
                    }
                    Rectangle {
                        radius: 3
                        x: 1
                        y: 1
                        height: parent.height - 2 * y
                        width: position * (parent.width - 2 * x)
                        color: PlasmaCore.Theme.highlightColor
                        opacity: 0.6
                    }
                }
            }
        }
    ]
}
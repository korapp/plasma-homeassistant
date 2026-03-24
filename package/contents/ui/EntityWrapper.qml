import QtQuick 2.15
import QtQuick.Controls 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

MouseArea {
    id: control
    clip: true
    enabled: !!actions.length
    hoverEnabled: true
    property bool flat: true
    property bool showScrollPositionBackground: true
    property bool showBackground: false
    property alias tooltipTitle: tooltip.mainText
    readonly property var actions: getActiveActions()
    property alias content: socket.contentItem
    property alias background: socket.background
    
    PlasmaCore.ColorScope.inherit: flat
    PlasmaCore.ColorScope.colorGroup: flat && parent ? parent.PlasmaCore.ColorScope.colorGroup : PlasmaCore.Theme.ButtonColorGroup

    Control {
        id: socket
        padding: PlasmaCore.Units.smallSpacing
        anchors.fill: control
        Binding on background {
            when: showBackground
            value: Item {
                height: control.height
                width: control.width

                PlasmaCore.FrameSvgItem {
                    anchors.fill: parent
                    imagePath: "widgets/button"
                    prefix: ["toolbutton-normal", "normal"]
                    visible: !flat
                }
                
                PlasmaCore.FrameSvgItem {
                    id: surfacePressed
                    anchors.fill: parent
                    imagePath: "widgets/button"
                    prefix: ["toolbutton-pressed", "pressed"]
                    opacity: model.active ? 0.5 : 0
                    Behavior on opacity {
                        enabled: PlasmaCore.Units.shortDuration > 0
                        NumberAnimation { duration: PlasmaCore.Units.shortDuration; easing.type: Easing.OutQuad }
                    }
                }

                PlasmaCore.FrameSvgItem {
                    anchors.fill: parent
                    imagePath: "widgets/button"
                    prefix: ["toolbutton-hover", "normal"]
                    visible: control.hoverEnabled && control.containsMouse
                }
            }
        }
    }

    PlasmaCore.ToolTipArea {
        id: tooltip
        anchors.fill: parent
        subText: actions.map(c => c.item.tip).join("\n")
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
            parent: socket.background || socket
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
                        visible: control.showScrollPositionBackground
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
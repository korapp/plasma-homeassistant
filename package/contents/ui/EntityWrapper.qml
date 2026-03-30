import QtQuick
import QtQuick.Controls

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

MouseArea {
    id: control
    clip: true
    enabled: !!actions.length
    hoverEnabled: true
    property bool flat: true
    property bool showBackground: false
    property alias tooltipTitle: tooltip.mainText
    readonly property var actions: getActiveActions()
    property alias content: socket.contentItem
    property alias background: socket.background
    
    Kirigami.Theme.inherit: flat
    Kirigami.Theme.colorGroup: flat && parent ? parent.Kirigami.Theme.colorGroup : Kirigami.Theme.ButtonColorGroup

    Control {
        id: socket
        padding: Kirigami.Units.smallSpacing
        anchors.fill: control
        Binding on background {
            when: showBackground
            value: Item {
                height: control.height
                width: control.width

                KSvg.FrameSvgItem {
                    anchors.fill: parent
                    imagePath: "widgets/button"
                    prefix: ["toolbutton-normal", "normal"]
                    visible: !flat
                }
                
                KSvg.FrameSvgItem {
                    id: surfacePressed
                    anchors.fill: parent
                    imagePath: "widgets/button"
                    prefix: ["toolbutton-pressed", "pressed"]
                    opacity: model.active ? 0.5 : 0
                    Behavior on opacity {
                        enabled: Kirigami.Units.shortDuration > 0
                        NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
                    }
                }

                KSvg.FrameSvgItem {
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
            active: !!default_action
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
            active: model.active && !!scroll_action
            anchors.fill: parent
            parent: socket.background || socket
            sourceComponent: Component {
                Item {
                    readonly property string tip: `Scroll to adjust ${format(scroll_action.data_field)}`
                    readonly property var scrollAttributeField: store.fields[scroll_action.domain + scroll_action.service + scroll_action.data_field]
                    readonly property var max: scrollAttributeField?.number.max || 1
                    readonly property var min: scrollAttributeField?.number.min || 0
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
                        visible: control.showBackground
                        radius: 3
                        x: 1
                        y: 1
                        height: parent.height - 2 * y
                        width: position * (parent.width - 2 * x)
                        color: Kirigami.Theme.highlightColor
                        opacity: 0.6
                    }
                }
            }
        }
    ]
}
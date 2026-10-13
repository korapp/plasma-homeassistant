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
    readonly property var actions: actionLoaders.filter(l => l.item)
    property alias content: socket.contentItem
    property alias background: socket.background
    property bool pending

    Kirigami.Theme.inherit: flat

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

    function callService(...args) {
        pending = true
        const reset = () => pending = false
        return ha.callService(...args).then(reset, reset)
    }

    readonly property list<Loader> actionLoaders: [
        Loader {
            active: !!default_action
            sourceComponent: Component {
                Connections {
                    readonly property string tip: `Click to ${format(default_action.service)}`
                    target: control
                    function onClicked() {
                        callService(default_action)
                    }
                }
            }
        },
        Loader {
            active: !!dclick_action
            sourceComponent: Component {
                Connections {
                    readonly property string tip: `Double click to ${format(dclick_action.service)}`
                    target: control
                    function onDoubleClicked() {
                        callService(dclick_action)
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
                    property var mapper: { mapper = store.getFieldScrollMapper(scroll_action, attributes) }
                    readonly property real attributeBasedPosition: mapper.normalize(attributes[mapper.attribute])
                    property real position

                    Binding on position {
                        when: !pending
                        value: attributeBasedPosition
                    }
                    WheelHandler {
                        acceptedDevices: PointerDevice.TouchPad | PointerDevice.Mouse
                        orientation: Qt.Vertical
                        onWheel: e => {
                            const p = position + e.angleDelta.y / 3600
                            position = p > 1 ? 1 : p < 0 ? 0 : p
                        }
                        onActiveChanged: !active && callService(scroll_action, { [scroll_action.data_field]: mapper.denormalize(position) })
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
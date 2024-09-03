import QtQuick
import QtQuick.Controls

Item {
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property alias value: slider.value
    property alias textFromValue: spinbox.textFromValue
    property int spinBoxFactor: (v => v < 1 ? 1 / v : 1)(from || stepSize)
    Slider {
        id: slider
        anchors {
            left: parent.left
            right: spinbox.left
            verticalCenter: parent.verticalCenter
        }
        snapMode: Slider.SnapAlways
    }

    SpinBox {
        id: spinbox
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        from: parent.from * spinBoxFactor
        to: parent.to * spinBoxFactor
        stepSize: parent.stepSize * spinBoxFactor
        value: parent.value * spinBoxFactor
        onValueModified: parent.value = value / spinBoxFactor
    }
}
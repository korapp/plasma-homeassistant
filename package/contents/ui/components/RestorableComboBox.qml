import QtQuick
import QtQuick.Controls

ComboBox {
    property var initialValue
    property int fallbackIndex: -1
    onModelChanged: selectByValue(initialValue)
    Component.onCompleted: selectByValue(initialValue)
    function selectByValue(value) {
        const index = indexOfValue(value)
        currentIndex = ~index ? index : fallbackIndex
    }
}
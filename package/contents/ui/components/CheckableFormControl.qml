import QtQuick
import QtQuick.Controls

Row {
    property alias checked: checkBox.checked
    default property alias contentData: content.data

    CheckBox {
        id: checkBox
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        id: content
        enabled: checkBox.checked
    }
}
import QtQuick
import QtQuick.Layouts

import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

import org.kde.kirigami as Kirigami

GridLayout {
    id: grid
    columns: 2
    rows: model.value ? 2 : 1
    clip: true
    columnSpacing: Kirigami.Units.smallSpacing
    rowSpacing: 0

    DynamicIcon {
        name: model.icon
        Layout.rowSpan: model.value ? 2 : 1
        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
    }

    PlasmaExtras.Heading {
        id: stateValue
        level: 4
        text: model.value
        elide: Text.ElideRight
        visible: !!text
        wrapMode: Text.NoWrap
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true
    }

    PlasmaComponents3.Label {
        id: label
        text: name
        elide: Text.ElideRight
        Layout.alignment: model.value ? Qt.AlignTop : 0
        Layout.fillWidth: true
    }
}
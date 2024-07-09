import QtQuick 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents3

import org.kde.kirigami 2.4 as Kirigami

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
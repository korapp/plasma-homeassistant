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
    anchors.margins: Kirigami.Units.smallSpacing

    DynamicIcon {
        name: model.icon
        Layout.rowSpan: model.value ? 2 : 1
        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
    }

    PlasmaExtras.Heading {
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
        text: name
        elide: Text.ElideRight
        Layout.alignment: model.value ? Qt.AlignTop : 0
        Layout.fillWidth: true
    }
}
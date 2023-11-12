import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents3

import org.kde.kirigami 2.4 as Kirigami

import 'mdi'

PlasmaComponents3.Button {
    enabled: !!model.default_action?.service
    hoverEnabled: enabled
    down: model.active
    flat: plasmoid.configuration.flat
    onClicked: ha.callService(model.default_action)

    contentItem: GridLayout {
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

    PlasmaComponents3.ToolTip {
        text: parent.enabled ? format(model.default_action.service) + name : ''
        visible: hovered && text
    }

    function format(underscoredText) {
        return underscoredText
            .split('_')
            .reduce((o, w) => o += w[0].toUpperCase() + w.slice(1) + ' ','')
    }
}
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

import org.kde.kirigami as Kirigami

import "components"

PlasmaExtras.Representation {

    readonly property var preferredWidgetWidth: plasmoid.configuration.widgetWidth
    readonly property var preferredWidgetHeight: plasmoid.configuration.widgetHeight

    Layout.preferredWidth: preferredWidgetWidth < 0 ? Kirigami.Units.gridUnit * 24 : preferredWidgetWidth
    Layout.preferredHeight: preferredWidgetHeight < 0 ? Kirigami.Units.gridUnit * 24 : preferredWidgetHeight

    Loader {
        id: gridLoader
        sourceComponent: gridComponent
        active: root.initialized
        anchors.fill: parent
    }

    Component {
        id: gridComponent
        ScrollView {
            GridView {
                interactive: false
                clip: true
                cellWidth: plasmoid.configuration.cellWidth
                cellHeight: plasmoid.configuration.cellHeight
                model: itemModel
                delegate: Entity {
                    readonly property var gridHorizontalSpacing: plasmoid.configuration.gridHorizontalSpacing
                    readonly property var gridVerticalSpacing: plasmoid.configuration.gridVerticalSpacing
                    width: plasmoid.configuration.cellWidth - (gridHorizontalSpacing < 0 ? Kirigami.Units.smallSpacing : gridHorizontalSpacing)
                    height: plasmoid.configuration.cellHeight - (gridVerticalSpacing < 0 ? Kirigami.Units.smallSpacing : gridVerticalSpacing)
                    contentItem: EntityDelegateTile {}
                }
            }
        }
    }

    StatusIndicator {
        icon: "data-error"
        size: Kirigami.Units.iconSizes.small
        message: ha?.errorString || ''
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
    }

    Loader {
        width: parent.width
        anchors.centerIn: parent
        active: ClientFactory.error
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            text: i18n("Failed to create WebSocket client")
            explanation: ClientFactory.errorString().split(/\:\d+\s/)[1]
            iconName: "error"
            helpfulAction: Action {
                icon.name: "link"
                text: i18n("Show requirements")
                onTriggered: Qt.openUrlExternally(`${plasmoid.metaData.website}/tree/v${plasmoid.metaData.version}#requirements`)
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        active: plasmoid.configurationRequired
            && (plasmoid.formFactor === PlasmaCore.Types.Vertical
            || plasmoid.formFactor === PlasmaCore.Types.Horizontal)
        sourceComponent: PlasmaComponents3.Button {
            icon.name: "configure"
            text: i18nd("plasmashellprivateplugin", "Configure…")
            onClicked: plasmoid.internalAction("configure").trigger()
        }
    }
}

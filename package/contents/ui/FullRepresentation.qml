import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

import org.kde.kirigami as Kirigami

import "components"

PlasmaExtras.Representation {
    readonly property var appletInterface: plasmoid.self

    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight: Kirigami.Units.gridUnit * 24

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
                readonly property int dynamicColumnNumber: Math.min(Math.max(width / minItemWidth, 1), count)
                readonly property int dynamicCellWidth: Math.max(width / dynamicColumnNumber, minItemWidth)
                readonly property int minItemWidth: Kirigami.Units.iconSizes.enormous

                cellWidth: dynamicCellWidth
                cellHeight: minItemWidth / 2
                model: itemModel
                delegate: Entity {
                    id: entity
                    width: GridView.view.cellWidth - Kirigami.Units.smallSpacing
                    height: GridView.view.cellHeight - Kirigami.Units.smallSpacing
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
}

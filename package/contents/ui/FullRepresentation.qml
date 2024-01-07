import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.5

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents3

import "components"

PlasmaExtras.Representation {
    readonly property var appletInterface: plasmoid.self

    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 24
    Layout.preferredHeight: PlasmaCore.Units.gridUnit * 24

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
                readonly property int minItemWidth: PlasmaCore.Units.iconSizes.enormous

                cellWidth: dynamicCellWidth
                cellHeight: minItemWidth / 2
                model: itemModel
                delegate: Entity {
                    id: entity
                    width: GridView.view.cellWidth - PlasmaCore.Units.smallSpacing
                    height: GridView.view.cellHeight - PlasmaCore.Units.smallSpacing
                }
            }
        }
    }

    PlasmaComponents3.BusyIndicator {
        id: busyIndicator
        running: true
        visible: plasmoid.busy
        anchors.centerIn: parent
    }

    StatusIndicator {
        icon: "data-error"
        size: PlasmaCore.Units.iconSizes.small
        message: ha && ha.errorString
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

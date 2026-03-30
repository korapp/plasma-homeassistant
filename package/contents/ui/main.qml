import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

import "."

PlasmoidItem {
    id: root
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
    Plasmoid.backgroundHints: PlasmaCore.Types.StandardBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.configurationRequired: !ClientFactory.error && !(url && ha?.token && store.items.length)
    Plasmoid.busy: !ClientFactory.error && !plasmoid.configurationRequired && !store.initialized
    toolTipMainText: ""
    toolTipSubText: ""
    
    readonly property string url: plasmoid.configuration.url
    property Client ha

    onUrlChanged: initClient(url)

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Open %1", url)
            icon.name: "open-link-symbolic"
            onTriggered: Qt.openUrlExternally(url)
        }
    ]

    Store {
        id: store
        items: JSON.parse(plasmoid.configuration.items)
    }

    Notifications {
        id: notifications
    }

    function initClient(url) {
        ha = url ? ClientFactory.getClient(root, url) : null
        store.setClient(ha)
    }
}
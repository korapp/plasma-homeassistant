import QtQuick 2.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import "."
import "../code/model.mjs" as Model

Item {
    id: root
    Plasmoid.compactRepresentation: CompactRepresentation {}
    Plasmoid.fullRepresentation: FullRepresentation {}
    Plasmoid.backgroundHints: PlasmaCore.Types.StandardBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.configurationRequired: !url || !ha.token || !items.length
    Plasmoid.busy: !plasmoid.configurationRequired && !initialized
    Plasmoid.switchHeight: PlasmaCore.Units.iconSizes.enormous / 2
    Plasmoid.switchWidth: PlasmaCore.Units.iconSizes.enormous
    
    readonly property string url: plasmoid.configuration.url
    readonly property string cfgItems: plasmoid.configuration.items
    property ListModel itemModel: ListModel {}
    property var items: []
    property int subscription: 0
    property bool initialized: false
    
    onUrlChanged: url && (Secrets.entryKey = url)
    onCfgItemsChanged: items = JSON.parse(cfgItems)

    WsClient {
        id: ha
        baseUrl: url
        token: Secrets.token
        onReady: {
            subscribe()
            onItemsChanged.connect(subscribe)
        }
        onStateChanged: updateState(state)
    }

    function updateState(event) {
        if (!event || !event.variables) return
        const trigger = event.variables.trigger
        const itemIdx = items.findIndex(i => i.entity_id === trigger.entity_id)
        itemModel.set(itemIdx, new Model.Entity(items[itemIdx], trigger.to_state))
    }

    function initState(data) {
        itemModel.clear()
        items.forEach((i, idx) => {
            const entityData = data.find(e => e.entity_id === i.entity_id)
            itemModel.insert(idx, new Model.Entity(i, entityData))
        })
        initialized = true
    }

    function unsubscribe() {
        if (!subscription) return
        ha.unsubscribe(subscription)
        subscription = 0
    }

    function subscribe() {
        unsubscribe()
        if (!items.length) return
        const entities = items.map(i => i.entity_id)
        ha.getStates(entities).then(initState)
        subscription = ha.subscribeState(entities)
    }
}
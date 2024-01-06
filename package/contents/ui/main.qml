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
    Plasmoid.configurationRequired: !ClientFactory.error && (!url || !ha || !ha.token || !items.length)
    Plasmoid.busy: !ClientFactory.error && !plasmoid.configurationRequired && !initialized
    Plasmoid.switchHeight: PlasmaCore.Units.iconSizes.enormous / 2
    Plasmoid.switchWidth: PlasmaCore.Units.iconSizes.enormous
    
    readonly property string url: plasmoid.configuration.url
    readonly property string cfgItems: plasmoid.configuration.items
    property ListModel itemModel: ListModel {}
    property var items: []
    property bool initialized: false
    property QtObject ha
    property var cancelSubscription

    onCfgItemsChanged: items = JSON.parse(cfgItems)
    onUrlChanged: url && initClient(url)

    Notifications {
        id: notifications
    }

    function initClient(url) {
        if (ha) {
            unsubscribe()
            ha.ready.disconnect(subscribe)
            onItemsChanged.disconnect(subscribe)
        }
        ha = ClientFactory.getClient(this, url)
        ha.ready.connect(subscribe)
        onItemsChanged.connect(subscribe)
    }

    function updateState(state) {
        const itemIdx = items.findIndex(i => i.entity_id === state.entity_id)
        const configItem = items[itemIdx]
        const newItem = new Model.Entity(configItem, state)
        const oldValue = itemModel.get(itemIdx).value
        itemModel.set(itemIdx, newItem)
        if (configItem.notify && oldValue !== newItem.value) {
            notifications.createNotification(newItem.name + " " + newItem.value)
        }
    }

    function initState(data) {
        itemModel.clear()
        items.forEach((i, idx) => {
            const entityData = data.find(e => e.entity_id === i.entity_id)
            itemModel.insert(idx, new Model.Entity(i, entityData))
        })
        initialized = true
    }

    function subscribe() { 
        unsubscribe()
        if (!items.length) return
        const entities = items.map(i => i.entity_id)
        ha.getStates(entities).then(initState)
        cancelSubscription = ha.subscribeState(entities, updateState)
    }

    function unsubscribe() {
        cancelSubscription = typeof cancelSubscription === 'function' && cancelSubscription()
    }

    Component.onCompleted: {
        plasmoid.setAction("open_in_browser", i18n("Open in browser"), plasmoid.icon)
    }

    function action_open_in_browser() {
        Qt.openUrlExternally(url)
    }
}
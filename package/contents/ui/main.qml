import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "."
import "../code/model.mjs" as Model

PlasmoidItem {
    id: root
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
    Plasmoid.backgroundHints: PlasmaCore.Types.StandardBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.configurationRequired: !ClientFactory.error && !(url && ha?.token && items.length)
    Plasmoid.busy: !ClientFactory.error && !plasmoid.configurationRequired && !initialized
    switchHeight: Kirigami.Units.iconSizes.enormous / 2
    switchWidth: Kirigami.Units.iconSizes.enormous
    
    readonly property string url: plasmoid.configuration.url
    readonly property string cfgItems: plasmoid.configuration.items
    property ListModel itemModel: ListModel {}
    property var items: []
    property bool initialized: false
    property QtObject ha
    property var cancelSubscription
    property var fields: ({})

    onCfgItemsChanged: items = JSON.parse(cfgItems)
    onUrlChanged: initClient(url)
    onItemsChanged: fetchDataAndSubscribe()

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Open in Browser")
            icon.name: plasmoid.icon
            onTriggered: Qt.openUrlExternally(url)
        }
    ]

    Notifications {
        id: notifications
    }

    function initClient(url) {
        if (ha) {
            unsubscribe()
            ha.readyChanged.disconnect(fetchDataAndSubscribe)
        }
        if (!url) return ha = null
        ha = ClientFactory.getClient(root, url)     
        fetchDataAndSubscribe()
        ha.readyChanged.connect(fetchDataAndSubscribe)
    }

    function fetchDataAndSubscribe() {
        if (!ha?.ready) return
        fetchFieldsInfo()
        subscribe()
    }

    function fetchFieldsInfo() {
        if (!items.length) return
        ha.getServices().then(s => {
            fields = items.reduce((a, i) => {
                if (i.scroll_action) {
                    const field = i.scroll_action.data_field
                    const key = i.scroll_action.domain + i.scroll_action.service + field
                    const serviceFields = s[i.scroll_action.domain][i.scroll_action.service].fields
                    a[key] = (serviceFields[field] || serviceFields.advanced_fields.fields[field])?.selector
                }
                return a
            },{})
        })
    }

    function processData(event) {
        if (event.a) initState(event.a)
        if (event.c) updateState(event.c)
    }

    function updateState(state) {
        for(let id in state) {
            const itemIdx = items.findIndex(i => i.entity_id === id)
            const change = state[id]['+']
            const item = itemModel.get(itemIdx)
            const newItem = new Model.Entity(item, change)
            const oldValue = item.value
            itemModel.set(itemIdx, newItem)
            if (items[itemIdx].notify && oldValue !== newItem.value) {
                notifications.createNotification(newItem.name + " " + newItem.value)
            }
        }
    }

    function initState(state) {
        itemModel.clear()
        items.forEach((i, idx) => {
            const entityData = state[i.entity_id]
            itemModel.insert(idx, new Model.Entity(i, entityData))
        })
        initialized = true
    }

    function subscribe() { 
        unsubscribe()
        if (!items.length) return
        const entities = items.map(i => i.entity_id)
        cancelSubscription = ha.subscribeEntities(entities, processData)
    }

    function unsubscribe() {
        cancelSubscription = typeof cancelSubscription === 'function' && cancelSubscription()
    }
}

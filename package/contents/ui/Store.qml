import QtQuick

import "./components"
import "../code/model.mjs" as Model
import "../code/formatter.mjs" as Formatter

BaseObject {
    property var items: []
    property string language
    readonly property alias initialized: _.initialized
    readonly property ListModel itemModel: ListModel {}
    readonly property alias fields: _.fields
    readonly property alias hasFullRepresenationItems: _.hasFullRepresenationItems

    onItemsChanged: {
        _.hasFullRepresenationItems = items.some(e => e.display & DisplayFilterModel.Full)
        fetchDataAndSubscribe()
    }

    Component.onDestruction: setClient(null)

    function setClient(client) {
        if (_.client) {
            _.unsubscribe()
            _.client.readyChanged.disconnect(fetchDataAndSubscribe)
        }
        _.client = client
        if (!client) return
        fetchDataAndSubscribe()
        client.readyChanged.connect(fetchDataAndSubscribe)
    }

    function fetchDataAndSubscribe() {
        if (!_?.client?.ready) return
        fetchFieldsInfo()
        _.subscribe()
    }

    function fetchFieldsInfo() {
        if (!items.length) return
        _.client.getServices().then(_.initFields)
    }

    function getUsedEntityIds() {
        return items.map(i => i.entity_id)
    }

    function getUsedDomains() {
        return Array.from(new Set(items.map(i => i.domain)))
    }

    QtObject {
        id: _
        property bool initialized: false
        property var fields: ({})
        property var translations
        property bool hasFullRepresenationItems: false
        property Client client
        property var cancelSubscription

        readonly property var noValueStates: ({
            'unknown': i18nc('Entity state', 'unknown'),
            'unavailable': i18nc('Entity state', 'unavailable')
        })

        function filterRelevantTranslations(r) {
            const result = {};
            for (const k in r) {
                if (k.includes(".state.")) result[k] = r[k];
            }
            return result
        }

        function getTranslationKey(state, domain = "_", device_class = "_") {
            return `component.${domain}.entity_component.${device_class}.state.${state}`
        }

        function loadTranslations() {
            if (language === 'en') return Promise.resolve()
            return client.getTranslations(language, "entity_component", getUsedDomains()).then(({ resources }) => {
                translations = filterRelevantTranslations(resources)
            })
        }

        function getDisplayValue({ attributes, state }, config = {}) {
            const { attribute, domain, value_number_precision } = config
            if (attribute && attributes[attribute]) return attributes[attribute] + ''
            if (!state) return ''
            const unit = attributes.unit_of_measurement
            if (unit && !(state in noValueStates)) return Formatter.formatIfNumber(state, value_number_precision) + (unit === '%' ? unit : ' ' + unit)
            if (!translations) return state
            return translations[getTranslationKey(state, domain, attributes.device_class)]
                || translations[getTranslationKey(state, domain)]
                || noValueStates[state]
                || state
        }

        function subscribe() { 
            unsubscribe()
            if (!items.length) return
            loadTranslations().then(() => {
                cancelSubscription = client.subscribeEntities(getUsedEntityIds(), processState)
            })
        }

        function unsubscribe() {
            cancelSubscription = typeof cancelSubscription === 'function' && cancelSubscription()
        }

        function updateState(state) {
            for(const id in state) {
                const itemIdx = items.findIndex(i => i.entity_id === id)
                const config = items[itemIdx]
                const change = state[id]['+']
                const item = itemModel.get(itemIdx)
                const newItem = new Model.EntityUpdate(config, change, item, { 
                    valueFormatter: getDisplayValue
                })
                const oldValue = item.value
                itemModel.set(itemIdx, newItem)
                if (config.notify && oldValue !== newItem.value) {
                    notifications.createNotification(item.name + " " + newItem.value)
                }
            }
        }

        function initState(state) {
            itemModel.clear()
            items.forEach((i, idx) => {
                const entityData = state[i.entity_id]
                itemModel.insert(idx, new Model.Entity(i, entityData, {
                    valueFormatter: getDisplayValue
                }))
            })
            initialized = true
        }

        function processState(event) {
            if (event.a) initState(event.a)
            if (event.c) updateState(event.c)
        }

        function initFields(services) {
            const results = {}
            for (const i of items) {
                if (!i.scroll_action) continue
                const field = i.scroll_action.data_field
                const key = i.scroll_action.domain + i.scroll_action.service + field
                const serviceFields = services[i.scroll_action.domain][i.scroll_action.service].fields
                results[key] = (serviceFields[field]
                    || serviceFields.additional_fields?.fields[field]
                    || serviceFields.advanced_fields?.fields[field]
                )?.selector
            }
            fields = results
        }
    }
}
import QtQuick

import "./components"
import "../code/model.mjs" as Model
import "../code/formatter.mjs" as Formatter

BaseObject {
    property var items: []
    property string language
    readonly property bool initialized: items.length === itemModel.count
    readonly property ListModel itemModel: ListModel {}
    readonly property var getFieldScrollMapper: _.getFieldScrollMapper
    readonly property alias hasFullRepresenationItems: _.hasFullRepresenationItems

    onItemsChanged: fetchDataAndSubscribe()

    function setClient(client) {
        if (_.client) {
            _.unsubscribe()
            _.client.readyChanged.disconnect(fetchDataAndSubscribe)
        }
        _.client = client
        fetchDataAndSubscribe()
        _.client.readyChanged.connect(fetchDataAndSubscribe)
    }

    function fetchDataAndSubscribe() {
        if (!_.client?.ready) return
        fetchFieldsInfo()
        _.subscribe()
    }

    function fetchFieldsInfo() {
        if (!items.length) return
        _.client.getServices().then(_.initFields)
    }

    function getUsedEntityIds() {
        return Object.keys(_.itemIdxsByEntityId)
    }

    function getUsedDomains() {
        return Array.from(new Set(items.map(i => i.domain)))
    }

    QtObject {
        id: _
        readonly property var fields: new Map()
        property var translations
        readonly property bool hasFullRepresenationItems: items.some(e => e.display & DisplayFilterModel.Full)
        readonly property var itemIdxsByEntityId: items.reduce((o, { entity_id: e }, i) => (o[e] = o[e] || []).push(i) && o, {})
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
            itemModel.clear()
            if (!items.length) return
            loadTranslations().then(() => {
                cancelSubscription = client.subscribeEntities(getUsedEntityIds(), processState)
            })
        }

        function unsubscribe() {
            cancelSubscription = typeof cancelSubscription === 'function' && cancelSubscription()
        }

        function updateState(state) {
            for (const id in state) {
                const itemIdxs = itemIdxsByEntityId[id]
                const change = state[id]['+']
                for (const itemIdx of itemIdxs) {
                    const config = items[itemIdx]
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
        }

        function setState(state) {
            items.forEach((config, idx) => {
                const entityData = state[config.entity_id]
                if (!entityData && initialized) return
                itemModel.set(idx, new Model.Entity(config, entityData, {
                    valueFormatter: getDisplayValue
                }))
            })
        }

        function processState(event) {
            if (event.a) setState(event.a)
            if (event.c) updateState(event.c)
        }

        function fieldKey(action) {
            return action.domain + action.service + action.data_field
        }

        function initFields(services) {
            fields.clear()
            for (const { scroll_action: action } of items) {
                if (!action) continue
                const field = services.getService(action.domain, action.service)
                    .findField(f => f.name === action.data_field, true)
                fields.set(fieldKey(action), field)
            }
        }

        function getFieldScrollMapper(action, attrs) {
            const field = fields.get(fieldKey(action))
            const max = attrs['max_' + field.name] ?? attrs[field.overrides.max] ?? field.selector.number.max ?? 1
            const min = attrs['min_' + field.name] ?? attrs[field.overrides.min] ?? field.selector.number.min ?? 0
            return {
                normalize: value => (value - min) / (max - min),
                denormalize: value => value * (max - min) + min,
                attribute: field.overrides.attribute || field.name
            }
        }
    }
}
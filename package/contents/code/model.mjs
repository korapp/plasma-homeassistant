import { formatIfNumber } from "./formatter.mjs"

const activeStates = ['on', 'open', 'idle']
const noValueStates = ['unknown', 'unavailable']

function getDisplayValue({ attributes, state }, config = {}) {
    const { attribute, value_number_precision } = config
    if (attribute && attributes[attribute]) return attributes[attribute] + ''
    if (!state) return ''
    const unit = attributes.unit_of_measurement
    if (unit && !noValueStates.includes(state)) return formatIfNumber(state, value_number_precision) + (unit === '%' ? unit : ' ' + unit)
    return state
}

export function EntityUpdate(config = {}, update = {}, entity = {}) {
    this.attributes = Object.assign({}, entity.attributes, update.a)
    this.icon = config.icon || this.attributes.icon || ''
    this.state = update.s || entity.state || ''
    this.active = activeStates.includes(this.state)
    this.value = getDisplayValue(this, config)
}

export function Entity(config = {}, data = {}) {
    Object.assign(this, new EntityUpdate(config, data))
    this.entity_id = config.entity_id
    this.name = config.name || this.attributes.friendly_name || ''
    this.attribute = config.attribute || ''
    this.default_action = config.default_action || {}
    this.scroll_action = config.scroll_action || {}
    this.display = config.display ?? 1
    this.domain = config.domain || ''
}

export function ConfigEntity(config = {}) {
    Object.defineProperties(this, {
        entity_id: {
            enumerable: true,
            get: function() { return this[Symbol.for('entity_id')] },
            set: function(id) {
                this[Symbol.for('entity_id')] = id
                this[Symbol.for('domain')] = id.substring(0, id.indexOf('.'))
                updateAction(this, 'default_action')
                updateAction(this, 'scroll_action')
            }
        },
        domain: {
            enumerable: true,
            get: function() { return this[Symbol.for('domain')] }
        }
    });

    addActionProperty(this, 'default_action')
    addActionProperty(this, 'scroll_action')

    this.entity_id = config.entity_id || ''
    this.name = config.name
    this.icon = config.icon
    this.attribute = config.attribute
    this.display = config.display ?? 1
    this.default_action = config.default_action
    this.scroll_action = config.scroll_action
    this.notify = config.notify
    this.value_number_precision = config.value_number_precision
}

function addActionProperty(o, name) {
    Object.defineProperty(o, name, {
        enumerable: true,
        get: function() { return o[Symbol.for(name)] },
        set: function(action) {
            o[Symbol.for(name)] = !action?.service ? null : { 
                service: action.service,
                domain: action.domain || o.domain,
                target: action.target || { entity_id: o.entity_id },
                data_field: action.data_field
            }
        }
    })
}

function updateAction(o, name) {
    if (!o[name]) return
    if (o.domain !== o[name].domain) return o[name] = null
    o[name].target.entity_id = o.entity_id    
}

import { formatIfNumber } from "./formatter.mjs"

const activeStates = ['on', 'open', 'idle']
const noValueStates = ['unknown', 'unavailable']

function getDisplayValue({ state, attribute, attributes, unit, value_number_precision }) {
    if (attribute && attributes[attribute]) return attributes[attribute] + ''
    if (!state) return ''
    if (unit && !noValueStates.includes(state)) return formatIfNumber(state, value_number_precision) + (unit === '%' ? unit : ' ' + unit)
    return state
}

export function Entity({ entity_id = '', name, icon, state, attribute = '', attributes, unit, display = 1, value_number_precision, default_action = {}, scroll_action = {} } = {}, data = {}) {
    this.entity_id = entity_id
    this.attributes = Object.assign({}, attributes, data.a)
    this.state = data.s || state || ''
    this.name = name || this.attributes.friendly_name || ''
    this.icon = icon || this.attributes.icon || ''
    this.unit = unit || this.attributes.unit_of_measurement || ''
    this.attribute = attribute
    this.default_action = default_action
    this.scroll_action = scroll_action
    this.display = display
    this.value_number_precision = value_number_precision
    this.active = activeStates.includes(this.state)
    this.domain = entity_id.substring(0, entity_id.indexOf('.'))
    this.value = getDisplayValue(this)
}

export function ConfigEntity({ entity_id = '', name, icon, attribute, display = 1, value_number_precision, default_action, scroll_action, notify } = {}) {
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

    this.entity_id = entity_id
    this.name = name
    this.icon = icon
    this.attribute = attribute
    this.display = display
    this.default_action = default_action
    this.scroll_action = scroll_action
    this.notify = notify
    this.value_number_precision = value_number_precision
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
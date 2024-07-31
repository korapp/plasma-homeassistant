const activeStates = ['on', 'open', 'idle'];

function getDisplayValue({ state, attribute, attributes, unit }) {
    if (attribute && attributes[attribute]) return attributes[attribute].toString()
    if (state && state !== 'unknown') return state + (unit === '%' ? unit : ' ' + unit)
    return ''
}

export function Entity({ entity_id = '', name, icon, state, attribute = '', attributes, unit, default_action = {}, scroll_action = {} } = {}, data = {}) {
    this.entity_id = entity_id
    this.attributes = Object.assign({}, attributes, data.attributes)
    this.state = data.state || state || ''
    this.name = name || this.attributes.friendly_name || ''
    this.icon = icon || this.attributes.icon || ''
    this.unit = unit || this.attributes.unit_of_measurement || ''
    this.attribute = attribute
    this.default_action = default_action
    this.scroll_action = scroll_action
    this.active = activeStates.includes(this.state)
    this.domain = entity_id.substring(0, entity_id.indexOf('.'))
    this.value = getDisplayValue(this)
}

export function ConfigEntity({ entity_id = '', name, icon, attribute, default_action, scroll_action, notify } = {}) {
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
    this.default_action = default_action
    this.scroll_action = scroll_action
    this.notify = notify
}

function addActionProperty(o, name) {
    Object.defineProperty(o, name, {
        enumerable: true,
        get: function() { return o[Symbol.for(name)] },
        set: function(action) {
            o[Symbol.for(name)] = !action || !action.service ? null : { 
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
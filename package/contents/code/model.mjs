const activeStates = ['on', 'open'];

function getDisplayValue({ state, domain, attribute, attributes }) {
    if (domain === 'button') return ''
    if (attribute) {
        return attributes[attribute] || ''
    }
    if (state && state !== 'unknown') {
        const unit = attributes.unit_of_measurement
        return state + (unit ? (unit === '%' ? '' : ' ') + unit : '')
    }
    return ''
}

export function Entity({ entity_id = '', domain, name, icon, attribute = '', default_action = {} }, { state, attributes = {} } = {}) {
    this.entity_id = entity_id
    this.domain = domain
    this.name = name || attributes.friendly_name || ''
    this.icon = icon || attributes.icon || ''
    this.attribute = attribute
    this.default_action = default_action
    this.active = activeStates.includes(state)
    this.domain = entity_id.substring(0, entity_id.indexOf('.'))
    this.state = state
    this.value = getDisplayValue({ state, domain: this.domain, attribute, attributes })
}

export function ConfigEntity({ entity_id = '', name, icon, attribute, default_action, notify } = {}) {
    Object.defineProperties(this, {
        entity_id: {
            get: function() { return this._entity_id },
            set: function(id) {
                this._entity_id = id
                this._domain = id.substring(0, id.indexOf('.'))
                if (!this._default_action) return
                if (this._domain === this._default_action.domain) {
                    this._default_action.target.entity_id = id
                } else {
                    delete this._default_action
                }
            }
        },
        domain: {
            get: function() { return this._domain }
        },
        default_action: {
            get: function() { return this._default_action },
            set: function({ domain = this.domain, service, target = { entity_id: this.entity_id }} = {}) {
                if (!service) return delete this._default_action
                this._default_action = {
                    domain,
                    service,
                    target
                }
            }
        },
    });

    this.entity_id = entity_id
    this.name = name
    this.icon = icon
    this.attribute = attribute
    this.default_action = default_action
    this.notify = notify
}

ConfigEntity.prototype.toJSON = function() {
    return {
        attribute: this.attribute,
        entity_id: this.entity_id,
        icon: this.icon,
        name: this.name,
        default_action: this.default_action,
        notify: this.notify
    }
}
import { SERVICE_FIELDS_TO_ATTRIBUTES as OVERRIDES } from 'serviceOverrides.mjs'

export function fromObject(s) {
    return {
        getDomains() {
            return Object.keys(s)
        },
        getNames(domain) {
            return domain ? Object.keys(s[domain] ?? {}) : []
        },
        getService(domain, service) {
            return new Service(domain, service, s[domain]?.[service])
        }
    }
}

class Service {
    constructor(domain, name, { fields } = {}) {
        this.domain = domain
        this.name = name
        this.fields = fields
    }

    filterFields(predicate, recursive) {
        const result = []
        for (const field of Service.traverseFields(this, recursive)) {
            if (predicate(field)) result.push(field)
        }
        return result
    }

    findField(predicate, recursive) {
        for (const field of Service.traverseFields(this, recursive)) {
            if (predicate(field)) return field
        }
    }

    static *traverseFields({ domain, name, fields = {} } = {}, recursive) {
        for (const [k, v] of Object.entries(fields)) {
            if (recursive && v.fields) {
                yield* Service.traverseFields({ domain, name, fields: v.fields }, true)
                continue
            }
            yield new Field(k, v, OVERRIDES[domain]?.[name]?.[k])
        }
    }
}

class Field {
    constructor(name, field, overrides = {}) {
        this.name = name
        this.filter = field.filter
        this.selector = field.selector
        this.overrides = overrides
    }

    isApplicableTo(entity) {
        return !this.filter || this._supportsFeature(entity) || this._hasRequiredAttributes(entity)
    }

    _supportsFeature(entity) {
        return this.filter.supported_features?.some(f => f & entity.attributes.supported_features)
    }

    _hasRequiredAttributes(entity) {
        return Object.entries(this.filter.attribute || {}).every(([a, values]) => values.some(v => entity.attributes[a]?.includes(v)))
    }

    isNumber() {
        return !!this.selector?.number
    }

    hasCorrespondingAttribute(entity) {
        return (this.overrides.attribute || this.name) in entity.attributes
    }
}
const SERVICE_FIELDS_TO_ATTRIBUTES = Object.freeze({})

export function getFieldsForService(domain, service) {
  return SERVICE_FIELDS_TO_ATTRIBUTES[domain]?.[service] ?? {}
}

export function getField(domain, service, field) {
  return getFieldsForService(domain, service)[field] ?? {}
}
const SERVICE_FIELDS_TO_ATTRIBUTES = Object.freeze({
  climate: {
    set_temperature: {
      temperature: {
        max: 'max_temp',
        min: 'min_temp'
      }
    }
  },
  cover: {
    set_cover_position: {
      position: {
        attribute: 'current_position'
      }
    },
    set_cover_titlt_position: {
      tilt_position: {
        attribute: 'curent_tilt_position'
      }
    }
  }
})

export function getFieldsForService(domain, service) {
  return SERVICE_FIELDS_TO_ATTRIBUTES[domain]?.[service] ?? {}
}

export function getField(domain, service, field) {
  return getFieldsForService(domain, service)[field] ?? {}
}
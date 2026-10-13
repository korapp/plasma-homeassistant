const BLACKLIST = ['_class', '_modes', '_name', '_list', '_step', 'max_', 'min_', 'supported_', 'access_token', 'icon', 'unit_of_measurement']

export function filter(attributes = []) {
    return attributes.filter(a => !BLACKLIST.some(b => a.includes(b)))
}
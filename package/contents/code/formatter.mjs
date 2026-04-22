const locale = Qt.locale()

export function formatIfNumber(value, precision) {
    if (!(precision >=0)) return value
    const n = +value
    return isNaN(n) ? value : n.toLocaleString(locale, "f", precision)
}

export function getDefaultPrecision(value, maxSignificantDigits = 3) {
    const dotIdx = value.indexOf(".")
    if (dotIdx === -1) return 0
    const fractionDigits = value.length - dotIdx - 1
    const integerDigits = dotIdx - value.startsWith("-")
    return Math.min(Math.max(maxSignificantDigits - integerDigits, 0), fractionDigits)
}
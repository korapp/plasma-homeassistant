pragma Singleton

import QtQuick
import org.kde.ksvg as KSvg

KSvg.Svg {
    imagePath: Qt.resolvedUrl("mdi.svgz")
    multipleImages: true

    function scaleSize(s1, s2) {
        const scale = Math.min(s2.width / s1.width, s2.height / s1.height)
        return Qt.size(s1.width * scale, s1.height * scale)
    }

    function scaleIconForPlasma(name, size) {
        const margin = getPlasmaMargin(size.height) * 2
        return scaleSize(elementSize(name), Qt.size(size.width - margin, size.height - margin))
    }

    function getPlasmaMargin(s) {
        if (s >= 96) return 9
        if (s >= 64) return 6
        if (s >= 48) return 4
        if (s >= 22) return 3
        return 2
    }
}
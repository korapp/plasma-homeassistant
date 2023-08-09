pragma Singleton

import QtQuick 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

PlasmaCore.Svg {
    imagePath: Qt.resolvedUrl("mdi.svgz")
    multipleImages: true

    function scaleSize(s1, s2) {
        const scale = Math.min(s2.width / s1.width, s2.height / s1.height)
        return Qt.size(s1.width * scale, s1.height * scale)
    }

    function get(name, size) {
        if (!size.width || !size.height) return
        const elSize = scaleSize(elementSize(name), size)
        return image(elSize, name)
    }
}
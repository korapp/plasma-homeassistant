import QtQuick

import org.kde.kirigami as Kirigami

import "."

Kirigami.Icon {
    property string name
    color: Kirigami.Theme.textColor
    isMask: true
    onNameChanged: () => source = name ? Mdi.get(name, Qt.size(width, height)) : null
}

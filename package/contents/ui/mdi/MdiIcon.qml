import QtQuick 2.0

import org.kde.kirigami 2.4 as Kirigami

import "."

Kirigami.Icon {
    property string name
    color: Kirigami.Theme.textColor
    isMask: true
    onNameChanged: () => source = name ? Mdi.get(name, Qt.size(width, height)) : null
}

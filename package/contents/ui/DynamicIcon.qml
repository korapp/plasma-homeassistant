import QtQuick

import org.kde.kirigami as Kirigami

import 'mdi'

Loader {
    id: dynamicIcon
    property string name
    property string type
    property string id
    property color color: "transparent"

    sourceComponent: {
        switch(type) {
            case 'mdi': return mdi
            case 'plasma': return plasma
        }
    }

    onNameChanged: () => {
        if (!name || !~name.indexOf(':')) return
        [type, id] = name.split(':')
    }

    Component {
        id: mdi
        MdiIcon {
            name: id
            color: dynamicIcon.color.a > 0 ? dynamicIcon.color : Kirigami.Theme.textColor
        }
    }

    Component {
        id: plasma
        Kirigami.Icon {
            source: id
            color: dynamicIcon.color
        }
    }
}
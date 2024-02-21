import QtQuick

import org.kde.kirigami as Kirigami

import 'mdi'

Loader {
    property string name
    property string type
    property string id

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
        }
    }

    Component {
        id: plasma
        Kirigami.Icon {
            source: id
        }
    }
}
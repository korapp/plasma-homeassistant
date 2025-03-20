import QtQuick 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

import 'mdi'

Loader {
    property string name
    property string type
    property string id
    property int colorGroup: PlasmaCore.ColorScope.colorGroup

    sourceComponent: {
        switch(type) {
            case 'mdi': return mdi
            case 'plasma': return plasma
        }
    }

    onNameChanged: {
        if (!name || !~name.indexOf(':')) return
        [type, id] = name.split(':')
    }

    Component {
        id: mdi
        MdiIcon {
            name: id
            colorGroup: parent.colorGroup
        }
    }

    Component {
        id: plasma
        PlasmaCore.IconItem {
            source: id
            colorGroup: parent.colorGroup
        }
    }
}
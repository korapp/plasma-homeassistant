import QtQuick

import org.kde.kirigami as Kirigami

import 'mdi'

Loader {
    property string name
    property string id

    onNameChanged: {
        let type
        [id, type] = name?.split(':').reverse() || []
        sourceComponent = id ? { mdi, plasma }[type] || plasma : undefined
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
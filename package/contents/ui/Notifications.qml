import QtQuick

import org.kde.notification

import "components"

BaseObject {
    property bool enabled: true
    Component {
        id: notificationComponent
        Notification {
            componentName: "plasma_workspace"
            eventId: "notification"
            title: plasmoid.title
            iconName: plasmoid.icon
            autoDelete: true
        }
    }

    function createNotification(text) {
        enabled && notificationComponent.createObject(root, { text })?.sendEvent()
    }
}
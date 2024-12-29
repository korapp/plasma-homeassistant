import QtQuick

import org.kde.notification

import "components"

BaseObject {
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
        notificationComponent.createObject(root, { text })?.sendEvent()
    }
}
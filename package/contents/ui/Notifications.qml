import QtQuick 2.0

import org.kde.notification 1.0

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
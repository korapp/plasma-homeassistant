import QtQuick 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

PlasmaCore.DataSource {
    id: notificationSource
    engine: "notifications"
    connectedSources: "org.freedesktop.Notifications"

    function createNotification(summary, { appName = plasmoid.title, appIcon = plasmoid.icon } = {}, actions) {        
        const service = notificationSource.serviceForSource("notification");
        const operation = service.operationDescription("createNotification");

        operation.appName = appName
        operation.appIcon = appIcon
        operation.summary = summary
        operation.expireTimeout = 5000
        if (actions) {
            operation.actions = actions
        }

        service.startOperationCall(operation);
    }
}
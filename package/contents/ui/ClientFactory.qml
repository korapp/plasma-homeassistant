pragma Singleton

import QtQuick 2.0

import "components"

BaseObject {
    readonly property var _instances: new Map()
    readonly property Component clientComponent: Qt.createComponent("Client.qml")
    readonly property bool error: clientComponent.status === Component.Error
    readonly property var errorString: clientComponent.errorString

    Secrets {
        id: secrets
        readonly property var init: new Promise(resolve => onReady.connect(resolve))
        function getToken(url) {
            return init.then(() => get(url))
        }
    }
    
    function getClient(consumer, baseUrl) {
        if (!(consumer instanceof QtObject) || !baseUrl) return
        let instance = _findInstance(baseUrl)
        if (!instance) {
            instance = _createClient(baseUrl)
        }
        if (!_instances.has(consumer)) {
            consumer.Component.destruction.connect(() => _instances.delete(consumer))
        }
        _instances.set(consumer, instance)
        return instance
    }

    function _createClient(baseUrl) {
        const client = clientComponent.createObject(null, { baseUrl })
        secrets.getToken(baseUrl).then(t => client.token = t)
        return client
    }

    function _findInstance(url) {
        return Array.from(_instances.values()).find(i => i.baseUrl === url)
    }
}
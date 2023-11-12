pragma Singleton

import QtQuick 2.0

import "components"

BaseObject {
    readonly property var _instances: new Map()

    Secrets {
        id: secrets
        readonly property var init: new Promise(resolve => onReady.connect(resolve))
        function getToken(url) {
            return init.then(() => get(url))
        }
    }

    Component {
        id: clientComponent
        Client {
            onBaseUrlChanged: secrets.getToken(baseUrl).then(t => token = t)
        }
    }
    
    function getClient(consumer, baseUrl) {
        if (!(consumer instanceof QtObject) || !baseUrl) return
        let instance = _findInstance(baseUrl)
        if (!instance) {
            instance = clientComponent.createObject(null, { baseUrl })
        }
        if (!_instances.has(consumer)) {
            consumer.Component.destruction.connect(() => _instances.delete(consumer))
        }
        _instances.set(consumer, instance)
        return instance
    }

    function _findInstance(url) {
        return Array.from(_instances.values()).find(i => i.baseUrl === url)
    }
}
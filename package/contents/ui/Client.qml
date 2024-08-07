import QtQuick
import QtWebSockets

import "components"

BaseObject {
    property string baseUrl
    property string token
    property var subscribeEntities: ws.subscribeEntities
    property var callService: ws.callService
    property var getServices: ws.getServices
    property var getStates: ws.getStates
    property string errorString: ""
    readonly property alias ready: ws.ready
    readonly property bool configured: ws.url && token
    
    onBaseUrlChanged: ws.url = baseUrl.replace('http', 'ws') + "/api/websocket"
    onConfiguredChanged: ws.active = configured
    
    Connections {
        target: ws
        function onError(msg) { errorString = msg }
        function onReadyChanged() { ws.ready && (errorString = "") }
    }

    Timer {
        id: pingPongTimer
        interval: 30000
        running: ws.status
        repeat: true
        property bool waiting
        onTriggered: {
            if (waiting || !ws.open) {
                ws.reconnect()
            } else {
                ws.ping()
            }   
            waiting = !waiting         
        }
        function reset() {
            waiting = false
            restart()
        }
    }

    WebSocket {
        id: ws
        property bool ready: false
        property int messageCounter: 0
        property var subscriptions: new Map()
        property var promises: new Map()
        readonly property bool open: status === WebSocket.Open
        signal error(string msg)

        onOpenChanged: ready = false

        onTextMessageReceived: message => {
            pingPongTimer.reset()
            const msg = JSON.parse(message)
            switch (msg.type) {
                case 'auth_required': auth(token); break;
                case 'auth_ok': ready = true; break;
                case 'auth_invalid': error(msg.message); break;
                case 'event': notifyStateUpdate(msg); break;
                case 'result': handleResult(msg); break;
            }
        }

        onErrorStringChanged: () => errorString && error(errorString)

        function reconnect() {
            active = false
            active = true
        }

        function handleResult(msg) {
            const p = promises.get(msg.id)
            if (!p) return
            if (msg.success) {
                p.resolve(msg.result)
            } else {
                p.reject(msg.error)
            }
            promises.delete(msg.id)
        }

        function auth(token) {
            send({"type": "auth", "access_token": token})
        }

        function notifyStateUpdate(msg) {
            const callback = subscriptions.get(msg.id)
            return callback && callback(msg.event)
        }

        function subscribeEntities(entity_ids, callback) {
            if (!entity_ids) return
            const subscription = command({"type": "subscribe_entities", entity_ids})
            subscriptions.set(subscription, callback)
            return () => unsubscribe(subscription)
        }

        function unsubscribe(subscription) {
            if(!subscriptions.has(subscription)) return
            return commandAsync({"type": "unsubscribe_events", subscription})
                .then(() => subscriptions.delete(subscription))
        }

        function callService({ domain, service, target } = {}, data) {
            return commandAsync({
                "type": "call_service",
                "domain": domain,
                "service": service,
                "service_data": data,
                "target": target
            })
        }

        function getStates(entities) {
            return commandAsync({"type": "get_states"})
                .then(s => entities ? s.filter(e => entities.includes(e.entity_id)) : s)
        }

        function getServices() {
            return commandAsync({"type": "get_services"})
        }

        function ping() {
            return command({"type": "ping"})
        }

        function commandAsync(message) {
            const id = command(message)
            return new Promise((resolve, reject) => promises.set(id, {resolve, reject}))
        }

        function command(message) {
            return send(Object.assign({}, {id: messageCounter}, message))
        }

        function send(message) {
            sendTextMessage(JSON.stringify(message))
            return messageCounter++
        }

        function unsubscribeAll() {
            Array.from(subscriptions.keys()).forEach(unsubscribe)
        }

        Component.onDestruction: unsubscribeAll()
    }
}
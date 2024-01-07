import QtQuick 2.0
import QtWebSockets 1.0

import "components"

BaseObject {
    property string baseUrl
    property string token
    property var subscribeState: ws.subscribeState
    property var callService: ws.callService
    property var getServices: ws.getServices
    property var getStates: ws.getStates
    property string errorString: ""
    readonly property bool configured: ws.url && token
    
    onBaseUrlChanged: ws.url = baseUrl.replace('http', 'ws') + "/api/websocket"
    onConfiguredChanged: ws.active = configured
    
    Connections {
        target: ws
        onError: errorString = msg
        onEstablished: errorString = ""
    }

    readonly property QtObject ready: QtObject {
        function connect (fn) {
            if (ws.ready) fn()
            ws.established.connect(fn)
        }
        function disconnect (fn) {
            ws.established.disconnect(fn)
        }
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
        signal established
        signal error(string msg)

        onOpenChanged: ready = false
        onReadyChanged: ready && established()

        onTextMessageReceived: {
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

        onErrorStringChanged: errorString && error(errorString)

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
            return callback && callback(msg.event.variables.trigger.to_state)
        }

        function subscribeState(entities, callback) {
            if (!callback) return
            const subscription = subscribe({
                "platform": "state",
                "entity_id": entities
            })
            subscriptions.set(subscription, callback)
            return () => unsubscribe(subscription)
        }

        function subscribe(trigger) {
            return command({"type": "subscribe_trigger", trigger})
        }

        function unsubscribe(subscription) {
            if(!subscriptions.has(subscription)) return
            return commandAsync({"type": "unsubscribe_events", subscription})
                .then(() => subscriptions.delete(subscription))
        }

        function callService({ domain, service, data, target } = {}) {
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
import QtQuick 2.0
import QtWebSockets 1.0

import "components"

BaseObject {
    property string apiUrl
    property string baseUrl
    property string token
    property var subscribeState: ws.subscribeState
    property var unsubscribe: ws.unsubscribe
    property var callService: ws.callService
    property var getServices: ws.getServices
    property var getStates: ws.getStates

    signal ready()
    signal stateChanged(var state)
    
    onBaseUrlChanged: apiUrl = baseUrl.replace('http', 'ws') + "/api/websocket"
    onTokenChanged: ws.active = apiUrl && token

    Timer {
        id: pingPongTimer
        interval: 30000
        running: ws.active
        repeat: true
        property bool waiting
        onTriggered: {
            if (waiting) {
                ws.reconnect()
            } else {
                ws.ping()
            }   
            waiting = !waiting         
        }
    }

    WebSocket {
        id: ws
        url: apiUrl
        property int messageCounter: 0
        property var promises: new Map()

        onTextMessageReceived: {
            const msg = JSON.parse(message)
            switch (msg.type) {
                case 'auth_required': auth(token); break;
                case 'auth_ok': ready(); break;
                case 'auth_invalid': console.error(msg.message); break;
                case 'event': stateChanged(msg.event); break;
                case 'result': handleResult(msg); break;
                case 'pong': pingPongTimer.waiting = false
            }
        }

        onErrorStringChanged: errorString && console.error(errorString)

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

        function subscribeState(entities) {
            if (!entities) return
            return subscribe({
                "platform": "state",
                "entity_id": entities
            })
        }

        function subscribe(trigger) {
            return command({"type": "subscribe_trigger", trigger})
        }

        function unsubscribe(subscription) {
            return command({"type": "unsubscribe_events", subscription})
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
    }
}
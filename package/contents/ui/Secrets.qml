pragma Singleton

import QtQuick 2.0

import "../lib/secrets"

Secrets { 
    appId: "HomeAssistant"
    property string token
    property string entryKey
    
    onReady: {
        restore()
        onEntryKeyChanged.connect(restore)
        onTokenChanged.connect(() => set(entryKey, token))
    }

    function restore() {
        if (entryKey) {
            get(entryKey).then(t => token = t)
        }
    }
}
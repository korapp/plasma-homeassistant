import QtQuick
import QtQuick.Controls

Menu {
    id: menu
    property var options: []
    property string current
    property string label
    property var format: o => o
    // optimistic selection, shown until the server echoes a change or the timeout hits
    // (cloud integrations can take many seconds to reflect a change back)
    property string pending
    signal selected(string option)

    title: {
        const value = pending || current
        return value ? `${label} · ${format(value)}` : label
    }

    // Check marks are managed imperatively: clicking a checkable MenuItem writes
    // `checked` directly, which silently destroys declarative bindings, so the
    // marks are re-synced from state on every show and on every change instead.
    onAboutToShow: sync()
    onCurrentChanged: {
        pending = ''
        sync()
    }
    onPendingChanged: pending ? pendingTimeout.restart() : pendingTimeout.stop()

    function sync() {
        const value = pending || current
        for (let i = 0; i < items.count; i++) {
            const item = items.objectAt(i)
            if (item) item.checked = options[i] === value
        }
    }

    function select(option) {
        pending = option
        sync()
        selected(option)
    }

    Timer {
        id: pendingTimeout
        interval: 30000
        onTriggered: {
            menu.pending = ''
            menu.sync()
        }
    }

    Instantiator {
        id: items
        model: menu.options
        delegate: MenuItem {
            text: menu.format(modelData)
            checkable: true
            onTriggered: menu.select(modelData)
        }
        onObjectAdded: (index, object) => menu.insertItem(index, object)
        onObjectRemoved: (index, object) => menu.removeItem(object)
    }
}

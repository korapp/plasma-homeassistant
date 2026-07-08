import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

import org.kde.kirigami as Kirigami

import "."

GridLayout {
    id: tile
    columns: 2
    rows: 2
    clip: true
    columnSpacing: Kirigami.Units.smallSpacing
    rowSpacing: 0

    readonly property var attrs: model.attributes
    readonly property string hvacMode: model.state
    readonly property string hvacModesKey: JSON.stringify(attrs.hvac_modes || [])
    readonly property var hvacModes: JSON.parse(hvacModesKey)
    readonly property bool available: !['', 'unknown', 'unavailable'].includes(hvacMode)
    readonly property real minTemp: Number(attrs.min_temp ?? 7)
    readonly property real maxTemp: Number(attrs.max_temp ?? 35)
    readonly property real tempStep: Number(attrs.target_temp_step || 0.5)
    readonly property string activity: attrs.hvac_action || hvacMode
    // string key so pending is only reset when setpoint values actually change,
    // not on every attributes object replacement
    readonly property string liveSetpointKey: JSON.stringify(attrs.temperature != null
        ? { temperature: attrs.temperature }
        : attrs.target_temp_low != null && attrs.target_temp_high != null
            ? { target_temp_low: attrs.target_temp_low, target_temp_high: attrs.target_temp_high }
            : null)
    readonly property var liveSetpoint: JSON.parse(liveSetpointKey)
    property var pending: null
    readonly property var setpoint: pending || liveSetpoint
    // optimistic hvac mode, mirrors ClimateOptionMenu.pending
    property string pendingMode

    // static per-entity; keyed so submenus aren't rebuilt on every state update
    readonly property string optionGroupsKey: JSON.stringify([attrs.preset_modes, attrs.fan_modes, attrs.swing_modes, attrs.swing_horizontal_modes])
    readonly property var optionGroups: {
        const [presets, fans, swings, swingsH] = JSON.parse(optionGroupsKey)
        return [
            { title: i18n("Preset"), list: presets || [], service: 'set_preset_mode', field: 'preset_mode' },
            { title: i18n("Fan"), list: fans || [], service: 'set_fan_mode', field: 'fan_mode' },
            { title: i18n("Swing"), list: swings || [], service: 'set_swing_mode', field: 'swing_mode' },
            { title: i18n("Horizontal swing"), list: swingsH || [], service: 'set_swing_horizontal_mode', field: 'swing_horizontal_mode' }
        ].filter(g => g.list.length)
    }

    readonly property var activityColors: ({
        heat: '#ff8100', heating: '#ff8100',
        cool: '#2196f3', cooling: '#2196f3',
        heat_cool: '#ff9800',
        auto: '#4caf50',
        dry: '#ffc107', drying: '#ffc107',
        fan_only: '#4db6ac', fan: '#4db6ac'
    })
    readonly property color activityColor: activityColors[activity] || Kirigami.Theme.textColor

    readonly property real setpointRatio: {
        const s = setpoint
        if (!s) return 0
        const v = s.temperature ?? s.target_temp_low
        return Math.min(1, Math.max(0, (v - minTemp) / (maxTemp - minTemp)))
    }

    // the server may echo an older commit while newer adjustments are still
    // pending — only treat an echo of the pending value itself as confirmation
    onLiveSetpointKeyChanged: {
        if (pending && liveSetpointKey === JSON.stringify(pending)) {
            pending = null
        }
    }

    function formatTemp(t, decimals) {
        return Number(t).toLocaleString(Qt.locale(), 'f', decimals ?? (tempStep % 1 ? 1 : 0)) + '°'
    }

    function formatSetpoint(s) {
        return s.temperature != null
            ? formatTemp(s.temperature)
            : formatTemp(s.target_temp_low) + '–' + formatTemp(s.target_temp_high)
    }

    function adjust(steps) {
        if (!available || !setpoint) return
        confirmTimer.stop()
        const round = v => Math.round(v * 100) / 100
        const s = setpoint
        if (s.temperature != null) {
            pending = { temperature: round(Math.min(maxTemp, Math.max(minTemp, s.temperature + steps * tempStep))) }
        } else {
            const d = Math.max(minTemp - s.target_temp_low, Math.min(maxTemp - s.target_temp_high, steps * tempStep))
            pending = { target_temp_low: round(s.target_temp_low + d), target_temp_high: round(s.target_temp_high + d) }
        }
        commitTimer.restart()
    }

    function callClimate(service, data) {
        ha.callService({ domain: 'climate', service, target: { entity_id: model.entity_id } }, data)
    }

    function setMode(mode) {
        pendingMode = mode
        modeMenu.syncModes()
        callClimate('set_hvac_mode', { hvac_mode: mode })
    }

    function formatOption(value, field) {
        return store.translateAttributeValue(value, 'climate', field).replace(/_/g, ' ')
    }

    function openMenu(anchor) {
        anchor ? modeMenu.popup(anchor, 0, anchor.height) : modeMenu.popup()
        return modeMenu
    }

    Timer {
        id: commitTimer
        interval: 800
        onTriggered: {
            if (!tile.pending) return
            confirmTimer.restart()
            ha.callService({ domain: 'climate', service: 'set_temperature', target: { entity_id: model.entity_id } }, tile.pending)
                .catch(() => tile.pending = null)
        }
    }

    // keeps the optimistic value until the server echoes it back or times out
    Timer {
        id: confirmTimer
        interval: 10000
        onTriggered: tile.pending = null
    }

    WheelHandler {
        enabled: tile.available && !!tile.setpoint
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real acc: 0
        onWheel: event => {
            acc += event.angleDelta.y
            const steps = Math.trunc(acc / 120)
            if (steps) {
                acc -= steps * 120
                tile.adjust(steps)
            }
        }
    }

    onHvacModeChanged: {
        pendingMode = ''
        modeMenu.syncModes()
    }
    onPendingModeChanged: pendingMode ? modePendingTimeout.restart() : modePendingTimeout.stop()

    Timer {
        id: modePendingTimeout
        interval: 30000
        onTriggered: {
            tile.pendingMode = ''
            modeMenu.syncModes()
        }
    }

    Menu {
        id: modeMenu

        // see ClimateOptionMenu.qml — click-toggles break `checked` bindings,
        // so mode marks are re-synced imperatively instead
        onAboutToShow: syncModes()

        function syncModes() {
            const value = tile.pendingMode || tile.hvacMode
            for (let i = 0; i < modeItems.count; i++) {
                const item = modeItems.objectAt(i)
                if (item) item.checked = tile.hvacModes[i] === value
            }
        }

        Instantiator {
            id: modeItems
            model: tile.hvacModes
            delegate: MenuItem {
                text: store.translateState(modelData, 'climate').replace(/_/g, ' ')
                checkable: true
                onTriggered: tile.setMode(modelData)
            }
            onObjectAdded: (index, object) => modeMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => modeMenu.removeItem(object)
        }

        MenuSeparator {
            visible: tile.optionGroups.length > 0
        }

        Instantiator {
            model: tile.optionGroups
            delegate: ClimateOptionMenu {
                label: modelData.title
                options: modelData.list
                current: tile.attrs[modelData.field] || ''
                format: o => tile.formatOption(o, modelData.field)
                onSelected: option => tile.callClimate(modelData.service, { [modelData.field]: option })
            }
            onObjectAdded: (index, object) => modeMenu.addMenu(object)
            onObjectRemoved: (index, object) => modeMenu.removeMenu(object)
        }
    }

    DynamicIcon {
        name: model.icon || 'mdi:thermostat'
        color: tile.activityColor
        opacity: tile.available ? 1 : 0.6
        Layout.rowSpan: 2
        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Kirigami.Units.iconSizes.medium

        MouseArea {
            anchors.fill: parent
            enabled: tile.available && (tile.hvacModes.length || tile.optionGroups.length)
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: tile.openMenu(parent)
        }
    }

    RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true

        PlasmaExtras.Heading {
            level: 4
            text: tile.setpoint ? tile.formatSetpoint(tile.setpoint) : model.value
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            font.weight: Font.Bold
            Layout.fillWidth: true

            // level indicator: target position within min/max, follows the
            // optimistic value while adjusting
            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                height: 2
                radius: 1
                width: parent.width * tile.setpointRatio
                color: tile.activityColor
                opacity: 0.7
                visible: !!tile.setpoint
            }
        }

        PlasmaComponents3.ToolButton {
            icon.name: "list-remove"
            icon.width: Kirigami.Units.iconSizes.small
            icon.height: Kirigami.Units.iconSizes.small
            display: AbstractButton.IconOnly
            text: i18n("Decrease temperature")
            visible: !!tile.setpoint
            enabled: tile.available
            autoRepeat: true
            onClicked: tile.adjust(-1)
            ToolTip.text: text
            ToolTip.visible: hovered
            ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        PlasmaComponents3.ToolButton {
            icon.name: "list-add"
            icon.width: Kirigami.Units.iconSizes.small
            icon.height: Kirigami.Units.iconSizes.small
            display: AbstractButton.IconOnly
            text: i18n("Increase temperature")
            visible: !!tile.setpoint
            enabled: tile.available
            autoRepeat: true
            onClicked: tile.adjust(1)
            ToolTip.text: text
            ToolTip.visible: hovered
            ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        PlasmaComponents3.ToolButton {
            id: menuButton
            icon.name: "overflow-menu"
            icon.width: Kirigami.Units.iconSizes.small
            icon.height: Kirigami.Units.iconSizes.small
            display: AbstractButton.IconOnly
            text: i18n("Mode and options")
            visible: tile.hvacModes.length || tile.optionGroups.length
            enabled: tile.available
            onClicked: tile.openMenu(menuButton)
            ToolTip.text: text
            ToolTip.visible: hovered
            ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: name
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PlasmaComponents3.Label {
            readonly property var current: tile.attrs.current_temperature
            readonly property string modeText: tile.available ? store.translateState(tile.hvacMode, 'climate').replace(/_/g, ' ') : ''
            text: [modeText, current != null ? tile.formatTemp(current, current % 1 ? 1 : 0) : ''].filter(Boolean).join(' · ')
            visible: !!text
            font: Kirigami.Theme.smallFont
            color: tile.activityColor
            opacity: tile.activity in tile.activityColors ? 1 : 0.7
        }
    }
}

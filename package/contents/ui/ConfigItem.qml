import QtQuick 2.15
import QtQuick.Controls 2.0

import org.kde.kirigami 2.4 as Kirigami

import "components"

Kirigami.FormLayout {
    property var item
    readonly property var source: item.entity_id && entities[item.entity_id] || {}
    readonly property var itemServices: item.domain && services[item.domain] || {}

    TextField {
        Kirigami.FormData.label: i18n("Entity")
        text: item.entity_id
        onEditingFinished: {
            item.entity_id = text
            item = item
        }
        Autocompletion {
            model: Object.keys(entities).sort()
        }
    }

    ComboBox {
        displayText: currentText || item.attribute
        model: source.attributes ? Object.keys(source.attributes) : []
        onActivated: item.attribute = model[index]
        onModelChanged: currentIndex = item.attribute ? model.indexOf(item.attribute) : -1
        enabled: Kirigami.FormData.checked
        onEnabledChanged: activated(enabled ? currentIndex : -1)
        Kirigami.FormData.checked: !!item.attribute
        Kirigami.FormData.label: i18n("Display attribute")
        Kirigami.FormData.checkable: true
    }

    TextField {
        text: item.name || ''
        placeholderText: source.attributes && source.attributes.friendly_name || ''
        onTextChanged: item.name = text
        Kirigami.FormData.label: i18n("Name")
    }

    Row {
        Kirigami.FormData.label: i18n("Icon")
        spacing: Kirigami.Units.smallSpacing
        TextField {
            id: iconName
            text: item.icon || ''
            placeholderText: (source.attributes && source.attributes.icon) || 'mdi: | plasma:'
            onTextChanged: item.icon = text
        }
        DynamicIcon {
            name: iconName.text || iconName.placeholderText
        }
    }

    CheckBox {
        Kirigami.FormData.label: i18n("Notify about changes")
        checked: !!item.notify
        onCheckedChanged: item.notify = checked
    }

    component ServiceSelector: Row {
        visible: !!serviceSelector.count
        property alias currentValue: serviceSelector.currentValue
        property var initialValue
        property var serviceFilter
        default property alias data: nested.data
        CheckBox {
            id: useAction
            anchors.verticalCenter: parent.verticalCenter
        }
        ComboBox {
            id: serviceSelector
            model: serviceFilter ? Object.keys(itemServices).filter(serviceFilter) : Object.keys(itemServices)
            enabled: useAction.checked
            onEnabledChanged: if (!enabled) currentIndex = -1
            onCurrentIndexChanged: useAction.checked = ~currentIndex
            onModelChanged: resetIndex()
            Component.onCompleted: resetIndex()
            function resetIndex() {
                currentIndex = initialValue && count ? indexOfValue(initialValue) : -1
            }
        }
        Column {
            enabled: serviceSelector.enabled
            id: nested
        }
    }

    ServiceSelector {
        Kirigami.FormData.label: i18n("Click action")
        initialValue: item.default_action && item.default_action.service
        onCurrentValueChanged: s => item.default_action = { service: currentValue }
    }

    ServiceSelector {
        id: scrollActionSelector
        Kirigami.FormData.label: i18n("Scroll action")
        serviceFilter: k => getNumberFields(itemServices[k]).length
        initialValue: item.scroll_action && item.scroll_action.service
        onCurrentValueChanged: scrollFieldSelector.model = getNumberFields(itemServices[currentValue])

        ComboBox {
            id: scrollFieldSelector
            model: scrollActionSelector.currentValue
            onCurrentValueChanged: item.scroll_action = { service: scrollActionSelector.currentValue, data_field: currentValue }
            onModelChanged: currentIndex = item.scroll_action && item.scroll_action.data_field
                ? indexOfValue(item.scroll_action.data_field)
                : count === 1 ? 0 : -1
        }
    }

    function getNumberFields({ fields = {} } = {}) {
        return Object.keys(fields)
            .reduce((f, id) => {
                const field = fields[id]
                if (field.fields) f.push(...getNumberFields(field))
                if (field.selector && field.selector.number && source.attributes && id in source.attributes) f.push(id)
                return f
            }, [])
    }
}
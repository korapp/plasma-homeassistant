import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami

import "components"

Kirigami.FormLayout {
    property var item
    readonly property var source: item.entity_id && entities[item.entity_id] || {}

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

    Row {
        Kirigami.FormData.label: i18n("Display attribute") 
        CheckBox {
            id: useAttribute
            anchors.verticalCenter: parent.verticalCenter
            checked: !!item.attribute
        }
        ComboBox {
            displayText: currentText || item.attribute
            model: source.attributes ? Object.keys(source.attributes) : []
            onActivated: index => item.attribute = model[index]
            onModelChanged: currentIndex = item.attribute ? model.indexOf(item.attribute) : -1
            enabled: useAttribute.checked
            onEnabledChanged: activated(enabled ? currentIndex : -1)
            Kirigami.FormData.label: i18n("Display attribute")
        }
    }

    Row {
        Kirigami.FormData.label: i18n("Action")
        visible: !!actionSelector.count
        CheckBox {
            id: useAction
            anchors.verticalCenter: parent.verticalCenter
        }
        ComboBox {
            id: actionSelector
            model: item.domain && services[item.domain] ? Object.keys(services[item.domain]) : []
            onActivated: index => item.default_action = { service: model[index] }
            enabled: useAction.checked
            onModelChanged: {
                currentIndex = item.default_action && model ? model.indexOf(item.default_action.service) : -1
                useAction.checked = ~currentIndex
            }
            onEnabledChanged: activated(enabled ? currentIndex : -1)
        }
    }

    TextField {
        text: item.name || ''
        placeholderText: source.attributes?.friendly_name || ''
        onTextChanged: item.name = text
        Kirigami.FormData.label: i18n("Name")
    }

    Row {
        Kirigami.FormData.label: i18n("Icon")
        spacing: Kirigami.Units.smallSpacing
        TextField {
            id: iconName
            text: item.icon || ''
            placeholderText: source.attributes?.icon || 'mdi: | plasma:'
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
}
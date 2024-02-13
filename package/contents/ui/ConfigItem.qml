import QtQuick 2.0
import QtQuick.Controls 2.0

import org.kde.kirigami 2.4 as Kirigami

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

    ComboBox {
        visible: !!count
        model: item.domain && services[item.domain] ? Object.keys(services[item.domain]) : []
        onActivated: item.default_action = { service: model[index] }
        enabled: Kirigami.FormData.checked
        onModelChanged: {
            currentIndex = item.default_action && model ? model.indexOf(item.default_action.service) : -1
            Kirigami.FormData.checked = ~currentIndex
        }
        onEnabledChanged: activated(enabled ? currentIndex : -1)
        Kirigami.FormData.label: i18n("Action")
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
}
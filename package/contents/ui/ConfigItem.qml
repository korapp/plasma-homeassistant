import QtQuick 2.0
import QtQuick.Controls 2.0

import org.kde.kirigami 2.4 as Kirigami

Kirigami.FormLayout {
    property var item
    property var source: ({})

    ComboBox {
        id: itemStateSelector
        model: Object.keys(entities).sort()
        editable: true
        currentIndex: indexOfValue(item.entity_id)
        Kirigami.FormData.label: i18n("Entity")
        Component.onCompleted: currentIndex = indexOfValue(item.entity_id)
        
        onCurrentTextChanged: {
            source = entities[currentText]
            item.entity_id = source.entity_id
            attributeSelector.model = Object.keys(source.attributes) || []
            const availableServices = services[item.domain]
            if (availableServices) {
                serviceSelector.model = Object.keys(availableServices) || []
            }
        }
    }

    ComboBox {
        id: attributeSelector
        onActivated: item.attribute = currentValue
        onModelChanged: currentIndex = indexOfValue(item.attribute)
        enabled: Kirigami.FormData.checked
        onEnabledChanged: !enabled && (delete item.attribute)
        Kirigami.FormData.checked: !!item.attribute
        Kirigami.FormData.label: i18n("Display attribute")
        Kirigami.FormData.checkable: true
    }

    ComboBox {
        readonly property bool hasDefaultAction: !!item.default_action
        id: serviceSelector
        visible: !!count
        onActivated: item.default_action = { service: currentValue }
        onModelChanged: {
            currentIndex = hasDefaultAction ? indexOfValue(item.default_action.service) : -1
        }
        enabled: Kirigami.FormData.checked
        onEnabledChanged: !enabled && hasDefaultAction && (delete item.default_action.service)
        Kirigami.FormData.label: i18n("Action")
        Kirigami.FormData.checked: !!hasDefaultAction
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
}
import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami

import "components"
import "../code/formatter.mjs" as Formatter
import "../code/attributesBlacklist.mjs" as Ab
import "../code/serviceOverrides.mjs" as So

Kirigami.FormLayout {
    property var item
    readonly property var source: item.entity_id && entities[item.entity_id] || {}
    readonly property var itemServices: item.domain && services[item.domain] || {}

    TextField {
        Kirigami.FormData.label: i18nc("@label:textbox", "Entity")
        text: item.entity_id
        onEditingFinished: {
            item.entity_id = text
            itemChanged()
        }
        Autocompletion {
            model: Object.keys(entities).sort()
        }
    }

    ComboBox {
        readonly property int steps: 7
        Kirigami.FormData.label: i18nc("@label:listbox number format", "Precision")
        visible: !isNaN(+source.state) && !attributeSelector.enabled
        model: [{
            text: i18nc("@item:inlistbox number format", "%1 (raw)", source.state),
            value: undefined
        }, ...Array.from({ length: steps }, (_, i) => ({
            text: Formatter.formatIfNumber(source.state, i),
            value: i
        }))]
        textRole: "text"
        valueRole: "value"
        onActivated: item.value_number_precision = currentValue
        Component.onCompleted: {
            currentIndex = indexOfValue(item.value_number_precision)
            parent.onSourceChanged.connect(() => visible && (currentIndex = indexOfValue(Formatter.getDefaultPrecision(source.state))))
        }
    }

    CheckableFormControl {
        Kirigami.FormData.label: i18nc("@label", "Display attribute")
        visible: attributeSelector.model?.length > 0
        checked: ~attributeSelector.currentIndex
        ComboBox {
            id: attributeSelector
            model: source.attributes ? Ab.filter(Object.keys(source.attributes)).sort() : []
            onActivated: index => item.attribute = model[index]
            onModelChanged: currentIndex = item.attribute ? model.indexOf(item.attribute) : -1
            onEnabledChanged: !enabled && activated(-1)
        }
    }

    TextField {
        text: item.name || ''
        placeholderText: source.attributes?.friendly_name || ''
        onTextChanged: item.name = text
        Kirigami.FormData.label: i18nc("@label:textbox", "Name")
    }

    Row {
        Kirigami.FormData.label: i18nc("@label:textbox", "Icon")
        spacing: Kirigami.Units.smallSpacing
        TextField {
            id: iconName
            text: item.icon || ''
            placeholderText: source.attributes?.icon || 'mdi: | plasma:'
            onTextChanged: item.icon = text
        }
        DynamicIcon {
            name: iconName.text || iconName.placeholderText
            height: iconName.height
            width: height
        }
    }

    CheckBox {
        Kirigami.FormData.label: i18nc("@label", "Notify about changes")
        checked: !!item.notify
        onCheckedChanged: item.notify = checked
    }

    component ServiceSelector: CheckableFormControl {
        visible: !!serviceSelector.count
        checked: ~serviceSelector.currentIndex
        property alias currentValue: serviceSelector.currentValue
        property var initialValue
        property var serviceFilter
        default property alias content: nested.data
        ComboBox {
            id: serviceSelector
            model: serviceFilter ? Object.keys(itemServices).filter(serviceFilter) : Object.keys(itemServices)
            onModelChanged: currentIndex = initialValue ? model.indexOf(initialValue) : -1
            onEnabledChanged: if (!enabled) currentIndex = -1
        }
        Row {
            enabled: serviceSelector.enabled
            id: nested
        }
    }

    function assignAction(action, part) {
        item[action] = Object.assign({}, item[action], part)
    }

    ServiceSelector {
        Kirigami.FormData.label: i18nc("@label", "Click action")
        initialValue: item.default_action?.service
        onCurrentValueChanged: assignAction('default_action', { service: currentValue })
    }

    ServiceSelector {
        id: scrollActionSelector
        Kirigami.FormData.label: i18nc("@label", "Scroll action")
        serviceFilter: k => getNumberFields(itemServices[k]).length
        initialValue: item.scroll_action?.service
        onCurrentValueChanged: assignAction('scroll_action', { service: currentValue })
        readonly property var serviceOverrides: So.getFieldsForService(item.domain, currentValue)

        ComboBox {
            model: scrollActionSelector.getNumberFields(itemServices[scrollActionSelector.currentValue])
            onCurrentValueChanged: assignAction('scroll_action', { data_field: currentValue })
            onCountChanged: count && (currentValue = item.scroll_action?.data_field || model[0])
        }

        function getNumberFields({ fields = {} } = {}) {
            return Object.keys(fields).reduce((f, id) => {
                const field = fields[id]
                if (field.fields) f.push(...getNumberFields(field))
                if (field.selector?.number && hasAttributeForServiceField(id)) f.push(id)
                return f
            }, [])
        }

        function hasAttributeForServiceField(fieldName) {
            return serviceOverrides[fieldName]?.attribute in source.attributes || fieldName in source.attributes
        }
    }
}
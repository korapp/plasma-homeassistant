import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami

import "components"
import "../code/formatter.mjs" as Formatter
import "../code/attributesBlacklist.mjs" as Ab

Kirigami.FormLayout {
    property var item
    readonly property var source: item.entity_id && entities[item.entity_id] || {}
    readonly property list<string> itemServiceNames: services.getNames(item.domain)

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

    RestorableComboBox {
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
        initialValue: item.value_number_precision
        Component.onCompleted: parent.onSourceChanged.connect(() => visible && selectByValue(Formatter.getDefaultPrecision(source.state)))
    }

    CheckableFormControl {
        Kirigami.FormData.label: i18nc("@label", "Display attribute")
        visible: attributeSelector.model?.length > 0
        checked: ~attributeSelector.currentIndex
        RestorableComboBox {
            id: attributeSelector
            model: source.attributes ? Ab.filter(Object.keys(source.attributes)).sort() : []
            onActivated: index => item.attribute = model[index]
            initialValue: item.attribute
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
        property alias service: serviceSelector.currentValue
        property alias initialValue: serviceSelector.initialValue
        property var serviceFilter
        RestorableComboBox {
            id: serviceSelector
            model: serviceFilter ? itemServiceNames.filter(serviceFilter) : itemServiceNames
            onEnabledChanged: if (!enabled) currentIndex = -1
        }
    }

    function assignAction(action, part) {
        item[action] = Object.assign({}, item[action], part)
    }

    ServiceSelector {
        Kirigami.FormData.label: i18nc("@label", "Click action")
        initialValue: item.default_action?.service
        onServiceChanged: assignAction('default_action', { service })
    }

    ServiceSelector {
        Kirigami.FormData.label: i18nc("@label", "Double click action")
        initialValue: item.dclick_action?.service
        onServiceChanged: assignAction('dclick_action', { service })
    }

    ServiceSelector {
        id: scrollActionSelector
        Kirigami.FormData.label: i18nc("@label", "Scroll action")
        serviceFilter: k => getNumberFields(k).length
        initialValue: item.scroll_action?.service
        onServiceChanged: assignAction('scroll_action', { service })

        RestorableComboBox {
            model: getNumberFields(scrollActionSelector.service).map(e => e.name)
            onCurrentValueChanged: assignAction('scroll_action', { data_field: currentValue })
            initialValue: item.scroll_action?.data_field
            fallbackIndex: 0
        }
    }

    function getNumberFields(serviceName) {
        if (!serviceName) return []
        return services.getService(item.domain, serviceName)
            .filterFields(f => f.isNumber() && f.isApplicableTo(source) && f.hasCorrespondingAttribute(source), true)
    }
}
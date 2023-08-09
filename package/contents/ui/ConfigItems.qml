import QtQuick 2.4
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.4 as Kirigami

import "../code/model.mjs" as Model
import "."

Kirigami.FormLayout {
    anchors.fill: parent
    property string cfg_items
    property var items: JSON.parse(cfg_items)
    property var services: ({})
    property var entities: ({})

    WsClient {
        id: ha
        baseUrl: plasmoid.configuration.url
        token: Secrets.token
        onReadyChanged: {
            ha.getStates().then(s => entities = arrayToObject(s, 'entity_id'))
            ha.getServices().then(s => services = s)
        }
    }

    Loader {
        id: loader
        active: !!Object.keys(entities).length
        sourceComponent: list
        anchors.fill: parent
    }

    Component {
        id: listItem
        RowLayout {
            width: parent.width
            DynamicIcon {
                name: modelData.icon || entities[modelData.entity_id].attributes.icon || ''
                Layout.preferredWidth: parent.height
            }
            Column {
                Label {
                    text: modelData.name || entities[modelData.entity_id].attributes.friendly_name
                }
                Label {
                    text: modelData.entity_id
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                }
                Layout.fillWidth: true
            }
            ToolButton {
                icon.name: 'arrow-up'
                enabled: index > 0
                onClicked: swapItems(index, index - 1)
            }
            ToolButton {
                icon.name: 'arrow-down'
                enabled: index < items.length - 1
                onClicked: swapItems(index, index + 1)
            }
            ToolButton {
                icon.name: 'edit-entry'
                onClicked: openDialog(new Model.ConfigEntity(modelData), index)
            }
            ToolButton {
                icon.name: 'delete'
                onClicked: removeItem(index)
            }
        }
    }

    Component {
        id: list
        ScrollView {
            ListView {
                id: itemList
                model: items
                currentIndex: -1
                delegate: listItem
                spacing: Kirigami.Units.smallSpacing
                footerPositioning: ListView.PullBackFooter
                footer: Button {
                    icon.name: 'list-add'
                    text: i18n("Add")
                    onClicked: openDialog(new Model.ConfigEntity())
                }
            }
        }
    }

    Component {
        id: dialogComponent
        Kirigami.OverlaySheet {
            id: dialog
            property int index
            property var item
            signal accepted(int index, var item)

            footer: DialogButtonBox {
                standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
                onRejected: dialog.close()
                onAccepted: dialog.accepted(index, item) || dialog.close()
            }

            contentItem: ConfigItem {
                item: dialog.item
            }
        }
    }

    function openDialog(data, index = -1) {
        const dialog = dialogComponent.createObject(parent, { 
            index: index,
            item: data,
            title: data.name || data.entity_id || i18n('New')
        })
        dialog.open()
        dialog.onAccepted.connect((index, item) => {
            if (~index) {
                return updateItem(item, index)
            }
            return addItem(item)
        })
    }

    function save() {
        cfg_items = JSON.stringify(items, (key, value) => value || undefined)
    }

    function swapItems(index1, index2) {
        if (index1 < 0 || index2 < 0 || index1 > items.length || index2 > items.length) {
            return
        }
        [items[index2], items[index1]] = [items[index1], items[index2]]
        save()
    }

    function removeItem(index) {
        if (index >= items.length || index < 0) return
        items.splice(index, 1)
        save()
    }

    function addItem(item) {
        items.push(item)
        save()
    }

    function updateItem(item, index) {
        if (index >= items.length || index < 0) return
        items[index] = item
        save()
    }

    function arrayToObject(array, key) {
        return array.reduce((o, e) => (o[e[key]] = e,o), {})
    }
}
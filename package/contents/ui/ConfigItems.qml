import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.4 as Kirigami

import "../code/model.mjs" as Model
import "."

ColumnLayout {
    property string cfg_items
    property var items: JSON.parse(cfg_items)
    property var services: ({})
    property var entities: ({})
    property bool busy: true
    property Client ha

    Component.onCompleted: {
        ha = ClientFactory.getClient(this, plasmoid.configuration.url)
        ha.ready.connect(fetchData)
    }

    function fetchData() {
        return Promise.all([ha.getStates(), ha.getServices()])
            .then(([e, s]) => {
                entities = arrayToObject(e, 'entity_id')
                services = s
                busy = false
            }).catch(() => busy = false)
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        text: ha && ha.errorString
        visible: !!text
        type: Kirigami.MessageType.Error
    }

    ScrollView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        contentHeight: itemList.implicitHeight
        
        ListView {
            id: itemList
            model: Object.keys(entities).length ? items : []
            delegate: listItem
            spacing: Kirigami.Units.mediumSpacing

            BusyIndicator {
                anchors.centerIn: parent
                visible: busy
            }
        }
    }

    Button {
        icon.name: 'list-add'
        text: i18n("Add")
        enabled: !busy
        onClicked: openDialog(new Model.ConfigEntity())
        Layout.fillWidth: true
    }

    Component {
        id: listItem
        RowLayout {
            width: ListView.view.width
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
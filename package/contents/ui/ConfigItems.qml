import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import "../code/model.mjs" as Model
import "."

ColumnLayout {
    property string cfg_items
    property ListModel items: ListModel { dynamicRoles: true }
    property var services: ({})
    property var entities: ({})
    property bool busy: true
    property Client ha

    Component.onCompleted: {
        items.append(JSON.parse(cfg_items))
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
        text: ha?.errorString
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
            delegate: EntityListItem {}
            moveDisplaced: Transition {
                NumberAnimation { properties: "y"; duration: Kirigami.Units.longDuration }
            }

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

    component EntityListItem: Item { // Wrapper for ListItemDragHandle
        width: ListView.view.width
        implicitHeight: listItem.height
        ItemDelegate {
            id: listItem
            down: false
            width: parent.width
            readonly property var entity: entities[model.entity_id]
            contentItem: RowLayout {
                Kirigami.ListItemDragHandle {
                    listItem: listItem
                    listView: itemList
                    onMoveRequested: (oldIndex, newIndex) => items.move(oldIndex, newIndex, 1)
                    onDropped: save()
                }
                DynamicIcon {
                    name: model.icon || listItem.entity?.attributes.icon || ''
                    Layout.preferredWidth: parent.height
                    Layout.preferredHeight: parent.height
                }
                Kirigami.TitleSubtitle {
                    title: model.name || listItem.entity?.attributes.friendly_name || 'Unknown'
                    subtitle: model.entity_id
                    Layout.fillWidth: true
                }
                ToolButton {
                    icon.name: 'edit-entry'
                    onClicked: openDialog(new Model.ConfigEntity(model), index)
                }
                ToolButton {
                    icon.name: 'delete'
                    onClicked: removeItem(index)
                }
            }
        }
    }

    Component {
        id: dialogComponent
        Kirigami.Dialog {
            id: dialog
            property int index
            property var item
            signal itemAccepted(int index, var item)
            readonly property bool acceptable: !!itemForm.item?.entity_id
            padding: Kirigami.Units.largeSpacing
            standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
            onRejected: close()
            onAccepted: itemAccepted(index, item) || close()
            Component.onCompleted: standardButton(Kirigami.Dialog.Ok).enabled = Qt.binding(() => acceptable)

            ConfigItem {
                id: itemForm
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
        dialog.onItemAccepted.connect((index, item) => {
            if (~index) {
                return updateItem(item.toJSON(), index)
            }
            return addItem(item.toJSON())
        })
    }

    function save() {
        const array = []
        for (let i = 0; i < items.count; i++) {
            array.push(items.get(i))
        }
        cfg_items = JSON.stringify(array, (key, value) => value || undefined)
    }

    function removeItem(index) {
        if (index >= items.length || index < 0) return
        items.remove(index)
        save()
    }

    function addItem(item) {
        items.append(item)
        save()
    }

    function updateItem(item, index) {
        if (index >= items.length || index < 0) return
        items.set(index, item)
        save()
    }

    function arrayToObject(array, key) {
        return array.reduce((o, e) => (o[e[key]] = e,o), {})
    }
}
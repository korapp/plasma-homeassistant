import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.5 as Kirigami

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
            delegate: Kirigami.DelegateRecycler {
                width: itemList.width
                sourceComponent: listItemComponent
            }
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

    Component {
        id: listItemComponent
        Kirigami.SwipeListItem {
            id: listItem
            readonly property var entity: entities[model.entity_id]
            RowLayout {
                Kirigami.ListItemDragHandle {
                    listItem: listItem
                    listView: itemList
                    onMoveRequested: items.move(oldIndex, newIndex, 1)
                    onDropped: save()
                }
                DynamicIcon {
                    name: model.icon || (entity && entity.attributes.icon) || ''
                    Layout.preferredWidth: parent.height
                    Layout.preferredHeight: parent.height
                }
                Column {
                    Label {
                        text: model.name || (entity && entity.attributes.friendly_name) || 'Unknown'
                    }
                    Label {
                        text: model.entity_id
                        font: Kirigami.Theme.smallFont
                        opacity: 0.6
                    }
                    Layout.fillWidth: true
                }
            }
            actions: [
                Kirigami.Action {
                    iconName: 'edit-entry'
                    onTriggered: openDialog(new Model.ConfigEntity(model), index)
                },
                Kirigami.Action {
                    icon.name: 'delete'
                    onTriggered: removeItem(index)
                }
            ]
        }
    }

    Component {
        id: dialogComponent
        Kirigami.OverlaySheet {
            id: dialog
            property int index
            property var item
            signal accepted(int index, var item)
            readonly property bool acceptable: !!contentItem.item.entity_id

            footer: DialogButtonBox {
                standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
                onRejected: dialog.close()
                onAccepted: dialog.accepted(index, item) || dialog.close()
                Component.onCompleted: standardButton(DialogButtonBox.Ok).enabled = Qt.binding(() => acceptable)
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
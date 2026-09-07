import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "../code/model.mjs" as Model
import "components"
import "."

KCM.ScrollViewKCM {
    property string cfg_items
    property alias cfg_autoBackupFile: autoBackupFileField.text
    property int cfg_itemDisplayDefault
    property ListModel items: ListModel { dynamicRoles: true }
    property var services: ({})
    property var entities: ({})
    property bool busy: true
    property Client ha

    header: ColumnLayout {
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            text: ha?.errorString
            visible: !!text
            type: Kirigami.MessageType.Error
        }

        RowLayout {
            Layout.maximumWidth: itemList.width - Kirigami.Units.largeSpacing * 2
            Label {
                text: i18n("Global display mode")
                Layout.fillWidth: true
            }
            ConfigItemActionBar {
                actions: [
                    Kirigami.Action {
                        text: i18n("Display in compact view")
                        icon.name: "window-minimize-pip"
                        checkable: true
                        checked: cfg_itemDisplayDefault & DisplayFilterModel.Compact
                        onTriggered: setDisplayDefaultAndItems(DisplayFilterModel.Compact, checked)
                    },
                    Kirigami.Action {
                        text: i18n("Display in full view")
                        icon.name: "window-restore-pip"
                        checkable: true
                        checked: cfg_itemDisplayDefault & DisplayFilterModel.Full
                        onTriggered: setDisplayDefaultAndItems(DisplayFilterModel.Full, checked)
                    }
                ]
            }
        }
    }

    function setDisplayDefaultAndItems(flag, set) {
        cfg_itemDisplayDefault ^= flag
        for (let i = 0; i < items.count; i++) {
            const display = items.get(i).display
            items.setProperty(i, "display", set ? (display | flag) : (display & ~flag))
        }
        save()
    }

    footer: ColumnLayout {
        RowLayout {
            enabled: !busy
            Button {
                icon.name: 'list-add'
                text: i18n("Add")
                onClicked: openDialog(new Model.ConfigEntity())
                Layout.fillWidth: true
            }
            Button {
                icon.name: 'application-menu'
                down: backupMenu.visible
                onClicked: backupMenu.visible = !backupMenu.visible
            }
        }
            
        ColumnLayout {
            id: backupMenu
            visible: false

            RowLayout {
                Button {
                    icon.name: 'document-import'
                    text: i18n("Import")
                    onClicked: file.open().then(data => {
                        setItems(data)
                        save()
                    })
                    Layout.fillWidth: true
                }
                Button {
                    icon.name: 'document-export'
                    text: i18n("Export")
                    onClicked: file.save(cfg_items)
                    enabled: !!items.count
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Label {
                    text: i18n("Auto backup")
                }
                Kirigami.ActionTextField {
                    id: autoBackupFileField
                    readOnly: true
                    onPressed: file.select().then(file => cfg_autoBackupFile = file)
                    Layout.fillWidth: true
                    rightActions: [
                        Kirigami.Action {
                            visible: !!cfg_autoBackupFile
                            icon.name: 'edit-clear'
                            onTriggered: cfg_autoBackupFile = null
                        }
                    ]
                }
            }

            File {
                id: file
                defaultSuffix: "hapi"
                nameFilters: ["Home Assistant Plasma Items (*.hapi)"]
            }
        }
    }

    view: ListView {
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

    Component.onCompleted: {
        setItems(cfg_items)
        ha = ClientFactory.getClient(this, plasmoid.configuration.url) ?? null
        if (ha) {
            ha.readyChanged.connect(fetchData)
            fetchData()
        } else {
            busy = false
        }
    }

    Component.onDestruction: ha?.readyChanged.disconnect(fetchData)

    function setItems(data) {
        const rawItems = JSON.parse(data) || []
        rawItems.forEach(item => items.append(new Model.ConfigEntity(item)))
    }

    function fetchData() {
        if (!ha?.ready) return
        return Promise.all([ha.getStates(), ha.getServices()])
            .then(([e, s]) => {
                entities = arrayToObject(e, 'entity_id')
                services = s
                busy = false
            }).catch(() => busy = false)
    }

    component EntityListItem: Item { // Wrapper for ListItemDragHandle
        width: ListView.view.width
        implicitHeight: listItem.height
        ItemDelegate {
            id: listItem
            down: false
            width: parent.width
            readonly property var entity: entities[model.entity_id]
            function toggleDisplay(flag) {
                updateItem({ display: model.display ^ flag }, index)
            }
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
                ConfigItemActionBar {
                    actions: [
                        Kirigami.Action {
                            icon.name: 'edit-entry'
                            onTriggered: openDialog(new Model.ConfigEntity(model), index)
                            text: i18n("Edit")
                            visible: listItem.hovered
                        },
                        Kirigami.Action {
                            icon.name: 'delete'
                            onTriggered: removeItem(index)
                            text: i18n("Delete")
                            visible: listItem.hovered
                        },
                        Kirigami.Action {
                            text: i18n("Display in compact view")
                            icon.name: "window-minimize-pip"
                            checkable: true
                            checked: model.display & DisplayFilterModel.Compact
                            onTriggered: listItem.toggleDisplay(DisplayFilterModel.Compact)
                        },
                        Kirigami.Action {
                            text: i18n("Display in full view")
                            icon.name: "window-restore-pip"
                            checkable: true
                            checked: model.display & DisplayFilterModel.Full
                            onTriggered: listItem.toggleDisplay(DisplayFilterModel.Full)
                        }
                    ]
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
                return updateItem(item, index)
            }
            return addItem(item)
        })
        dialog.closed.connect(dialog.destroy)
    }

    function save() {
        const array = []
        for (let i = 0; i < items.count; i++) {
            array.push(items.get(i))
        }
        cfg_items = JSON.stringify(array, (_, value) => value || (value === 0 ? 0 : undefined))
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

    function saveConfig() {
        if (cfg_autoBackupFile) {
            file.write(cfg_autoBackupFile, cfg_items)
        }
    }
}
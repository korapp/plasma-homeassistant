import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.7 as Kirigami

import "../code/model.mjs" as Model
import "components"
import "."

ColumnLayout {
    property string cfg_items
    property alias cfg_autoBackupFile: autoBackupFileField.text
    property int cfg_itemDisplayDefault
    property ListModel items: ListModel { dynamicRoles: true }
    property var services: ({})
    property var entities: ({})
    property bool busy: true
    property Client ha

    Component.onCompleted: {
        setItems(cfg_items)
        ha = ClientFactory.getClient(this, plasmoid.configuration.url)
        ha.readyChanged.connect(fetchData)
    }

    function setItems(data) {
        const rawItems = JSON.parse(data) || []
        rawItems.forEach(item => items.append(new Model.ConfigEntity(item)))
    }

    function fetchData() {
        if (!ha.ready) return
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

    RowLayout {
        Layout.maximumWidth: itemListScrollView.availableWidth - Kirigami.Units.largeSpacing
        Label {
            text: i18n("Global display mode")
            Layout.fillWidth: true
        }
        ConfigItemActionBar {
            Layout.alignment: Qt.AlignRight
            actions: [
                Kirigami.Action {
                    text: i18n("Display in compact view")
                    icon.name: "zoom-out-symbolic"
                    checkable: true
                    checked: cfg_itemDisplayDefault & DisplayFilterModel.Compact
                    onTriggered: setDisplayDefaultAndItems(DisplayFilterModel.Compact, checked)
                },
                Kirigami.Action {
                    text: i18n("Display in full view")
                    icon.name: "zoom-original-symbolic"
                    checkable: true
                    checked: cfg_itemDisplayDefault & DisplayFilterModel.Full
                    onTriggered: setDisplayDefaultAndItems(DisplayFilterModel.Full, checked)
                }
            ]
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    function setDisplayDefaultAndItems(flag, set) {
        cfg_itemDisplayDefault ^= flag
        for (let i = 0; i < items.count; i++) {
            const display = items.get(i).display
            items.setProperty(i, "display", set ? (display | flag) : (display & ~flag))
        }
        save()
    }

    ScrollView {
        id: itemListScrollView
        Layout.fillHeight: true
        Layout.fillWidth: true
        contentHeight: itemList.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

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
            nameFilters: ["Home Assistant Plasmoid Items (*.hapi)"]
        }
    }

    Component {
        id: listItemComponent
        Kirigami.AbstractListItem {
            id: listItem
            readonly property var entity: entities[model.entity_id]

            function toggleDisplay(flag) {
                updateItem({ display: model.display ^ flag }, index)
            }

            onClicked: openDialog(new Model.ConfigEntity(model), index)

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
                ConfigItemActionBar {
                    actions: [
                        Kirigami.Action {
                            icon.name: 'edit-entry'
                            onTriggered: openDialog(new Model.ConfigEntity(model), index)
                            text: i18n("Edit")
                            visible: containsMouse
                        },
                        Kirigami.Action {
                            icon.name: 'delete'
                            onTriggered: removeItem(index)
                            text: i18n("Delete")
                            visible: containsMouse
                        },
                        Kirigami.Action {
                            text: i18n("Display in compact view")
                            icon.name: "zoom-out-symbolic"
                            checkable: true
                            checked: model.display & DisplayFilterModel.Compact
                            onTriggered: toggleDisplay(DisplayFilterModel.Compact)
                        },
                        Kirigami.Action {
                            text: i18n("Display in full view")
                            icon.name: "zoom-original-symbolic"
                            checkable: true
                            checked: model.display & DisplayFilterModel.Full
                            onTriggered: toggleDisplay(DisplayFilterModel.Full)
                        }
                    ]
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
                return updateItem(item, index)
            }
            return addItem(item)
        })
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
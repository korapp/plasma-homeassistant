import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    id: config
    property bool cfg_firstStart
    property string cfg_url
    property alias cfg_compact: compact.checked
    property alias cfg_flat: flat.checked
    property alias cfg_fontSize: fontSize.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_widgetWidth: widgetWidth.value
    property alias cfg_widgetHeight: widgetHeight.value
    property alias cfg_cellWidth: cellWidth.value
    property alias cfg_cellHeight: cellHeight.value
    property alias cfg_gridHorizontalSpacing: gridHorizontalSpacing.value
    property alias cfg_gridVerticalSpacing: gridVerticalSpacing.value

    signal configurationChanged

    states: [
        State {
            name: "planar-defaults"
            when: config.cfg_firstStart && plasmoid.formFactor === PlasmaCore.Types.Planar
            PropertyChanges 
            {
                config.cfg_firstStart: false
                config.cfg_flat: false
                config.cfg_fontSize: 10
                config.cfg_iconSize: -1
                config.cfg_widgetWidth: -1
                config.cfg_widgetHeight: -1
                config.cfg_cellWidth: 200
                config.cfg_cellHeight: 60
                config.cfg_gridHorizontalSpacing: -1
                config.cfg_gridVerticalSpacing: -1
            }
        },
        State {
            name: "horizontal-defaults"
            when: config.cfg_firstStart && plasmoid.formFactor === PlasmaCore.Types.Horizontal
            PropertyChanges 
            {
                config.cfg_firstStart: false
                config.cfg_flat: true
                config.cfg_fontSize: 10
                config.cfg_iconSize: 20
                config.cfg_widgetWidth: -1
                config.cfg_widgetHeight: -1
                config.cfg_cellWidth: 86
                config.cfg_cellHeight: 36
                config.cfg_gridHorizontalSpacing: -1
                config.cfg_gridVerticalSpacing: 0
            }
        },
        State {
            name: "vertical-defaults"
            when: config.cfg_firstStart && plasmoid.formFactor === PlasmaCore.Types.Vertical
            PropertyChanges 
            {
                config.cfg_firstStart: false
                config.cfg_flat: true
                config.cfg_fontSize: 6
                config.cfg_iconSize: 20
                config.cfg_widgetWidth: -1
                config.cfg_widgetHeight: -1
                config.cfg_cellWidth: 1000 // just a very large value so that the cell content is not clipped
                config.cfg_cellHeight: 36
                config.cfg_gridHorizontalSpacing: -1
                config.cfg_gridVerticalSpacing: -1
            }
        }
    ]

    Kirigami.FormLayout {

        Secrets {
            id: secrets
            property string token
            onReady: {
                restore(cfg_url)
                list().then(urls => (url.model = urls))
            }
            
            function restore(entryKey) {
                if (!entryKey) {
                    return this.token = ""
                }
                get(entryKey)
                    .then(t => this.token = t)
                    .catch(() => this.token = "")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("API")
        }

        ComboBox {
            id: url
            editable: true
            onModelChanged: currentIndex = indexOfValue(cfg_url)
            onActiveFocusChanged: !activeFocus && setValue(editText)
            onHoveredChanged: !hovered && setValue(editText)
            onEditTextChanged: editText !== cfg_url && configurationChanged()
            onActivated: {
                secrets.restore(editText)
                setValue(editText)
            }
            Kirigami.FormData.label: i18n("Home Assistant URL")
            Layout.fillWidth: true

            function setValue(value) {
                cfg_url = editText = value ? value.replace(/\s+|\/+\s*$/g,'') : ''
            }
        }

        Label {
            text: i18n("Make sure the URL includes the protocol and port. For example:\nhttp://homeassistant.local:8123\nhttps://example.duckdns.org")
        }

        TextField {
            id: token
            text: secrets.token
            onTextChanged: text !== secrets.token && configurationChanged()
            Kirigami.FormData.label: i18n("Token")
        }

        Label {
            text: i18n("Get token from your profile page")
        }

        Label {
            text: `<a href="${url.editText}/profile/security">${url.editText}/profile/security</a>`
            onLinkActivated: link => Qt.openUrlExternally(link)
            visible: url.editText
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Look")
        }

        CheckBox {
            id: compact
            Kirigami.FormData.label: i18n("Compact representation (restart required)")
        }

        CheckBox {
            id: flat
            Kirigami.FormData.label: i18n("Flat entities")
        }

        SpinBox {
            id: fontSize
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Font size (pts)")
            from: 0
            to: 9999
        }

        SpinBox {
            id: iconSize
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Icon size (-1 = default size)")
            from: -1
            to: 9999
        }

        SpinBox {
            id: widgetWidth
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Widget width (-1 = default width)")
            from: -1
            to: 9999
            visible: plasmoid.formFactor === PlasmaCore.Types.Horizontal
        }

        SpinBox {
            id: widgetHeight
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Widget height (-1 = default height)")
            from: -1
            to: 9999
            visible: plasmoid.formFactor === PlasmaCore.Types.Vertical
        }

        SpinBox {
            id: cellWidth
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Cell width")
            from: 0
            to: 9999
        }

        SpinBox {
            id: cellHeight
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Cell height")
            from: 0
            to: 9999
        }

        SpinBox {
            id: gridHorizontalSpacing
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Horizontal spacing (-1 = default spacing)")
            from: -1
            to: 9999
        }

        SpinBox {
            id: gridVerticalSpacing
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Vertical spacing (-1 = default spacing)")
            from: -1
            to: 9999
        }
    }
    
    function saveConfig() {
        secrets.set(url.editText, token.text)
    }
}
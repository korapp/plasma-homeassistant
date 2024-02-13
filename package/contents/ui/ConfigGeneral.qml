import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.4 as Kirigami

Kirigami.FormLayout {
    property string cfg_url
    property alias cfg_flat: flat.checked

    signal configurationChanged

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
        text: `<a href="${url.editText}/profile">${url.editText}/profile</a>`
        onLinkActivated: Qt.openUrlExternally(link)
        visible: url.editText
    }

    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Look")
    }

    CheckBox {
        id: flat
        Kirigami.FormData.label: i18n("Flat entities")
    }

    function saveConfig() {
        secrets.set(url.editText, token.text)
    }
}
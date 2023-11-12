import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.4 as Kirigami
import "."

Kirigami.FormLayout {
    property alias cfg_url: url.text
    property alias cfg_flat: flat.checked

    signal configurationChanged

    Secrets {
        id: secrets
        property string token
        onReady: restore(cfg_url)
        
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

    TextField {
        id: url
        onEditingFinished: secrets.restore(text)
        placeholderText: "http://homeassistant.local:8123"
        Kirigami.FormData.label: i18n("Home Assistant URL")
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
        text: `<a href="${url.text}/profile">${url.text}/profile</a>`
        onLinkActivated: Qt.openUrlExternally(link)
        visible: url.text
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
        secrets.set(url.text, token.text)
    }
}
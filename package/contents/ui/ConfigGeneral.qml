import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import org.kde.kirigami 2.4 as Kirigami
import "."

Kirigami.FormLayout {
    property alias cfg_url: url.text
    property alias cfg_flat: flat.checked

    signal configurationChanged

    onCfg_urlChanged: Secrets.entryKey = cfg_url

    Item {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("API")
    }

    TextField {
        id: url
        onEditingFinished: Secrets.entryKey = url.text
        Kirigami.FormData.label: i18n("Home Assistant URL")
    }

    Kirigami.InlineMessage {
        text: `<a href="${url.text}/profile">${i18n("Get token from your HA profile page")}</a>`
        onLinkActivated: Qt.openUrlExternally(link)
        visible: !token.text && url.text
        Layout.fillWidth: true
    }

    TextField {
        id: token
        text: Secrets.token
        onTextChanged: text !== Secrets.token && configurationChanged()
        Kirigami.FormData.label: i18n("Token")
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
        Secrets.token = token.text
    }
}
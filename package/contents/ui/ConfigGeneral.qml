import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property string cfg_url

    signal configurationChanged

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
            onAccepted: setValue(editText)
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
            onTextEdited: configurationChanged()
            Kirigami.FormData.label: i18n("Token")
        }

        Label {
            text: i18n("Get token from your profile page")
        }

        Kirigami.UrlButton {
            url: url.editText + "/profile/security"
            visible: url.editText
        }
    }
    
    function saveConfig() {
        secrets.set(url.editText, token.text)
    }
}
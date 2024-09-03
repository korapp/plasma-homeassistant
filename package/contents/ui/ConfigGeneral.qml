import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "components"

KCM.SimpleKCM {
    property string cfg_url
    property alias cfg_scrollStep: scrollStepSlider.value
    signal configurationChanged

    onCfg_urlChanged: secrets.restore(cfg_url)

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
            Kirigami.FormData.label: i18nc("@title:group", "API")
        }

        ComboBox {
            id: url
            editable: true
            onModelChanged: currentIndex = indexOfValue(cfg_url)
            onActiveFocusChanged: !activeFocus && accepted()
            onActivated: cfg_url = editText = currentValue
            onAccepted: cfg_url = editText
            validator: RegularExpressionValidator {
                regularExpression: /^https?:\/\/\w+[\w.-]+\w+(?::\d{2,5})?$/
            }
            Kirigami.FormData.label: i18nc("@label:listbox", "Home Assistant URL")
            Layout.fillWidth: true
        }

        Label {
            text: i18nc("@info", "Make sure the URL includes the protocol and port. For example: %1", "\nhttp://homeassistant.local:8123\nhttps://example.duckdns.org")
        }

        TextField {
            id: token
            text: secrets.token
            onTextEdited: configurationChanged()
            validator: RegularExpressionValidator {
                regularExpression: /^[\w-]+\.[\w-]+\.[\w-]+$/
            }
            Kirigami.FormData.label: i18nc("@label:textbox", "Token")
        }

        Label {
            text: i18nc("@info", "Get token from your profile page")
        }

        Kirigami.UrlButton {
            url: cfg_url + "/profile/security"
            visible: cfg_url
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Behavior")
        }

        SliderBox {
            id: scrollStepSlider
            from: 0.01
            to: 0.15
            stepSize: 0.01
            textFromValue: v => i18ncp("@label", "%1 %pt", "%1 %pts", v)
            Kirigami.FormData.label: i18nc("@label", "Scroll step")
            Layout.fillWidth: true
        }
    }

    function saveConfig() {
        if (!token.acceptableInput) return
        secrets.set(cfg_url, token.text)
    }
}
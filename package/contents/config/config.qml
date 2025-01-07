import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Items")
        icon: "view-list-symbolic"
        source: "ConfigItems.qml"
    }
    ConfigCategory {
        name: i18n("Look")
        icon: "preferences-desktop-theme"
        source: "ConfigLook.qml"
    }
}
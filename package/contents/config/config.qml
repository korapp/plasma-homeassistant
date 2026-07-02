import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nc("@title:tab", "General")
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18nc("@title:tab", "Items")
        icon: "view-list-details"
        source: "ConfigItems.qml"
    }
    ConfigCategory {
        name: i18nc("@title:tab", "Look")
        icon: "preferences-desktop-theme"
        source: "ConfigLook.qml"
    }
}
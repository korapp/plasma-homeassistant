import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_flat: flat.checked
    property alias cfg_compactScaleIconsToFit: compactScaleIconsToFit.checked
    property string cfg_compactEntity
    property int cfg_compactIconSpacing

    signal configurationChanged
    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Compact")
        }

        CheckBox {
            id: compactScaleIconsToFit
            Kirigami.FormData.label: i18nc("@label", "Scale icons to fit")
        }

        ComboBox {
            model: [
                {value: "icon", label: i18nc("@item:inlistbox", "Icon")},
                {value: "icon-and-text", label: i18nc("@item:inlistbox", "Icon and text")}
            ]
            textRole: "label"
            valueRole: "value"
            Kirigami.FormData.label: i18nc("@label:listbox", "Entity widget")
            Component.onCompleted: (currentIndex = indexOfValue(cfg_compactEntity))
            onActivated: (cfg_compactEntity = currentValue)
        }

        ComboBox {
            id: compactIconSpacing
            model: [
                { value: 1, name: i18ndc("plasma_applet_org.kde.plasma.systemtray", "@item:inlistbox Icon spacing", "Small") },
                { value: 2, name: i18ndc("plasma_applet_org.kde.plasma.systemtray", "@item:inlistbox Icon spacing", "Normal") },
                { value: 6, name: i18ndc("plasma_applet_org.kde.plasma.systemtray", "@item:inlistbox Icon spacing", "Large") }
            ]
            textRole: "name"
            valueRole: "value"
            Kirigami.FormData.label: i18ndc("plasma_applet_org.kde.plasma.systemtray", "@label:listbox The spacing between system tray icons in the Panel", "Spacing:")
            Component.onCompleted: (currentIndex = indexOfValue(cfg_compactIconSpacing))
            onActivated: (cfg_compactIconSpacing = currentValue)
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Full")
        }

        CheckBox {
            id: flat
            Kirigami.FormData.label: i18nc("@label", "Flat entities")
        }
    }
}
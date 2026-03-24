import QtQuick 2.0

import org.kde.plasma.core 2.1 as PlasmaCore

PlasmaCore.SortFilterModel {
    enum Visibility {
        Full = 1,
        Compact = 2
    }
    property int filterItems: 0
    filterCallback: row => sourceModel.get(row).display & filterItems
}
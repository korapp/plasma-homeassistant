import QtQuick

import org.kde.kitemmodels

KSortFilterProxyModel {
    enum Visibility {
        Full = 1,
        Compact = 2
    }
    property int filterItems: 0
    filterRowCallback: row => sourceModel.get(row).display & filterItems
}
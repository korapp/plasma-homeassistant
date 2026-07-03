import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "."

GridLayout {
    id: grid
    readonly property bool trayMode: compactItems.count > 0
    readonly property bool vertical: plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int smallIconSize: Kirigami.Units.iconSizes.smallMedium
    readonly property bool autoSize: plasmoid.configuration.compactScaleIconsToFit
    readonly property int gridThickness: vertical ? width : height
    readonly property int rowsOrColumns: autoSize ? 1 : Math.max(1, Math.min(compactItems.count, Math.floor(gridThickness / (smallIconSize + cellSpacing))))
    readonly property int cellSpacing: plasmoid.configuration.compactIconSpacing
    readonly property int itemSize: {
        if (!autoSize) return smallIconSize
        return Kirigami.Units.iconSizes.roundedIconSize(Math.min(Math.min(width, height) / rowsOrColumns, Kirigami.Units.iconSizes.enormous))
    }
    readonly property string compactEntity: `compact-entities/${plasmoid.configuration.compactEntity}/Entity.qml`
    
    rowSpacing: cellSpacing
    columnSpacing: cellSpacing
    flow: vertical ? Flow.LeftToRight : Flow.TopToBottom
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    Binding {
        target: grid
        property: vertical ? "columns" : "rows"
        value: vertical && repeater.maxItemWidth > itemSize ? 1 : rowsOrColumns
    }

    Repeater {
        id: repeater
        property int maxItemWidth

        model: DisplayFilterModel {
            id: compactItems
            sourceModel: store.itemModel
            filterItems: DisplayFilterModel.Compact
        }

        delegate: EntityWrapper {
            readonly property var alignment: grid.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
            tooltipTitle: model.name + ": " + model.value
            flat: true
            Layout.alignment: alignment
            Layout.minimumWidth: loader.implicitWidth
            Layout.minimumHeight: loader.implicitHeight
            
            Loader {
                id: loader
                active: true
                source: compactEntity
                
                onItemChanged: {
                    if (!item) return
                    repeater.maxItemWidth = index ? Math.max(repeater.maxItemWidth, item.implicitWidth) : item.implicitWidth
                }
            }
        }
    }
    
    ExpandButton {
        onClicked: root.expanded = !root.expanded
        visible: store.hasFullRepresenationItems || !trayMode
        Layout.preferredHeight: grid.itemSize
        Layout.preferredWidth: grid.itemSize
        Layout.rowSpan: grid.vertical ? 1 : grid.rows
        Layout.columnSpan: grid.vertical ? grid.columns : 1
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    }
}

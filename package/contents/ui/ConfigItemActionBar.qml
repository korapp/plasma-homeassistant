import QtQuick 2.0
import QtQuick.Controls 2.5
import org.kde.kirigami 2.7 as Kirigami

Row {
    property list<Action> actions

    Repeater {
        model: actions
        delegate: ToolButton {
            action: actions[index]
            display: AbstractButton.IconOnly
            visible: action.visible
            ToolTip.visible: (Kirigami.Settings.tabletMode ? pressed : hovered) && ToolTip.text
            ToolTip.text: text
        }
    }
}
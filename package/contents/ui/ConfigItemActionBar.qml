import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

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
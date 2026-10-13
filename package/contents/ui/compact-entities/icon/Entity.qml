import QtQuick

import "../../"

DynamicIcon {
    name: model.icon
    height: grid.itemSize
    width: grid.itemSize
    opacity: model.default_action && !model.active ? 0.6 : 1
}
import QtQuick 2.0
import QtQuick.Layouts 1.0

import "../../"

DynamicIcon {
    name: model.icon
    height: grid.itemSize
    width: grid.itemSize
    opacity: model.default_action.service && !model.active ? 0.6 : 1
}
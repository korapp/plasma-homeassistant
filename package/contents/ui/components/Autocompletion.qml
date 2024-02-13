import QtQuick 2.7
import QtQuick.Controls 2.5

Popup {
    property TextField target: parent
    property var model
    
    function getModel() {
        return model.filter(i => textMaches(i, target.text))
    }

    function textMaches(text, search) {
        return !!text && text.toLowerCase().includes(search.toLowerCase())
    }

    function accept(index) {
        if (~index) target.text = list.model[index]
        close()
    }

    onTargetChanged: {
        if (!target) return
        target.pressed.connect(open)
        target.accepted.connect(() => accept(list.currentIndex))
        target.Keys.onUpPressed.connect(list.decrementCurrentIndex)
        target.Keys.onDownPressed.connect(list.incrementCurrentIndex)
        target.Keys.onTabPressed.connect(() => list.count && (target.text = list.model[list.currentIndex || 0]))
    }

    y: target.height
    width: target.width
    padding: 1
    height: Math.min(contentItem.contentHeight + verticalPadding * 2, target.parent.height - y - target.y) 
    onClosed: target.focus = false

    contentItem: ScrollView {
        ListView {
            id: list
            model: visible ? getModel() : null
            highlightMoveDuration: 0
            delegate: ItemDelegate {
                width: ListView.view.width
                text: modelData
                highlighted: ListView.isCurrentItem
                onClicked: accept(index)
            }
        }
    }
}
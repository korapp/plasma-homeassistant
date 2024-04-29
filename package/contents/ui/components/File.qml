import QtQuick 2.0
import QtQuick.Dialogs 1.0

import org.kde.plasma.core 2.0 as PlasmaCore

BaseObject {
    property alias defaultSuffix: fileDialog.defaultSuffix
    property alias nameFilters: fileDialog.nameFilters
    property var write: file.write
    property var read: file.read

    PlasmaCore.DataSource {
        id: file
        engine: "executable"
        readonly property string cmdSave: "echo"
        readonly property string cmdRead: "cat"
        property var promises: new Map()
        onNewData: {
            const p = promises.get(sourceName)
            if (p) {
                if (!data["exit code"]) {
                    p.resolve(data.stdout)
                } else {
                    p.reject(data.stderr)
                }
                promises.delete(sourceName)
            }
            disconnectSource(sourceName)
        }

        function read(url) {
            return new Promise((resolve, reject) => {
                const source = `${cmdRead} ${url}`
                connectSource(source)
                promises.set(source, { resolve, reject })
            })
        }

        function write(url, content) {
            connectSource(`${cmdSave} '${content}' > ${url}`)
        }
    }

    function save(content) {
        return select().then(url => file.write(url, content))
    }

    function open() {
        return select(true).then(file.read)
    }

    function select(existing = false) {
        fileDialog.selectExisting = existing
        return new Promise((resolve, reject) => {
            fileDialog.open()
            fileDialog.accepted.connect(() => resolve(fixUrl(fileDialog.fileUrl)))
            fileDialog.rejected.connect(reject)
        })
    }

    function fixUrl(url) {
        return url.toString().replace("file://", "")
    }

    FileDialog {
        id: fileDialog
        folder: shortcuts.home
    }
}
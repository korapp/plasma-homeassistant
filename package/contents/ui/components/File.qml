import QtCore
import QtQuick
import QtQuick.Dialogs

import org.kde.plasma.plasma5support as P5Support

BaseObject {
    property alias defaultSuffix: fileDialog.defaultSuffix
    property alias nameFilters: fileDialog.nameFilters
    property var write: file.write
    property var read: file.read

    P5Support.DataSource {
        id: file
        engine: "executable"
        readonly property string cmdSave: "echo"
        readonly property string cmdRead: "cat"
        property var promises: new Map()
        onNewData: (sourceName, data) => {
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
        return select(FileDialog.SaveFile).then(url => file.write(url, content))
    }

    function open() {
        return select(FileDialog.OpenFile).then(file.read)
    }

    function select(fileMode = FileDialog.SaveFile) {
        fileDialog.fileMode = fileMode
        return new Promise((resolve, reject) => {
            fileDialog.open()
            fileDialog.accepted.connect(() => resolve(fixUrl(fileDialog.selectedFile)))
            fileDialog.rejected.connect(reject)
        })
    }

    function fixUrl(url) {
        return url.toString().replace("file://", "")
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    }
}
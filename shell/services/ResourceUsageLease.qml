pragma ComponentBehavior: Bound
import QtQuick

// Visibility-scoped subscription. Declared as an object property by consumers,
// so it also works inside components with a custom default content property.
QtObject {
    id: root
    property bool active: false
    property bool registered: false

    function sync() {
        if (active === registered) return
        registered = active
        if (registered) ResourceUsage.acquire()
        else ResourceUsage.release()
    }
    onActiveChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (registered) ResourceUsage.release()
}

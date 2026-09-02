pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Screensharing and mic activity.
 */
Singleton {
    id: root

    // .length > 0 matters here: assigning the filtered array itself to a
    // bool property is always truthy (even when empty), which made these
    // report "active" unconditionally.
    property bool screenSharing: Pipewire.linkGroups.values.filter(pwlg => pwlg.source.type === PwNodeType.VideoSource).map(pwlg => pwlg.target).length > 0
    property bool micActive: Pipewire.linkGroups.values.filter(pwlg => pwlg.source.type === PwNodeType.AudioSource && pwlg.target.type === PwNodeType.AudioInStream).map(pwlg => pwlg.target).length > 0
}

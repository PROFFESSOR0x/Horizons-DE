import QtQuick
import QtQuick.Layouts

RowLayout {
    // Uniform by default. 45 of the 51 ConfigRows across the settings pages
    // already opted in explicitly; the handful that didn't were oversights
    // (homogeneous ConfigSwitch/ConfigSpinBox pairs, nothing that wants
    // unequal columns), and they were the rows whose controls didn't line up
    // with the rows above and below them. Set `uniform: false` on a row that
    // genuinely needs its cells sized to their content.
    property bool uniform: true
    spacing: 4
    uniformCellSizes: uniform
}

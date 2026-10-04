import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// A zero-padded 8-bit value -- originally SiAmCIAPanel's own
// SiLabeledByteView. 'base' defaults to hex (16) and 'padded' to true, the
// common case for every Inspector panel; a panel whose fields follow the
// user's hex/decimal toggle (controller.inspectorController.hex) binds
// 'base'/'padded' per instance -- see SiLabeledBinaryView for the fixed-binary
// counterpart and SiLabeledWordView/SiLabeledWord24View/SiLabeledWord32View
// for the wider ones.
SiLabeledNumberView {

    size: Size.small
    font.weight: 500
    controlWidth: 32
    bits: 8
    base: 16
    padded: true
}

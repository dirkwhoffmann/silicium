import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// A zero-padded 16-bit value -- originally SiAmCIAPanel's own
// SiLabeledWordView. See SiLabeledByteView for the base/padded defaults and
// the toggle-following convention; SiLabeledWord24View/SiLabeledWord32View
// are the wider counterparts.
SiLabeledNumberView {

    size: Size.small
    font.weight: 500
    controlWidth: 48
    bits: 16
    base: 16
    padded: true
}

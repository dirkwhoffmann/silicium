import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// A zero-padded 16-bit value -- originally SiAmCIAPanel's own
// SuLabeledWordView. See SuLabeledByteView for the base/padded defaults and
// the toggle-following convention; SuLabeledWord24View/SuLabeledWord32View
// are the wider counterparts.
SuLabeledNumberView {

    size: Size.small
    font.weight: 500
    controlWidth: 48
    bits: 16
    base: 16
    padded: true
}

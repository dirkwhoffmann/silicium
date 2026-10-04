import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// An 8-bit value shown as its raw bit pattern -- fixed binary, zero-padded
// to 8 digits, regardless of whatever hex/decimal toggle the enclosing
// panel's other fields might follow (a bit-logic view like this one cares
// about the actual bit pattern, not the display base). Originally
// SiAmCIAPanel's own SuLabeledBitView -- see SuLabeledByteView/
// SuLabeledWordView/SuLabeledWord24View/SuLabeledWord32View for the
// decimal/hex-formatted counterparts.
SuLabeledNumberView {

    size: Size.small
    font.weight: 500
    controlWidth: 66
    bits: 8
    base: 2
    padded: true
}

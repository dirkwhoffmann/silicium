import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

// A single read-only status/flag bit -- a small bit-style checkbox, used
// throughout the Inspector panels for one bit of a register (e.g. a CIA
// port bit, a Paula interrupt bit, an audio DMA state flag). Originally
// repeated by hand as SiLabeledCheckBox { size: Size.small; bitStyle: true;
// readOnly: true } across SiAmCIAPanel/SiAmPaulaPanel/SiC64CIAPanel -- not
// to be confused with SiLabeledBinaryView, which shows a whole byte's worth
// of bits as one binary number, not a single flag.
SiLabeledCheckBox {

    size: Size.small
    bitStyle: true
    readOnly: true
}

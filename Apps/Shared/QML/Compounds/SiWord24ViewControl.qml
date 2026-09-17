import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

// A zero-padded 24-bit value -- the width DMA pointer/address registers and
// the CIA's TOD counters share. See SiByteViewControl for the base/padded
// defaults and the toggle-following convention.
SiNumberViewControl {

    size: Size.small
    font.weight: 500
    controlWidth: 68
    bits: 24
    base: 16
    padded: true
}

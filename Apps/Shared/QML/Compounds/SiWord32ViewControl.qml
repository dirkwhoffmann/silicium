import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

// A zero-padded 32-bit value -- the CPU panel's PC/D/A registers. See
// SiByteViewControl for the base/padded defaults and the toggle-following
// convention.
SiNumberViewControl {

    size: Size.small
    font.weight: 500
    controlWidth: 92
    bits: 32
    base: 16
    padded: true
}

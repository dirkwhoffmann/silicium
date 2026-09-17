import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

// A zero-padded 16-bit value -- originally SiAmCIAPanel's own
// SiWordViewControl. See SiByteViewControl for the base/padded defaults and
// the toggle-following convention; SiWord24ViewControl/SiWord32ViewControl
// are the wider counterparts.
SiNumberViewControl {

    size: Size.small
    font.weight: 500
    controlWidth: 48
    bits: 16
    base: 16
    padded: true
}

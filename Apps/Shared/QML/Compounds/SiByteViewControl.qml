import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

// A zero-padded 8-bit value -- originally SiAmCIAPanel's own
// SiByteViewControl. 'base' defaults to hex (16) and 'padded' to true, the
// common case for every Inspector panel; a panel whose fields follow the
// user's hex/decimal toggle (controller.inspectorController.hex) binds
// 'base'/'padded' per instance -- see SiBinaryViewControl for the fixed-binary
// counterpart and SiWordViewControl/SiWord24ViewControl/SiWord32ViewControl
// for the wider ones.
SiNumberViewControl {

    size: Size.small
    font.weight: 500
    controlWidth: 32
    bits: 8
    base: 16
    padded: true
}

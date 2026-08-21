import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Slider {

    id: control

    property bool unicolor: false

    // Optional gated model input. When assigned (i.e. not NaN) it drives the
    // slider's value -- except while the user is dragging -- so a rounded
    // write-back can't fight the drag, nor silently break a plain "value:"
    // binding (QQC2 Slider assigns value imperatively while dragging). Read
    // live changes via value / moved() as usual; leave unset for a plain
    // control.
    property real boundValue: NaN

    // Reference the Palette singleton rather than a sibling palette.* member
    // (e.g. palette.button): reading one grouped-palette member while writing
    // another makes highlight depend on the palette it's part of -- a binding
    // loop. Palette.backdrop matches the groove/track background elsewhere.
    palette.highlight: !enabled ? Palette.disabled : unicolor ? Palette.backdrop : Palette.accent

    Binding {
        target: control
        property: "value"
        value: control.boundValue
        when: !control.pressed && !isNaN(control.boundValue)
        restoreMode: Binding.RestoreNone
    }
}

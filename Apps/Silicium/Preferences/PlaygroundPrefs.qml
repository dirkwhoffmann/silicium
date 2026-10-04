// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers
import Sulfur

PrefPage {

    id: root
    readonly property int labelWidth: 100
    readonly property int comboWidth: 72

    //
    // Toolbar
    //

    // No burger menu: this page is a widget showcase and owns no preferences,
    // so there is nothing to restore.
    toolbar: PrefToolbar {

        backdrop: root.backgroundItem

        heading: "Playground"

        HSpacer { }
    }

    component HelpWrapper : ColumnLayout {

        spacing: 0
        width: parent.width
    }

    PrefGrid {

        id: grid
        columnWidth: width / 2

        //
        // Section 1
        //

        ConfigSection {

            header: "FIXED WIDTH"

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                r: "Ipsum"
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                r: "Ipsum"
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {}
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                r: "Ipsum"
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {}
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                r: "Ipsum"
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {}
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {
                    alignment: Qt.AlignLeft
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                r: "Ipsum"
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {
                    alignment: Qt.AlignLeft
                }
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                r: "Ipsum"
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {
                    alignment: Qt.AlignLeft
                }
            }
        }

        //
        // Section 2
        //

        ConfigSection {

            header: "FLEX WIDTH"

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                model: ["Item 1", "Item 2", "Item 3"]
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                r: "Ipsum"
                model: ["Item 1", "Item 2", "Item 3"]
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                r: "Ipsum"
                model: ["Item 1", "Item 2", "Item 3"]
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {}
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                r: "Ipsum"
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {}
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                r: "Ipsum"
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {}
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {
                    alignment: Qt.AlignLeft
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                r: "Ipsum"
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {
                    alignment: Qt.AlignLeft
                }
            }

            SiLabeledComboBox {
                l: "Lorem:"
                lwidth: root.labelWidth
                r: "Ipsum"
                model: ["Item 1", "Item 2", "Item 3"]

                SiHelpButton {
                    alignment: Qt.AlignLeft
                }
            }
        }

        //
        // Section 3
        //

        ConfigSection {

            header: "FIXED WIDTH + ATTACHMENTS"

            SiLabeledComboBox {
                lwidth: root.labelWidth
                l: "Lorem: "
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    r: "B"
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"
                    r: "B"
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                l: "Lorem: "
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"

                    SiHelpButton {
                        alignment: Qt.AlignLeft
                    }
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    r: "B"

                    SiHelpButton {
                        alignment: Qt.AlignLeft
                    }
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"
                    r: "B"

                    SiHelpButton {
                        alignment: Qt.AlignLeft
                    }
                }
            }
        }

        //
        // Section 4
        //

        ConfigSection {

            header: "FLEX WIDTH + ATTACHMENTS"

            SiLabeledComboBox {
                lwidth: root.labelWidth
                l: "Lorem: "
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    r: "B"
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"
                    r: "B"
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                l: "Lorem: "
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"

                    SiHelpButton {
                        alignment: Qt.AlignLeft
                    }
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    r: "B"

                    SiHelpButton {
                        alignment: Qt.AlignLeft
                    }
                }
            }

            SiLabeledComboBox {
                lwidth: root.labelWidth
                model: ["Item 1", "Item 2", "Item 3"]

                SiLabeledCheckBox {
                    l: "A"
                    r: "B"

                    SiHelpButton {
                        alignment: Qt.AlignLeft
                    }
                }
            }
        }
    }
}

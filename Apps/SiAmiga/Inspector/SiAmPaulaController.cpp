// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmPaulaController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmPaulaController::SiAmPaulaController(SiAmController *parent)
    : SiAmInspectorController(parent)
{

}

QString
SiAmPaulaController::intBitLabel(int n) const
{
    static const char *labels[15] = {

        "TBE", "DSKBLK", "SOFT", "PORTS", "COPER", "VERTB", "BLIT",
        "AUD0", "AUD1", "AUD2", "AUD3", "RBF", "DSKSYN", "EXTER", "INTEN"
    };

    return n >= 0 && n < 15 ? QString(labels[n]) : QString();
}

QString
SiAmPaulaController::fifoAt(int i) const
{
    if (i < 0 || i >= m_fifoCount || i >= 6) return QString();
    return formatNumber(m_fifo[i], 2);
}

void
SiAmPaulaController::refreshData()
{
    // Read the Paula/disk-controller/audio info from the shared info
    // controller rather than sampling the core directly; requestUpdate()
    // coalesces the sampling across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::PAULA, 0.25);
    auto &info = infoController->paulaInfo();
    auto &dc = infoController->diskControllerInfo();

    m_intena = info.intena;
    m_intreq = info.intreq;
    m_adkcon = info.adkcon;

    switch (dc.state) {

        case DriveDmaState::OFF:   m_dcStateText = QString("Idle"); break;
        case DriveDmaState::WAIT:  m_dcStateText = QString("Waiting for sync signal"); break;
        case DriveDmaState::READ:  m_dcStateText = QString("Reading"); break;
        case DriveDmaState::WRITE: m_dcStateText = QString("Writing"); break;
        default:                   m_dcStateText = QString("UNKNOWN"); break;
    }

    m_selectedDrive = int(dc.selectedDrive);
    m_dsklen  = dc.dsklen;
    m_dskbytr = dc.dskbytr;
    m_dsksync = dc.dsksync;
    m_fifoCount = dc.fifoCount;
    for (int i = 0; i < 6; i++) m_fifo[i] = dc.fifo[i];

    for (int ch = 0; ch < 4; ch++) {

        auto &a = infoController->audioInfo(ch);

        m_audLen[ch] = a.audlenLatch;
        m_audPer[ch] = a.audperLatch;
        m_audVol[ch] = a.audvolLatch;
        m_audDat[ch] = a.auddat;

        // Advances this channel's display state exactly the way the Swift
        // reference's assignImage() does -- see the class comment.
        int &ds = m_displayState[ch];

        switch (ds) {

            case 0: if (a.state != 0) ds = a.dma ? 1 : 2; break;
            case 1: ds = 5; break;
            case 5: ds = 2; break;
            case 2: ds = 3; break;
            case 3: ds = (a.state == 2 || a.state == 3) ? 2 : 0; break;
            default: ds = 0; break;
        }
    }

    emit paulaChanged();
}

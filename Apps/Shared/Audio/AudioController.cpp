// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "AudioController.h"
#include "Logger.h"
#include <QDebug>

AudioController::AudioController() : QObject() {}

AudioController::~AudioController()
{
    stop();
}

void
AudioController::setDelegate(AudioControllerDelegate *ptr)
{
    delegate = ptr;
}

void
AudioController::removeDelegate(AudioControllerDelegate *ptr)
{
    if (delegate == ptr) delegate = nullptr;
}

void AudioController::start()
{
    LogTask task("Starting AudioController...");

    QAudioDevice info = QMediaDevices::defaultAudioOutput();
    QAudioFormat format = info.preferredFormat();

    qCDebug(siLog) << "System preferred sample rate:" << format.sampleRate()
                   << "Channels:" << format.channelCount()
                   << "Format:" << format.sampleFormat();

    assert(m_audioSink == nullptr);
    m_audioSink = new QAudioSink(info, format, this);

    if (delegate) delegate->linkAudioSink(m_audioSink, format);

    if (m_audioSink->error() != QAudio::NoError) {
        qCWarning(siLog) << "Error starting audio output:" << m_audioSink->error();
    }
}

void
AudioController::stop()
{
    LogTask task("Stopping AudioController...");

    if (m_audioSink) {
        m_audioSink->stop();
        m_audioSink->deleteLater();
        m_audioSink = nullptr;
    }
}

/// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QAudioSink>
#include <QMediaDevices>

class AudioControllerDelegate {

  public:

    // Called whenever the audio sink is (re)configured, so the delegate can
    // hook up its own audio source (e.g. the emulator core's audio port).
    virtual void linkAudioSink(QAudioSink *sink, QAudioFormat &format) { };
};

class AudioController : public QObject
{
    Q_OBJECT

    // Gateway to the host audio backend
    QAudioSink* m_audioSink = nullptr;

    // Delegate
    AudioControllerDelegate *delegate = nullptr;

public:

    AudioController();
    ~AudioController();

    void setDelegate(AudioControllerDelegate *ptr);
    void removeDelegate(AudioControllerDelegate *ptr);

    void start();
    void stop();
};

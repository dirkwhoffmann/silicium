import QtMultimedia

pragma Singleton

SoundEffect {

    id: root
    volume: 0.5

    function playAlert() {

        // Cut off if already playing
        if (root.playing) root.stop();

        root.source = "qrc:/sounds/universfield-system-notification-199277.wav"
        root.play();
    }
}
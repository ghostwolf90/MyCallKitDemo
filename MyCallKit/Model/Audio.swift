import AVFoundation

func configureAudioSession() {
    print("Configuring audio session")
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(AVAudioSession.Category.playAndRecord)
        try session.setMode(AVAudioSession.Mode.voiceChat)
    } catch (let error) {
        print("Error while configuring audio session: \(error)")
    }
}

func startAudio() {    
    print("Starting audio")
}

func stopAudio() {
    print("Stopping audio")
}

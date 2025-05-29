import Foundation
import AVFoundation

public class SoundManager {
    public static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        // Preload all sound effects
        preloadSound("swish")
        preloadSound("hop")
        preloadSound("capture")
        preloadSound("victory")
        preloadSound("dice")
    }
    
    private func preloadSound(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Could not find sound file: \(name).wav")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[name] = player
        } catch {
            print("Could not create audio player for \(name).wav: \(error)")
        }
    }
    
    public func playSound(_ name: String) {
        guard let player = audioPlayers[name] else {
            print("Sound not found: \(name)")
            return
        }
        
        // Reset the player to the beginning if it's already playing
        if player.isPlaying {
            player.currentTime = 0
        }
        
        player.play()
    }
} 

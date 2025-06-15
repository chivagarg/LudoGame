import Foundation
import AVFoundation

public class SoundManager {
    public static let shared = SoundManager()
    
    // Define constants for sound file names to avoid magic strings
    private struct SoundFiles {
        static let swish = "swish"
        static let hop = "hop2"
        static let capture = "capture"
        static let victory = "victory"
        static let dice = "dice"
    }
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        // Preload all sound effects using the constants
        preloadSound(SoundFiles.swish)
        preloadSound(SoundFiles.hop)
        preloadSound(SoundFiles.capture)
        preloadSound(SoundFiles.victory)
        preloadSound(SoundFiles.dice)
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
    
    // MARK: - Specific Sound Functions
    
    public func playDiceRollSound() {
        playSound(SoundFiles.dice)
    }
    
    public func playPawnHopSound() {
        playSound(SoundFiles.hop)
    }
    
    public func playPawnCaptureSound() {
        playSound(SoundFiles.capture)
    }
    
    public func playPawnReachedHomeSound() {
        playSound(SoundFiles.victory)
    }
    
    public func playPawnLeaveHomeSound() {
        playSound(SoundFiles.swish)
    }
} 

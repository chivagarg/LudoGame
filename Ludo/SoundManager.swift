import Foundation
import AVFoundation

public class SoundManager {
    public static let shared = SoundManager()
    
    // Define constants for sound file names to avoid magic strings
    private struct SoundFiles {
        static let leaveHome = "boing.mp3"
        static let hop = "hop.wav"
        static let hopReverse = "hopReverse.wav"
        static let capture = "capture.wav"
        static let victory = "victory.wav"
        static let dice = "dice.wav"
    }
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        // Preload all sound effects using the constants
        preloadSound(named: SoundFiles.leaveHome)
        preloadSound(named: SoundFiles.hop)
        preloadSound(named: SoundFiles.hopReverse)
        preloadSound(named: SoundFiles.capture)
        preloadSound(named: SoundFiles.victory)
        preloadSound(named: SoundFiles.dice)
    }
    
    private func preloadSound(named filename: String) {
        let fileComponents = filename.components(separatedBy: ".")
        guard fileComponents.count == 2,
              let name = fileComponents.first,
              let ext = fileComponents.last else {
            print("Invalid sound filename format: \(filename)")
            return
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Could not find sound file: \(filename)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[filename] = player
        } catch {
            print("Could not create audio player for \(filename): \(error)")
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

    public func playReverseHopSound() {
        playSound(SoundFiles.hopReverse)
    }
    
    public func playPawnCaptureSound() {
        playSound(SoundFiles.capture)
    }
    
    public func playPawnReachedHomeSound() {
        playSound(SoundFiles.victory)
    }
    
    public func playPawnLeaveHomeSound() {
        playSound(SoundFiles.leaveHome)
    }
} 

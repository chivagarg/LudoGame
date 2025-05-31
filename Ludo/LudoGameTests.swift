import XCTest
@testable import Ludo

final class LudoGameTests: XCTestCase {
    var game: LudoGame!
    
    override func setUp() {
        super.setUp()
        game = LudoGame()
        game.startGame()
    }
    
    override func tearDown() {
        game = nil
        super.tearDown()
    }
    
    // MARK: - Guard Statement Tests
    
    func testMovePawnGuardStatements() {
        // Test: Can't move if it's not your turn
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 6
        game.eligiblePawns = [0] // Red pawn 0 is eligible
        
        // Try to move a green pawn
        game.movePawn(color: .green, pawnId: 0, steps: 6)
        XCTAssertNil(game.pawns[.green]?[0].positionIndex, "Green pawn shouldn't move when it's red's turn")
        
        // Test: Can't move if it's not your roll
        game.currentPlayer = .red
        game.currentRollPlayer = .green
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        XCTAssertNil(game.pawns[.red]?[0].positionIndex, "Red pawn shouldn't move when it's green's roll")
        
        // Test: Can't move if pawn is not eligible
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.eligiblePawns = []
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        XCTAssertNil(game.pawns[.red]?[0].positionIndex, "Pawn shouldn't move when not eligible")
    }
    
    // MARK: - Capture Tests
    
    func testPawnCapture() {
        // Setup: Move red pawn to a position
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        
        // Move green pawn to the same position
        game.currentPlayer = .green
        game.currentRollPlayer = .green
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .green, pawnId: 0, steps: 6)
        
        // Move red pawn again to capture green pawn
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        
        // Verify capture
        XCTAssertNil(game.pawns[.green]?[0].positionIndex, "Green pawn should be captured")
        XCTAssertEqual(game.scores[.red], 3, "Red player should get 3 points for capture")
    }
    
    func testNoCaptureInSafePosition() {
        // Setup: Move red pawn to a safe position (e.g., starting position)
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        
        // Move green pawn to the same safe position
        game.currentPlayer = .green
        game.currentRollPlayer = .green
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .green, pawnId: 0, steps: 6)
        
        // Move red pawn again to try to capture green pawn
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        
        // Verify no capture
        XCTAssertNotNil(game.pawns[.green]?[0].positionIndex, "Green pawn shouldn't be captured in safe position")
        XCTAssertEqual(game.scores[.red], 0, "Red player shouldn't get points for failed capture")
    }
    
    // MARK: - Home Completion Tests
    
    func testScoreForHomeCompletion() {
        // Setup: Move all pawns to home
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        
        // Move first pawn home
        game.diceValue = 60 // Assuming this moves to home
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 60)
        XCTAssertEqual(game.scores[.red], 16, "First pawn should get 16 points")
        
        // Move second pawn home
        game.diceValue = 60
        game.eligiblePawns = [1]
        game.movePawn(color: .red, pawnId: 1, steps: 60)
        XCTAssertEqual(game.scores[.red], 31, "Second pawn should get 15 points")
        
        // Move third pawn home
        game.diceValue = 60
        game.eligiblePawns = [2]
        game.movePawn(color: .red, pawnId: 2, steps: 60)
        XCTAssertEqual(game.scores[.red], 46, "Third pawn should get 15 points")
        
        // Move fourth pawn home
        game.diceValue = 60
        game.eligiblePawns = [3]
        game.movePawn(color: .red, pawnId: 3, steps: 60)
        XCTAssertEqual(game.scores[.red], 61, "Fourth pawn should get 15 points")
    }
    
    // MARK: - Game Completion Tests
    
    func testGameCompletion() {
        // Setup: Move all red pawns to home
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        
        for pawnId in 0..<4 {
            game.diceValue = 60 // Assuming this moves to home
            game.eligiblePawns = [pawnId]
            game.movePawn(color: .red, pawnId: pawnId, steps: 60)
        }
        
        XCTAssertTrue(game.hasCompletedGame(color: .red), "Red player should have completed the game")
        XCTAssertFalse(game.isGameOver, "Game shouldn't be over until all players complete")
        
        // Move all green pawns to home
        game.currentPlayer = .green
        game.currentRollPlayer = .green
        
        for pawnId in 0..<4 {
            game.diceValue = 60
            game.eligiblePawns = [pawnId]
            game.movePawn(color: .green, pawnId: pawnId, steps: 60)
        }
        
        // Move all yellow pawns to home
        game.currentPlayer = .yellow
        game.currentRollPlayer = .yellow
        
        for pawnId in 0..<4 {
            game.diceValue = 60
            game.eligiblePawns = [pawnId]
            game.movePawn(color: .yellow, pawnId: pawnId, steps: 60)
        }
        
        // Move all blue pawns to home
        game.currentPlayer = .blue
        game.currentRollPlayer = .blue
        
        for pawnId in 0..<4 {
            game.diceValue = 60
            game.eligiblePawns = [pawnId]
            game.movePawn(color: .blue, pawnId: pawnId, steps: 60)
        }
        
        XCTAssertTrue(game.isGameOver, "Game should be over when all players complete")
        XCTAssertNotNil(game.finalRankings, "Final rankings should be set")
    }
    
    // MARK: - Turn Movement Tests
    
    func testTurnMovement() {
        // Test normal turn progression
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 5
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 5)
        
        XCTAssertEqual(game.currentPlayer, .green, "Turn should move to green")
        XCTAssertNil(game.currentRollPlayer, "Roll player should be cleared")
        XCTAssertTrue(game.eligiblePawns.isEmpty, "Eligible pawns should be cleared")
        
        // Test turn staying with same player after 6
        game.currentPlayer = .green
        game.currentRollPlayer = .green
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .green, pawnId: 0, steps: 6)
        
        XCTAssertEqual(game.currentPlayer, .green, "Turn should stay with green after rolling 6")
        XCTAssertNil(game.currentRollPlayer, "Roll player should be cleared")
        XCTAssertTrue(game.eligiblePawns.isEmpty, "Eligible pawns should be cleared")
    }
    
    // MARK: - Home Exit Tests
    
    func testPawnExitFromHome() {
        // Test: Can't exit home without 6
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 5
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 5)
        
        XCTAssertNil(game.pawns[.red]?[0].positionIndex, "Pawn shouldn't exit home without 6")
        
        // Test: Can exit home with 6
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        
        XCTAssertEqual(game.pawns[.red]?[0].positionIndex, 0, "Pawn should exit home with 6")
    }
    
    // MARK: - Second Roll Tests
    
    func testSecondRollAfterSix() {
        // Setup: Roll a 6 and move a pawn
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.diceValue = 6
        game.eligiblePawns = [0]
        game.movePawn(color: .red, pawnId: 0, steps: 6)
        
        // Verify state after move
        XCTAssertEqual(game.currentPlayer, .red, "Turn should stay with red")
        XCTAssertNil(game.currentRollPlayer, "Roll player should be cleared")
        XCTAssertTrue(game.eligiblePawns.isEmpty, "Eligible pawns should be cleared")
        
        // Roll again
        game.rollDice()
        
        // Verify new eligible pawns
        XCTAssertFalse(game.eligiblePawns.isEmpty, "Should have eligible pawns after rolling")
        XCTAssertEqual(game.currentRollPlayer, .red, "Roll player should be red")
    }
} 

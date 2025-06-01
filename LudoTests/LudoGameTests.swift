//
//  LudoGameTests.swift
//  LudoTests
//

import XCTest
@testable import Ludo  // Replace 'Ludo' with the actual name of your app module

class LudoGameTests: XCTestCase {

    var game: LudoGame!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        game = LudoGame()
        game.startGame() // Start the game to reset pawns to home
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        game = nil
    }

    // MARK: - Test Moving Pawn Out of Home

    func testMoveRedPawnOutOfHomeWithSix() {
        game.currentPlayer = .red
        game.diceValue = 6
        let pawnId = 0
        
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.red]?[pawnId].positionIndex, "Red pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 6, col: 1) // The first position on the red path
        XCTAssertEqual(game.path(for: .red)[game.pawns[.red]![pawnId].positionIndex!], expectedPosition, "Red pawn should move to \(expectedPosition) with a 6.")
        // Turn should not change
        XCTAssertEqual(game.currentPlayer, .red, "The current player should remain red after moving the pawn.")
        // Check that the eligible pawns have been cleared
        XCTAssertTrue(game.eligiblePawns.isEmpty, "Eligible pawns should be cleared")
    }

    func testMoveGreenPawnOutOfHomeWithSix() {
        game.currentPlayer = .green
        game.diceValue = 6
        let pawnId = 0
        
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.green]?[pawnId].positionIndex, "Green pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 1, col: 8) // The first position on the green path
        XCTAssertEqual(game.path(for: .green)[game.pawns[.green]![pawnId].positionIndex!],expectedPosition, "Green pawn should move to \(expectedPosition) with a 6.")
        // Turn should not change
        XCTAssertEqual(game.currentPlayer, .green, "The current player should remain green after moving the pawn.")
        // Check that the eligible pawns have been cleared
        XCTAssertTrue(game.eligiblePawns.isEmpty, "Eligible pawns should be cleared")
    }
    
    func testMoveYellowPawnOutOfHomeWithSix() {
        game.currentPlayer = .yellow
        game.diceValue = 6
        let pawnId = 0
        
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.yellow]?[pawnId].positionIndex, "Yellow pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 8, col: 13) // First position on the yellow path
        XCTAssertEqual(game.path(for: .yellow)[game.pawns[.yellow]![pawnId].positionIndex!],expectedPosition, "Yellow pawn should move to \(expectedPosition) with a 6.")
        // Turn should not change
        XCTAssertEqual(game.currentPlayer, .yellow, "The current player should remain yellow after moving the pawn.")
        // Check that the eligible pawns have been cleared
        XCTAssertTrue(game.eligiblePawns.isEmpty, "Eligible pawns should be cleared")
    }
    
    func testMoveBluePawnOutOfHomeWithSix() {
        game.currentPlayer = .blue
        game.diceValue = 6
        let pawnId = 0
        
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.blue]?[pawnId].positionIndex, "Blue pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 13, col: 6) // First position on the blue path
        XCTAssertEqual(game.path(for: .blue)[game.pawns[.blue]![pawnId].positionIndex!],expectedPosition, "Blue pawn should move to \(expectedPosition) with a 6.")
        // Turn should not change
        XCTAssertEqual(game.currentPlayer, .blue, "The current player should remain blue after moving the pawn.")
        // Check that the eligible pawns have been cleared
        XCTAssertTrue(game.eligiblePawns.isEmpty, "Eligible pawns should be cleared")
    }

    // MARK: - Test Moving Pawn on Path

    func testMoveRedPawnForwardOnPath() {
        game.currentPlayer = .red
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
       // Move out first to move pawn to starting position
       game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 1
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        let expectedPosition = Position(row: 6, col: 2)
        // Check if the pawn is at the correct position on the path
        XCTAssertNotNil(game.pawns[.red]?[0].positionIndex, "Red pawn should be on the path.")
        XCTAssertEqual(game.path(for: .red)[game.pawns[.red]![0].positionIndex!], expectedPosition, "Red pawn should move forward \(game.diceValue) steps on the path.")
    }

     func testMoveGreenPawnForwardOnPath() {
         game.currentPlayer = .green
         game.diceValue = 6
         
         game.testRollDice(value: game.diceValue)

         let pawnId = 0
         
        // Move out first to move pawn to starting position
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)
         
         game.diceValue = 1
         game.testRollDice(value: game.diceValue)

         game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

         // Check if the pawn is at the correct position on the path
         XCTAssertNotNil(game.pawns[.green]?[0].positionIndex, "Green pawn should be on the path.")
         XCTAssertEqual(game.path(for: .green)[game.pawns[.green]![0].positionIndex!], Position(row: 2, col: 8), "Green pawn should move forward \(game.diceValue) steps on the path.")

    }

    func testMoveYellowPawnForwardOnPath() {
        game.currentPlayer = .yellow
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
       // Move out first to move pawn to starting position
       game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)
        
        game.diceValue = 1
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn is at the correct position on the path
        XCTAssertNotNil(game.pawns[.yellow]?[0].positionIndex, "Yellow pawn should be on the path.")
        XCTAssertEqual(game.path(for: .yellow)[game.pawns[.yellow]![0].positionIndex!], Position(row: 8, col: 12), "Yellow pawn should move forward \(game.diceValue) steps on the path.")
    }

    func testMoveBluePawnForwardOnPath() {
        game.currentPlayer = .blue
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
       // Move out first to move pawn to starting position
       game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)
        
        game.diceValue = 14
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn is at the correct position on the path
        XCTAssertNotNil(game.pawns[.blue]?[0].positionIndex, "Blue pawn should be on the path.")
        XCTAssertEqual(game.path(for: .blue)[game.pawns[.blue]![0].positionIndex!], Position(row: 6, col: 1), "Blue pawn should move forward \(game.diceValue) steps on the path.")
    }

    func testMoveBluePawnToFinish() {
        game.currentPlayer = .blue
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
       // Move out first to move pawn to starting position
       game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

       let finalPositionIndex = game.pawns[.blue]?[0].positionIndex

       XCTAssertEqual(finalPositionIndex, -1, "Blue pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

    func testMoveRedPawnToFinish() {
        game.currentPlayer = .red
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
        // Move out first to move pawn to starting position
        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

       let finalPositionIndex = game.pawns[.red]?[0].positionIndex

       XCTAssertEqual(finalPositionIndex, -1, "Red pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }
    
    func testMoveYellowPawnToFinish() {
        game.currentPlayer = .yellow
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
       // Move out first to move pawn to starting position
       game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

       let finalPositionIndex = game.pawns[.yellow]?[0].positionIndex

       XCTAssertEqual(finalPositionIndex, -1, "Yellow pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

    func testMoveGreenPawnToFinish() {
        game.currentPlayer = .green
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
       // Move out first to move pawn to starting position
       game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

       let finalPositionIndex = game.pawns[.green]?[0].positionIndex

       XCTAssertEqual(finalPositionIndex, -1, "Green pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

    // MARK: - Test Reaching Home

    func testRedPawnReachesHomeExactly() {
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.eligiblePawns = [0]
        let pawnId = 0
        
        let redPathLength = game.path(for: .red).count
        let stepsToReachHomeIndex = redPathLength - 1 // Index of the last position

        // Manually set the pawn position close to home
        let initialIndex = stepsToReachHomeIndex - 3 // 3 steps away from home
        game.pawns[.red]?[pawnId].positionIndex = initialIndex

        game.diceValue = 3 // Exactly enough steps to reach home
        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.red]?[pawnId].positionIndex

        XCTAssertEqual(finalPositionIndex, -1, "Red pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

     func testGreenPawnReachesHomeExactly() {
         game.currentPlayer = .green
         game.currentRollPlayer = .green
         game.eligiblePawns = [0]
         let pawnId = 0
         
        let greenPathLength = game.path(for: .green).count
        let stepsToReachHomeIndex = greenPathLength - 1

        let initialIndex = stepsToReachHomeIndex - 2
        game.pawns[.green]?[pawnId].positionIndex = initialIndex

        game.diceValue = 2
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.green]?[pawnId].positionIndex
        XCTAssertEqual(finalPositionIndex, -1, "Green pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

    func testYellowPawnReachesHomeExactly() {
        game.currentPlayer = .yellow
        game.currentRollPlayer = .yellow
        game.eligiblePawns = [0]
        let pawnId = 0
        
        let yellowPathLength = game.path(for: .yellow).count
        let stepsToReachHomeIndex = yellowPathLength - 1

        let initialIndex = stepsToReachHomeIndex - 4
        game.pawns[.yellow]?[pawnId].positionIndex = initialIndex

        game.diceValue = 4
        game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.yellow]?[pawnId].positionIndex
        XCTAssertEqual(finalPositionIndex, -1, "Yellow pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

     func testBluePawnReachesHomeExactly() {
        game.currentPlayer = .blue
        game.currentRollPlayer = .blue
        game.eligiblePawns = [0]
        let pawnId = 0
         
        let bluePathLength = game.path(for: .blue).count
        let stepsToReachHomeIndex = bluePathLength - 1

        let initialIndex = stepsToReachHomeIndex - 5
        game.pawns[.blue]?[pawnId].positionIndex = initialIndex

        game.diceValue = 5
        game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.blue]?[pawnId].positionIndex
        XCTAssertEqual(finalPositionIndex, -1, "Blue pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }
    

    // MARK: - Test Overshooting Home

    func testRedPawnOvershootsHome() {
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.eligiblePawns = [0]
        let pawnId = 0

        let redPathLength = game.path(for: .red).count
        let stepsToReachHomeIndex = redPathLength - 1

        // Manually set the pawn position close to home
        let initialIndex = stepsToReachHomeIndex - 3 // 3 steps away from home
        game.pawns[.red]?[pawnId].positionIndex = initialIndex
        let initialPosition = game.path(for: .red)[initialIndex]

        game.diceValue = 4 // More steps than needed to reach home
        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        // When overshooting, the pawn should remain at its initial position
        XCTAssertNotNil(game.pawns[.red]?[pawnId].positionIndex, "Red pawn should remain on the path when overshooting home.")
        let finalPositionIndex = game.pawns[.red]![pawnId].positionIndex!
        let finalPosition = game.path(for: .red)[finalPositionIndex]
        XCTAssertEqual(finalPosition, initialPosition, "Red pawn should remain at its original position (\(initialPosition)) if it overshoots home.")
    }

    func testGreenPawnOvershootsHome() {
        game.currentPlayer = .green
        game.currentRollPlayer = .green
        game.eligiblePawns = [0]
        let pawnId = 0
        let greenPathLength = game.path(for: .green).count
        let stepsToReachHomeIndex = greenPathLength - 1

        let initialIndex = stepsToReachHomeIndex - 2
        game.pawns[.green]?[pawnId].positionIndex = initialIndex
        let initialPosition = game.path(for: .green)[initialIndex]

        game.diceValue = 3
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

        // When overshooting, the pawn should remain at its initial position
        XCTAssertNotNil(game.pawns[.green]?[pawnId].positionIndex, "Green pawn should remain on the path when overshooting home.")
        let finalPositionIndex = game.pawns[.green]![pawnId].positionIndex!
        let finalPosition = game.path(for: .green)[finalPositionIndex]
        XCTAssertEqual(finalPosition, initialPosition, "Green pawn should remain at its original position (\(initialPosition)) if it overshoots home.")
    }

     func testYellowPawnOvershootsHome() {
        game.currentPlayer = .yellow
        game.currentRollPlayer = .yellow
        game.eligiblePawns = [0]
        let pawnId = 0
         
        let yellowPathLength = game.path(for: .yellow).count
        let stepsToReachHomeIndex = yellowPathLength - 1

        let initialIndex = stepsToReachHomeIndex - 4
        game.pawns[.yellow]?[pawnId].positionIndex = initialIndex
        let initialPosition = game.path(for: .yellow)[initialIndex]

        game.diceValue = 5
        game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

        // When overshooting, the pawn should remain at its initial position
        XCTAssertNotNil(game.pawns[.yellow]?[pawnId].positionIndex, "Yellow pawn should remain on the path when overshooting home.")
        let finalPositionIndex = game.pawns[.yellow]![pawnId].positionIndex!
        let finalPosition = game.path(for: .yellow)[finalPositionIndex]
        XCTAssertEqual(finalPosition, initialPosition, "Yellow pawn should remain at its original position (\(initialPosition)) if it overshoots home.")
    }

    func testBluePawnOvershootsHome() {
        game.currentPlayer = .blue
        game.currentRollPlayer = .blue
        game.eligiblePawns = [0]
        let pawnId = 0

        let bluePathLength = game.path(for: .blue).count
        let stepsToReachHomeIndex = bluePathLength - 1

        let initialIndex = stepsToReachHomeIndex - 5
        game.pawns[.blue]?[pawnId].positionIndex = initialIndex
        let initialPosition = game.path(for: .blue)[initialIndex]

        game.diceValue = 6
        game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

        // When overshooting, the pawn should remain at its initial position
        XCTAssertNotNil(game.pawns[.blue]?[pawnId].positionIndex, "Blue pawn should remain on the path when overshooting home.")
        let finalPositionIndex = game.pawns[.blue]![pawnId].positionIndex!
        let finalPosition = game.path(for: .blue)[finalPositionIndex]
        XCTAssertEqual(finalPosition, initialPosition, "Blue pawn should remain at its original position (\(initialPosition)) if it overshoots home.")
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
    
    func testPawnCapturesSuccessfully() {
        // Move green pawn to Position(row: 2, col: 8)
        game.currentPlayer = .green
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
        // Move out first to move pawn to starting position
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)
        
        game.diceValue = 1
        game.testRollDice(value: game.diceValue)
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)
        
        // Now move red pawn to the same position to trigger the capture
        game.currentPlayer = .red
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)
        
        // Move out first to move pawn to starting position
        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 15
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)
        
        // Verify capture
        XCTAssertNil(game.pawns[.green]?[0].positionIndex, "Green pawn should be captured")
        XCTAssertEqual(game.scores[.red], 3, "Red player should get 3 points for capture")
    }
    
    func testNoCaptureInSafePositionStartingHome() {
        // Move green pawn to Position(row: 2, col: 8)
        game.currentPlayer = .green
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
        // Move out first to move pawn to starting position
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)
        
        // Now move red pawn to the same position
        game.currentPlayer = .red
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)
        
        // Move out first to move pawn to starting position
        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 14
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)
        
        // Verify no capture
        XCTAssertNotNil(game.pawns[.green]?[0].positionIndex, "Green pawn shouldn't be captured in safe position")
        XCTAssertEqual(game.scores[.red], 0, "Red player shouldn't get points for failed capture")
    }
    
    func testNoCaptureInSafePositionStar() {
        game.currentPlayer = .green
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0
        
        // Move out first to move pawn to starting position
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)
        
        // Move green to the nearest star (6,12)
        game.diceValue = 9
        game.testRollDice(value: game.diceValue)
        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)
        
        // Now move red pawn to the same position to trigger the capture
        game.currentPlayer = .red
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)
        
        // Move out first to move pawn to starting position
        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        game.diceValue = 23
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)
        
        // Verify no capture
        XCTAssertNotNil(game.pawns[.green]?[0].positionIndex, "Green pawn shouldn't be captured in safe position")
        XCTAssertEqual(game.scores[.red], 0, "Red player shouldn't get points for failed capture")
    }
    
    // MARK: - Home Completion Tests
    
    func testScoreForHomeCompletion() {
        // Setup: Move all pawns to home
        game.currentPlayer = .red
        
        game.diceValue = 6
        game.testRollDice(value: game.diceValue)
        
        // Move out pawn 0 to starting position
        game.movePawn(color: .red, pawnId: 0, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: 0, steps: game.diceValue)
        XCTAssertEqual(game.scores[.red], 16, "First pawn should get 16 points")
        
        // Move second pawn home
        game.diceValue = 6
        game.testRollDice(value: game.diceValue)
        
        // Move out pawn 1 to starting position
        game.movePawn(color: .red, pawnId: 1, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: 1, steps: game.diceValue)
        
        XCTAssertEqual(game.scores[.red], 31, "Second pawn should get 15 points")
        
        // Move third pawn home
        game.diceValue = 6
        game.testRollDice(value: game.diceValue)
        
        // Move out pawn 2 to starting position
        game.movePawn(color: .red, pawnId: 2, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .red, pawnId: 2, steps: game.diceValue)
        
        XCTAssertEqual(game.scores[.red], 45, "Third pawn should get 14 points")
        
        // Blue pawn finishes 4th
        game.currentPlayer = .blue
        game.diceValue = 6
        
        game.testRollDice(value: game.diceValue)
        
        // Move out pawn 0 to starting position
        game.movePawn(color: .blue, pawnId: 0, steps: game.diceValue)

        game.diceValue = 60
        game.testRollDice(value: game.diceValue)

        game.movePawn(color: .blue, pawnId: 0, steps: game.diceValue)
        
        XCTAssertEqual(game.scores[.blue], 13, "Fourth pawn should get 13 points")
        XCTAssertEqual(game.scores[.red], 45, "Red's score should stay unchanged")
    }
    
    // MARK: - Game Completion Tests
    
    func testGameCompletion() {
        // Setup: Move all red pawns to home
        game.currentPlayer = .red
        
        for pawnId in 0..<4 {
            // Move out pawn to starting position
            game.diceValue = 6
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

            // Move pawn to home
            game.diceValue = 60
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)
        }
        
        XCTAssertTrue(game.hasCompletedGame(color: .red), "Red player should have completed the game")
        XCTAssertFalse(game.isGameOver, "Game shouldn't be over until all players complete")
        
        // Move all green pawns to home
        game.currentPlayer = .green
        
        for pawnId in 0..<4 {
            // Move out pawn to starting position
            game.diceValue = 6
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

            // Move pawn to home
            game.diceValue = 60
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)
        }
        
        XCTAssertTrue(game.hasCompletedGame(color: .green), "Green player should have completed the game")
        XCTAssertFalse(game.isGameOver, "Game shouldn't be over until all players complete")
        
        // Move all yellow pawns to home
        game.currentPlayer = .yellow
        
        for pawnId in 0..<4 {
            // Move out pawn to starting position
            game.diceValue = 6
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

            // Move pawn to home
            game.diceValue = 60
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)
        }
        
        XCTAssertTrue(game.hasCompletedGame(color: .yellow), "Yellow should have completed the game")
        XCTAssertFalse(game.isGameOver, "Game shouldn't be over until all players complete")
        
        // Move all blue pawns to home
        game.currentPlayer = .blue
        
        for pawnId in 0..<4 {
            // Move out pawn to starting position
            game.diceValue = 6
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

            // Move pawn to home
            game.diceValue = 60
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)
        }
        
        XCTAssertTrue(game.hasCompletedGame(color: .blue), "Blue should have completed the game")
        XCTAssertTrue(game.isGameOver, "Game should be over when all players complete")
        XCTAssertNotNil(game.finalRankings, "Final rankings should be set")
        XCTAssertEqual(game.scores[.red], 58, "Score should be 16+15+14+13")
        XCTAssertEqual(game.scores[.green], 42, "Score should be 12+11+10+9")
        XCTAssertEqual(game.scores[.yellow], 26, "Score 8+7+6+5")
        XCTAssertEqual(game.scores[.blue], 10, "Score 4+3+2+1")
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
    
    func testRollingNon6WithPawnsAtHome() {
        game.currentPlayer = .blue
        game.diceValue = 4
        
        game.testRollDice(value: game.diceValue)

        let pawnId = 0

        let finalPositionIndex = game.pawns[.blue]?[pawnId].positionIndex

        XCTAssertNil(finalPositionIndex, "Blue pawn should remain at home with a non-6.")
    }

    func testNextTurns() {
        game.currentPlayer = .red
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .green, "Red -> Green")
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .yellow, "Green -> Yellow")
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .blue, "Yellow -> Blue")
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .red, "Blue -> Red")
    }
    
    func testNextTurnSkipsCompletedPlayer() {
        game.currentPlayer = .red
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .green, "Red -> Green")
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .yellow, "Green -> Yellow")
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .blue, "Yellow -> Blue")
        
        // Move all red pawns to home
        game.currentPlayer = .red
        
        for pawnId in 0..<4 {
            // Move out pawn to starting position
            game.diceValue = 6
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

            // Move pawn to home
            game.diceValue = 60
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)
        }
        // At completion of red, the turn would advance to green in movePawn
        XCTAssertEqual(game.currentPlayer, .green, "Red -> Green")

        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .yellow, "Green -> Yellow")

        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .blue, "Yellow -> Blue")

        // Red should get skipped.
        game.nextTurn()
        XCTAssertEqual(game.currentPlayer, .green, "Blue -> Green")
    }

    func testNextTurnClearingRoll() {
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.nextTurn(clearRoll: true)
        XCTAssertEqual(game.currentRollPlayer, nil, "CurrentRollPlayer cleared")
    }
 
    func testNextTurnWithoutClearingRoll() {
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        game.nextTurn(clearRoll: false)
        XCTAssertEqual(game.currentRollPlayer, .red, "CurrentRollPlayer cleared")
    }

    func testTurnChangesOnRollDiceWhenPlayerHasCompleted() {
        // Setup: Move all red pawns to home
        game.currentPlayer = .red
        game.currentRollPlayer = .red
        
        for pawnId in 0..<4 {
            // Move out pawn to starting position
            game.diceValue = 6
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

            // Move pawn to home
            game.diceValue = 60
            game.testRollDice(value: game.diceValue)
            game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)
        }

        game.rollDice()
        XCTAssertEqual(game.currentPlayer, .green, "No state change expected")
    }
    
//    func testRollDiceAutoMovesPawn() {
//        // Setup: Move all red pawns to starting position
//        game.currentPlayer = .red
//        game.currentRollPlayer = .red
//        
//        // Move one pawn to starting position
//        game.diceValue = 6
//        game.testRollDice(value: game.diceValue)
//        game.movePawn(color: .red, pawnId: 0, steps: game.diceValue)
//
//        game.rollDice()
//        XCTAssertNotNil(game.pawns[.red]?[0].positionIndex, "Red pawn should be on the path.")
//        
//        // Since there is only one eligible pawn, it should have moved immediately on diceroll
//        let startingPosition = Position(row: 6, col: 1)
//        XCTAssertNotEqual(game.path(for: .red)[game.pawns[.red]![0].positionIndex!], startingPosition, "Red pawn should not be at starting position.")
//    }

    // MARK: - Test Dice Roll Prevention
    
    func testDiceRollPreventionWithEligiblePawns() {
        // Set up initial state
        game.currentPlayer = .red
        game.rollDice()
        
        XCTAssertEqual(game.currentRollPlayer, .red, "First roll should set currentRollPlayer")
        
        game.currentRollPlayer = nil
        game.eligiblePawns = [0]
        
        // Try to roll while there are eligible pawns
        game.rollDice()
        
        XCTAssertNotEqual(game.currentRollPlayer, .red, "Second roll should not change currentRollPlayer")
    }
}

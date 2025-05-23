//
//  LudoGameTests.swift
//  LudoTests
//
//  Created by Shiva garg on 5/18/25.
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

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.red]?[pawnId].positionIndex, "Red pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 6, col: 1) // The first position on the red path
        XCTAssertEqual(game.path(for: .red)[game.pawns[.red]![pawnId].positionIndex!], expectedPosition, "Red pawn should move to \(expectedPosition) with a 6.")
    }

    func testMoveRedPawnOutOfHomeWithNonSix() {
        game.currentPlayer = .red
        game.diceValue = 3
        let pawnId = 0

        game.movePawn(color: .red, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.red]?[pawnId].positionIndex

        XCTAssertNil(finalPositionIndex, "Red pawn should remain at home with a non-6.")
    }

    func testMoveGreenPawnOutOfHomeWithSix() {
        game.currentPlayer = .green
        game.diceValue = 6
        let pawnId = 0

        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.green]?[pawnId].positionIndex, "Green pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 1, col: 8) // The first position on the green path
        XCTAssertEqual(game.path(for: .green)[game.pawns[.green]![pawnId].positionIndex!], expectedPosition, "Green pawn should move to \(expectedPosition) with a 6.")
    }

    func testMoveGreenPawnOutOfHomeWithNonSix() {
        game.currentPlayer = .green
        game.diceValue = 3
        let pawnId = 0

        game.movePawn(color: .green, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.green]?[pawnId].positionIndex

        XCTAssertNil(finalPositionIndex, "Green pawn should remain at home with a non-6.")
    }

    func testMoveYellowPawnOutOfHomeWithSix() {
        game.currentPlayer = .yellow
        game.diceValue = 6
        let pawnId = 0

        game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.yellow]?[pawnId].positionIndex, "Yellow pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 8, col: 13) // First position on the yellow path
        XCTAssertEqual(game.path(for: .yellow)[game.pawns[.yellow]![pawnId].positionIndex!], expectedPosition, "Yellow pawn should move to \(expectedPosition) with a 6.")
    }

    func testMoveYellowPawnOutOfHomeWithNonSix() {
        game.currentPlayer = .yellow
        game.diceValue = 3
        let pawnId = 0

        game.movePawn(color: .yellow, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.yellow]?[pawnId].positionIndex

        XCTAssertNil(finalPositionIndex, "Yellow pawn should remain at home with a non-6.")
    }

    func testMoveBluePawnOutOfHomeWithSix() {
        game.currentPlayer = .blue
        game.diceValue = 6
        let pawnId = 0

        game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

        // Check if the pawn moved out of home and is at the correct starting position
        XCTAssertNotNil(game.pawns[.blue]?[pawnId].positionIndex, "Blue pawn should move out of home with a 6.")
        let expectedPosition = Position(row: 13, col: 6) // First position on the blue path
        XCTAssertEqual(game.path(for: .blue)[game.pawns[.blue]![pawnId].positionIndex!], expectedPosition, "Blue pawn should move to \(expectedPosition) with a 6.")
    }

    func testMoveBluePawnOutOfHomeWithNonSix() {
        game.currentPlayer = .blue
        game.diceValue = 3
        let pawnId = 0

        game.movePawn(color: .blue, pawnId: pawnId, steps: game.diceValue)

        let finalPositionIndex = game.pawns[.blue]?[pawnId].positionIndex

        XCTAssertNil(finalPositionIndex, "Blue pawn should remain at home with a non-6.")
    }

    // MARK: - Test Moving Pawn on Path

    func testMoveRedPawnForwardOnPath() {
        game.currentPlayer = .red
        game.diceValue = 6 // Move out first
        game.movePawn(color: .red, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.red]![0].positionIndex!
        game.diceValue = 54
        let stepsToMove = game.diceValue
        game.movePawn(color: .red, pawnId: 0, steps: stepsToMove)

        let expectedPositionIndex = initialPositionIndex + stepsToMove
        let expectedPosition = Position(row: 7, col: 0) // Red path: (6,1) + 5 steps -> (6,6)
        // Check if the pawn is at the correct position on the path
        XCTAssertNotNil(game.pawns[.red]?[0].positionIndex, "Red pawn should be on the path.")
        XCTAssertEqual(game.path(for: .red)[game.pawns[.red]![0].positionIndex!], expectedPosition, "Red pawn should move forward \(stepsToMove) steps on the path.")
    }
    
    func testMoveRedPawnToFinish() {
        game.currentPlayer = .red
        game.diceValue = 6 // Move out first
        game.movePawn(color: .red, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.red]![0].positionIndex!
        game.diceValue = 60
        let stepsToMove = game.diceValue
        game.movePawn(color: .red, pawnId: 0, steps: stepsToMove)

        let finalPositionIndex = game.pawns[.red]?[0].positionIndex

        XCTAssertEqual(finalPositionIndex, -1, "Red pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

     func testMoveGreenPawnForwardOnPath() {
        game.currentPlayer = .green
        game.diceValue = 6 // Move out first
        game.movePawn(color: .green, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.green]![0].positionIndex!
        game.diceValue = 7
        let stepsToMove = game.diceValue
        game.movePawn(color: .green, pawnId: 0, steps: stepsToMove)

        let expectedPositionIndex = initialPositionIndex + stepsToMove
        let expectedPosition = Position(row: 6, col: 10) // Green path: (1,8) + 7 steps -> (6,10)
        // Check if the pawn is at the correct position on the path
        XCTAssertNotNil(game.pawns[.green]?[0].positionIndex, "Green pawn should be on the path.")
        XCTAssertEqual(game.path(for: .green)[game.pawns[.green]![0].positionIndex!], expectedPosition, "Green pawn should move forward \(stepsToMove) steps on the path.")
    }

    func testMoveYellowPawnForwardOnPath() {
        game.currentPlayer = .yellow
        game.diceValue = 6 // Move out first
        game.movePawn(color: .yellow, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.yellow]![0].positionIndex!
        game.diceValue = 9
        let stepsToMove = game.diceValue
        game.movePawn(color: .yellow, pawnId: 0, steps: stepsToMove) // move to 12,8

        let expectedPositionIndex = initialPositionIndex + stepsToMove
        let expectedPosition = Position(row: 12, col: 8) // Yellow path: (8,13) + 9 steps -> (15,8)
        // Check if the pawn is at the correct position on the path
        XCTAssertNotNil(game.pawns[.yellow]?[0].positionIndex, "Yellow pawn should be on the path.")
        XCTAssertEqual(game.path(for: .yellow)[game.pawns[.yellow]![0].positionIndex!], expectedPosition, "Yellow pawn should move forward \(stepsToMove) steps on the path.")
    }

    func testMoveBluePawnForwardOnPath() {
        game.currentPlayer = .blue
        game.diceValue = 6 // Move out first
        game.movePawn(color: .blue, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.blue]![0].positionIndex!
        game.diceValue = 14
        let stepsToMove = game.diceValue
        game.movePawn(color: .blue, pawnId: 0, steps: stepsToMove)

        let expectedPositionIndex = initialPositionIndex + stepsToMove
        let expectedPosition = Position(row: 6, col: 1)
        XCTAssertNotNil(game.pawns[.blue]?[0].positionIndex, "Blue pawn should be on the path.")
        XCTAssertEqual(game.path(for: .blue)[game.pawns[.blue]![0].positionIndex!], expectedPosition, "Blue pawn should move forward \(stepsToMove) steps on the path.")
    }

    func testMoveBluePawnToFinish() {
        game.currentPlayer = .blue
        game.diceValue = 6 // Move out first
        game.movePawn(color: .blue, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.blue]![0].positionIndex!
        game.diceValue = 60
        let stepsToMove = game.diceValue
        game.movePawn(color: .blue, pawnId: 0, steps: stepsToMove)

        let finalPositionIndex = game.pawns[.blue]?[0].positionIndex

        XCTAssertEqual(finalPositionIndex, -1, "Blue pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

    func testMoveYellowPawnToFinish() {
        game.currentPlayer = .yellow
        game.diceValue = 6 // Move out first
        game.movePawn(color: .yellow, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.yellow]![0].positionIndex!
        game.diceValue = 60
        let stepsToMove = game.diceValue
        game.movePawn(color: .yellow, pawnId: 0, steps: stepsToMove)

        let finalPositionIndex = game.pawns[.yellow]?[0].positionIndex

        XCTAssertEqual(finalPositionIndex, -1, "Yellow pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

    func testMoveGreenPawnToFinish() {
        game.currentPlayer = .green
        game.diceValue = 6 // Move out first
        game.movePawn(color: .green, pawnId: 0, steps: game.diceValue)

        let initialPositionIndex = game.pawns[.green]![0].positionIndex!
        game.diceValue = 60
        let stepsToMove = game.diceValue
        game.movePawn(color: .green, pawnId: 0, steps: stepsToMove)

        let finalPositionIndex = game.pawns[.green]?[0].positionIndex

        XCTAssertEqual(finalPositionIndex, -1, "Green pawn should reach home (positionIndex = -1) when moving exactly onto the last position.")
    }

    // MARK: - Test Reaching Home

    func testRedPawnReachesHomeExactly() {
        game.currentPlayer = .red
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
}

//
//  TutorialScene.swift
//  Korners
//
//  Created by Kris Kissel on 11/4/15.
//  Copyright © 2015 Kris Kissel. All rights reserved.
//

import Foundation
import SpriteKit


class TutorialScene: GameScene {
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        self.scaleMode = .ResizeFill
        addWallpaper()
        self.childNodeWithName("wallpaper")?.alpha = 0
        self.childNodeWithName("gameTitleLabel")?.alpha = 0
        self.childNodeWithName("statusLabel")?.alpha = 0
        drawBoard()
        recenterBoard()
        drawButtonsAndStatusLabel()
        let b0 = FastBoard()
        let b1 = b0.placePiece(3, column: 2, mark: 1)
        let b2 = b1.placePiece(5, column: 2, mark: 1)
        let b3 = b2.placePiece(2, column: 1, mark: 2)
        let b4 = b3.placePiece(4, column: 3, mark: 2)
        currentGameBoard = b4
        applyCurrentGameBoard()
        currentViewedBoard = currentGameBoard
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            
            let location = (touch as UITouch).locationInNode(self)
            let placeTouched = self.nodeAtPoint(location)
            // print(placeTouched.name)
            if let nameOfSpriteTouched = placeTouched.name{
                switch nameOfSpriteTouched {
                    
                    
                case "backButton":
                    break
                    
                    
                case "playAgainButton":
                    break
                    
                case "okayMoveButton":
                    //print("pressed okayMoveButton")
                    if (gameState == GameState.WaitingForJumpCommitOrExtendedJumpSequence || gameState == GameState.WaitingForPlacementCommit) {
                        hideCommitButtons()
                        
                        //clearPiecesFromView()
                        
                        if (gameState == GameState.WaitingForPlacementCommit) {
                            activePiece?.alpha=1
                        }
                        submitCurrentViewAsMove()
                        //checkWhetherCurrentPlayerHasWon()  // redundant?
                        
                        if (gameState == GameState.WaitingForJumpCommitOrExtendedJumpSequence) {
                            applyCurrentGameBoard()
                        }
                        legalJumpTargetTiles = []
                        activePiece = nil
                        if (gameState != GameState.GameOver) {
                            switchUser()
                            gameState = GameState.WaitingForAI
                            submitMoveToAI(currentGameBoard)
                        }
                    }
                    
                case "cancelMoveButton":
                    //print("pressed cancelMoveButton")
                    if (gameState == GameState.WaitingForJumpCommitOrExtendedJumpSequence || gameState == GameState.WaitingForPlacementCommit || gameState==GameState.WaitingForJumpTargetTile) {
                        hideCommitButtons()
                        clearPiecesFromView()
                        applyCurrentGameBoard()
                        gameState = GameState.ReadyForPlayerMove
                        print("game state: ReadyForPlayerMove")
                        print(currentGameBoard)
                        currentViewedBoard = currentGameBoard
                        print(currentViewedBoard)
                        legalJumpTargetTiles = []
                        activePiece = nil
                        userJumpSequence = []
                    }
                    
                case "player1", "player2":
                    if (gameState == GameState.ReadyForPlayerMove) {
                        startJump(placeTouched)
                        activePiece = placeTouched
                    }
                    
                default:
                    if (nameOfSpriteTouched == "" || nameOfSpriteTouched == "wallpaper") {break}
                    // might need to redo this with a switch instead of if-else
                    let touchedSquareCoordinates = getSquareCoordinatesFromSquareName(placeTouched.name!)
                    let row = touchedSquareCoordinates.1
                    let col = touchedSquareCoordinates.0
                    // note that touchedSquareCoorindates has the form (column, row)
                    if (gameState == GameState.WaitingForJumpTargetTile || gameState == GameState.WaitingForJumpCommitOrExtendedJumpSequence) {
                        let startingCoordinates = getSquareCoordinatesFromSquareName(activePiece!.parent!.name!)
                        let startingRow = startingCoordinates.1
                        let startingColumn = startingCoordinates.0
                        if  (currentViewedBoard.legalToJump(startingRow, startingColumn: startingColumn, endingRow: row, endingColumn: col, mark: playerNumber(currentPlayer))){
                            userJumpSequence.append((row, col))
                            displayJumpResultAnimated(row, targetColumn: col) // this could break!!!
                        }
                    }
                    else if (gameState == GameState.ReadyForPlayerMove) {
                        // player can place a piece or use a piece to jump
                        if currentViewedBoard.isEmptyTile(row, column: col) {
                            // player is adding a piece to the board -- need to add a commit stage here.
                            addPieceToBoardAnimated(placeTouched.name!, player: currentPlayer)
                            activePiece = placeTouched.childNodeWithName(playerName(currentPlayer))
                            activePiece?.alpha = ColorConstants.OpacityConstant
                            gameState = GameState.WaitingForPlacementCommit
                            revealCommitButtons()
                            
                            previousGameBoard = currentViewedBoard
                            currentViewedBoard = currentViewedBoard.placePiece(row, column: col, mark: playerNumber(currentPlayer))
                        }
                        else {
                            if let touchedPiece = placeTouched.childNodeWithName(playerName(currentPlayer)) {
                                // player touched tile containing own piece
                                // the next two lines are a repetition of code above, maybe I should extract them into another method?
                                startJump(touchedPiece)
                                activePiece = touchedPiece
                            }
                            else {
                                // player touched a tile containing opponent's piece
                            }
                        }
                    }
                }
            }
            else {
            }
        }
    }
    
    enum TutorialState {
        case waitingToPlaceFirstPiece
        case waitingToCommitFirstPiece
        case waitingToSelectPieceForJump
        case waitingToSelectTarget
        case explainingGameGoal
    }

    
    
}
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
    
    var tutorialState = TutorialState.waitingToPlaceFirstPiece{ didSet {
        displayGameState()
        }
        }
    
    let message1 = "Touch any Square"
    let message2 = "Accept or Cancel"
    let message3 = "Touch One Of Your Pieces"
    let message4 = "Select a Jump Target"
    let message5 = "Accept or Cancel"
    let message6 = "Goal:"
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        self.scaleMode = .ResizeFill
        addWallpaper()
        drawBoard()
        drawButtonsAndStatusLabel()
        recenterBoard()
        self.childNodeWithName("wallpaper")?.alpha = 0
        self.childNodeWithName("gameTitleLabel")?.alpha = 0
        currentPlayerLabel.text = message1
        currentPlayerLabel.color = UIColor.blueColor()
        let b0 = FastBoard()
        let b1 = b0.placePiece(3, column: 2, mark: 1)
        let b2 = b1.placePiece(5, column: 2, mark: 1)
        let b3 = b2.placePiece(2, column: 1, mark: 2)
        let b4 = b3.placePiece(4, column: 3, mark: 2)
        currentGameBoard = b4
        applyCurrentGameBoard()
        currentViewedBoard = currentGameBoard
    }
    
    override func displayGameState() {
        let message: String
        switch tutorialState {
        case TutorialState.waitingToPlaceFirstPiece:
            message = message1
        case TutorialState.waitingToCommitFirstPiece:
            message = message2
        case TutorialState.waitingToSelectPieceForJump:
            message = message3
        case TutorialState.waitingToSelectTarget:
            message = message4
        case TutorialState.waitingToConfirmJump:
            message = message5
        case TutorialState.explainingGameGoal:
            message = message6
        }
        currentPlayerLabel.text = message
        
        if (tutorialState == TutorialState.waitingToPlaceFirstPiece) {
            currentPlayerLabel.text = message1   // Change this to ASSET
            currentPlayerLabel.fontColor = UIColor.blueColor()
            //print(ai.ratePosition(currentGameBoard))
        }
        if (tutorialState == TutorialState.waitingToCommitFirstPiece) {
            currentPlayerLabel.text = message2 // Change this to ASSET
            currentPlayerLabel.fontColor = UIColor.blueColor()
        }
    }
    
    override func submitCurrentViewAsMove() {
        if (tutorialState == TutorialState.waitingToCommitFirstPiece) {
            currentGameBoard = currentViewedBoard // commits the current move
        }
        else {
            currentGameBoard = currentGameBoard.jumpTiles(userJumpSequence)
        }
        legalJumpTargetTiles = []
        activePiece = nil
        
    }
    
    func placeBlackPieceForTutorial(){
        let selectedRow: Int
        let selectedColumn = 2
        if (currentGameBoard.getValue(2, column: 2) == 1){
            selectedRow = 6
        }
        else{
            selectedRow = 2
        }
        self.addPieceToBoardAnimated("\(selectedColumn)\(selectedRow)", player: .player2)
        self.currentGameBoard = currentGameBoard.placePiece(selectedRow, column: selectedColumn, mark: 2)
        self.currentViewedBoard = currentGameBoard
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            
            let location = (touch as UITouch).locationInNode(self)
            let placeTouched = self.nodeAtPoint(location)
            // print(placeTouched.name)
            if let nameOfSpriteTouched = placeTouched.name{
                switch nameOfSpriteTouched {
                    
                case "backButton", "playAgainButton", "wallpaper", "gameTitleLabel", "statusLabel", "player2", "":
                    break
                    
                case "okayMoveButton":
                    switch tutorialState {
                    case TutorialState.waitingToCommitFirstPiece, TutorialState.waitingToConfirmJump:
                        hideCommitButtons()
                        activePiece?.alpha=1
                        submitCurrentViewAsMove()
                        if (tutorialState == TutorialState.waitingToCommitFirstPiece){
                            tutorialState = TutorialState.waitingToSelectPieceForJump
                            placeBlackPieceForTutorial()
                        }
                        if (tutorialState == TutorialState.waitingToConfirmJump){
                            applyCurrentGameBoard()
                            tutorialState = TutorialState.explainingGameGoal
                        }
                    default:
                        break
                    }

                    
                case "cancelMoveButton":
                    switch tutorialState{
                    case TutorialState.waitingToCommitFirstPiece, TutorialState.waitingToSelectTarget, TutorialState.waitingToConfirmJump:
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
                        if (tutorialState == TutorialState.waitingToCommitFirstPiece){
                            tutorialState = TutorialState.waitingToPlaceFirstPiece
                        }
                        else {
                            tutorialState = TutorialState.waitingToSelectPieceForJump
                        }
                        
                    default:
                        break
                    }

                case "player1":
                    switch tutorialState {
                    case TutorialState.waitingToSelectPieceForJump:
                        startJump(placeTouched)
                        activePiece = placeTouched
                        tutorialState = TutorialState.waitingToSelectTarget
                    default:
                        break
                    }

                    
                default:
                    switch tutorialState {
                    case TutorialState.waitingToPlaceFirstPiece:
                        let touchedSquareCoordinates = getSquareCoordinatesFromSquareName(placeTouched.name!)
                        let row = touchedSquareCoordinates.1
                        let col = touchedSquareCoordinates.0
                        if currentViewedBoard.isEmptyTile(row, column: col) {
                            // player is adding a piece to the board -- need to add a commit stage here.
                            addPieceToBoardAnimated(placeTouched.name!, player: currentPlayer)
                            activePiece = placeTouched.childNodeWithName(playerName(currentPlayer))
                            activePiece?.alpha = ColorConstants.OpacityConstant
                            gameState = GameState.WaitingForPlacementCommit
                            revealCommitButtons()
                            
                            previousGameBoard = currentViewedBoard
                            currentViewedBoard = currentViewedBoard.placePiece(row, column: col, mark: playerNumber(currentPlayer))
                            tutorialState = TutorialState.waitingToCommitFirstPiece
                        }
                    case TutorialState.waitingToSelectTarget:
                        let touchedSquareCoordinates = getSquareCoordinatesFromSquareName(placeTouched.name!)
                        let row = touchedSquareCoordinates.1
                        let col = touchedSquareCoordinates.0
                        let startingCoordinates = getSquareCoordinatesFromSquareName(activePiece!.parent!.name!)
                        let startingRow = startingCoordinates.1
                        let startingColumn = startingCoordinates.0
                        if  (currentViewedBoard.legalToJump(startingRow, startingColumn: startingColumn, endingRow: row, endingColumn: col, mark: playerNumber(currentPlayer))){
                            userJumpSequence.append((row, col))
                            displayJumpResultAnimated(row, targetColumn: col) // this could break!!!
                        }
                        tutorialState = TutorialState.waitingToConfirmJump
                    default:
                        break

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
        case waitingToConfirmJump
        case explainingGameGoal
    }

    
    
}
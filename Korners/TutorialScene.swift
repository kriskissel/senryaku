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
    
    var messageLine1: SKLabelNode?
    var messageLine2: SKLabelNode?
    var messageLine3: SKLabelNode?
    
    let message1 = ["Touch any", "empty square", ""]
    let message2 = ["Accept or Cancel", "", ""]
    let message3 = ["Touch one of your", "pieces to try to jump", "over one of mine"]
    let message4 = ["Select one of the", "highlighted tiles to", "jump onto it"]
    let message5 = ["Accept or Cancel", "", ""]
    let message6 = ["You will win if you", "make one of these", "shapes before I do"]
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        self.scaleMode = .ResizeFill
        addWallpaper()
        drawBoard()
        drawButtonsAndStatusLabel()
        //recenterBoard()
        drawMessageLines()
        recenterMessageLines()
        self.childNodeWithName("wallpaper")?.alpha = 0
        self.childNodeWithName("gameTitleLabel")?.alpha = 0
        currentPlayerLabel.alpha = 0
        let b0 = FastBoard()
        let b1 = b0.placePiece(3, column: 4, mark: 1)
        let b2 = b1.placePiece(5, column: 5, mark: 1)
        let b3 = b2.placePiece(2, column: 3, mark: 2)
        let b4 = b3.placePiece(4, column: 5, mark: 2)
        currentGameBoard = b4
        applyCurrentGameBoard()
        currentViewedBoard = currentGameBoard
    }
    
    func drawMessageLines(){
        messageLine1 = SKLabelNode(fontNamed: "Arial")
        messageLine2 = SKLabelNode(fontNamed: "Arial")
        messageLine3 = SKLabelNode(fontNamed: "Arial")
        messageLine1?.name = "messageLine1"
        messageLine2?.name = "messageLine2"
        messageLine3?.name = "messageLine3"
        messageLine1?.fontColor = UIColor.blueColor()
        messageLine2?.fontColor = UIColor.blueColor()
        messageLine3?.fontColor = UIColor.blueColor()
        messageLine1?.position = CGPointMake(0, 0)
        messageLine2?.position = CGPointMake(100, 100)
        messageLine3?.position = CGPointMake(200, 200)
        messageLine1?.text = message1[0]
        messageLine2?.text = message1[1]
        messageLine3?.text = message1[2]
        self.addChild(messageLine1!)
        self.addChild(messageLine2!)
        self.addChild(messageLine3!)
        
        let endButton = SKSpriteNode(imageNamed: "Check Button.png")
        endButton.size = (self.childNodeWithName("okayMoveButton") as! SKSpriteNode).size
        endButton.position = CGPointMake(0,0)
        endButton.name = "endButton"
        endButton.zPosition = -11
        self.addChild(endButton)
        endButton.hidden = true
    }
    

    
    override func recenterBoard() {
        recenterBoardInner()
        recenterMessageLines()
    }
    
    func recenterMessageLines() {
        // recalculate reference sizes
        let viewHeight = self.view!.bounds.height
        let viewWidth = self.view!.bounds.width
        let squareSize:CGFloat = (min(viewHeight,viewWidth) - (min(viewHeight, viewWidth) % 9) ) / 9
        pieceSize = squareSize - 4
        let availableWidth: CGFloat
        let availableHeight: CGFloat
        if (viewWidth < viewHeight / 2){
            // split view
            availableWidth = viewWidth
            availableHeight = viewHeight - 8.5 * squareSize
        }
            
        else if (viewWidth < viewHeight){
            // portrait
            availableWidth = viewWidth
            availableHeight = viewHeight - 8.5 * squareSize
        }
        else {
            // landscape
            availableWidth = viewWidth - 8.5 * squareSize
            availableHeight = viewHeight
        }
        let fontSize = min(0.2 * availableHeight, 0.1 * availableWidth)
        let messageLine1HorizontalPosition = viewHeight - 0.2 * availableHeight
        let messageLine2HorizontalPosition = viewHeight - 0.4 * availableHeight
        let messageLine3HorizontalPosition = viewHeight - 0.6 * availableHeight
        messageLine1?.fontSize = fontSize
        messageLine2?.fontSize = fontSize
        messageLine3?.fontSize = fontSize
        messageLine1?.position = CGPointMake(availableWidth / 2, messageLine1HorizontalPosition)
        messageLine2?.position = CGPointMake(availableWidth / 2, messageLine2HorizontalPosition)
        messageLine3?.position = CGPointMake(availableWidth / 2, messageLine3HorizontalPosition)
        self.childNodeWithName("endButton")!.position = CGPointMake(availableWidth / 2, viewHeight - 0.8 * availableHeight)
    }
    
    override func displayGameState() {
        let message: [String]
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
        messageLine1!.text = message[0]
        messageLine2!.text = message[1]
        messageLine3!.text = message[2]
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
        let selectedColumn: Int
        if (currentGameBoard.getValue(3, column: 5) == 1){
            selectedRow = 6
            selectedColumn = 4
        }
        else if (currentGameBoard.getValue(1, column: 2) == 1){
            selectedRow = 1
            selectedColumn = 1
        }
        else if (currentGameBoard.getValue(0, column: 7) == 1){
            selectedRow = 1
            selectedColumn = 7
        }
        else if (currentGameBoard.getValue(5, column: 6) == 1){
            selectedRow = 6
            selectedColumn = 6
        }
        else if (currentGameBoard.getValue(1, column: 7) == 1){
            selectedRow = 2
            selectedColumn = 7
        }
        else {
            selectedRow = 0
            selectedColumn = 7
        }
        self.addPieceToBoardAnimated("\(selectedColumn)\(selectedRow)", player: .player2)
        self.currentGameBoard = currentGameBoard.placePiece(selectedRow, column: selectedColumn, mark: 2)
        if (selectedRow == 6 && selectedColumn == 4){
            self.addPieceToBoardAnimated("62", player: .player2)
            self.currentGameBoard = currentGameBoard.placePiece(2, column: 6, mark: 2)
        }
        self.currentViewedBoard = currentGameBoard
        
    }
    
    func showVictoryConfigurations() {
        currentGameBoard = FastBoard()
        currentViewedBoard = currentGameBoard
        applyCurrentGameBoard()
        let victoryLocations = [(0,4),(0,3),(0,2),(1,2),(2,2),(1,6),(2,6),(3,6),(3,5),(3,4),
                                (4,1),(5,1),(6,1),(6,2),(6,3),(5,5),(5,6),(5,7),(6,7),(7,7)]
        for location in victoryLocations{
            self.addPieceToBoardAnimated("\(location.1)\(location.0)", player: .player1)
        }
        highlightTiles(victoryLocations)
        self.childNodeWithName("endButton")?.hidden = false
        self.childNodeWithName("endButton")?.zPosition = 10
    }
    
    func saveFinishedTutorialToDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(true, forKey: "FinishedTutorial")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            
            let location = (touch as UITouch).locationInNode(self)
            let placeTouched = self.nodeAtPoint(location)
            // print(placeTouched.name)
            if let nameOfSpriteTouched = placeTouched.name{
                switch nameOfSpriteTouched {
                    
                case "backButton", "playAgainButton", "wallpaper", "gameTitleLabel", "statusLabel", "player2", "", "messageLine1", "messageLine2", "messageLine3":
                    break
                    
                case "endButton":
                    switch tutorialState {
                    case TutorialState.explainingGameGoal:
                        saveFinishedTutorialToDefaults()
                        pressedBackButton()
                    default:
                        break
                    }
                    
                    
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
                            showVictoryConfigurations()
                        }
                    case TutorialState.explainingGameGoal:
                        saveFinishedTutorialToDefaults()
                        pressedBackButton()
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
                        if ( gameState == GameState.WaitingForJumpTargetTile){
                            tutorialState = TutorialState.waitingToSelectTarget
                        }
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
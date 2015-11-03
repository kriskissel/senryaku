//
//  GameScene.swift
//  SKPractice
//
//  Created by Kris Kissel on 9/6/15.
//  Copyright (c) 2015 Kris Kissel. All rights reserved.
//

import SpriteKit

var player1Piece = "Corners Player 1 Piece - 1"
var player2Piece = "Corners Player 2 Piece - 1"





var humanPlayer = 1 // change this to 2 if user elects to be player 2
var aiPlayer: Int { get { return (3 - humanPlayer) }}

var currentPlayer = Players.player1 // modify the initial value of this based on the value of humanPlayer
var currentPlayerLabel: SKLabelNode!

var gameTitleLabel: SKSpriteNode!

//var ai = FastAlphaBetaAI(aiMark: 2)

var ai = MiniMaxAI(aiMark: 2)


var activePiece: SKNode?
var legalJumpTargetTiles = [(Int,Int)]() // used when a jump is in progresss to indicate legal targets

class GameScene: SKScene {
    
    
    weak var viewController: UIViewController? // made this weak so that the gae scence and game view controller can be released from memory
    
    var layoutChanged = false { didSet {
        print("layoutChanged value has been changed.")
        // USE THIS OBSERVER TO INITIATE REPOSITIONING AND RESCALING OF BUTTONS WHEN
        // SWITCHING BETWEEN LANDSCAPE AND PORTRAIT VIEWS
        if (layoutChanged == true) {recenterBoard(); layoutChanged = false;}
        }
        }
    
    var aiPly: Int!
    
    var squareSizeMultiplier = CGFloat(10) // used to determine the size of tiles for display on various devices, 10 is just a temporary placeholder
    var pieceSize = CGFloat(10) // used to determine the size of game pieces, 10 i sjust a temporary placeholder
    
    var boardHeight: CGFloat {
        get {
            return 9 * squareSizeMultiplier // 9 to give a little extra space
        }
    }
    
    var visualElementHeight: CGFloat {
        get {
            return (self.view!.frame.size.height - ColorConstants.OffsetFromBottom - ColorConstants.OffsetFromTop - boardHeight) / 3
        }
    }
    
    var currentGameBoard = FastBoard() { didSet { print("Current board:"); print(currentGameBoard); boardHistory.append(currentGameBoard) ;checkWhetherCurrentPlayerHasWon() ; checkForDraw()
        }} // This will hold the state of the game board representing all completed moves.
    var currentViewedBoard = FastBoard() // This will hold the state of the game board shown on screen, which may include a placement or jumps not just submitted as the player's selected move.
    var previousGameBoard = FastBoard() // will hold previous game board for animation purposes
    
    var boardHistory = [FastBoard]() // records the sequence of currentGameBoards
    
    var gameState = GameState.ReadyForPlayerMove { didSet {
        //print("changed game state")
        displayGameState()
        } }
    
    var boardSquares = [SKNode]()
    
    var userJumpSequence = [(Int,Int)]()
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        self.scaleMode = .ResizeFill
        addWallpaper()
        drawBoard()
        recenterBoard()
        drawButtonsAndStatusLabel()
        currentGameBoard = FastBoard()
        applyCurrentGameBoard()
        currentViewedBoard = currentGameBoard
    }
    
    func addWallpaper() {
        self.backgroundColor = ColorConstants.BackgroundColor
        
        let backgroundImage = SKSpriteNode(imageNamed: "Wallpaper1.png")
        backgroundImage.position.x = self.view!.frame.width / 2
        backgroundImage.position.y = self.view!.frame.height / 2
        backgroundImage.alpha = ColorConstants.WallpaperOpacity
        
        // compute the scale factor necessary to fill screen with wallpaper without distorting it
        let xScaleFactor = self.view!.bounds.width / backgroundImage.size.width
        let yScaleFactor = self.view!.bounds.height / backgroundImage.size.height
        let resizingScaleFactor = max(xScaleFactor, yScaleFactor)
        backgroundImage.size.height = backgroundImage.size.height * resizingScaleFactor
        backgroundImage.size.width = backgroundImage.size.width * resizingScaleFactor
        
        self.addChild(backgroundImage)
        backgroundImage.zPosition = -10
    }
    
    func drawBoard() {
        
        let viewHeight = self.view!.bounds.height
        let viewWidth = self.view!.bounds.width
        print("View height: \(viewHeight) - View Width: \(viewWidth)")
        
        squareSizeMultiplier = (min(viewHeight,viewWidth) - (min(viewHeight, viewWidth) % 9) ) / 9
        print("square size multiplier: \(squareSizeMultiplier)")
        pieceSize = squareSizeMultiplier - 4
        
        // Board parameters
        let numRows = 8
        let numCols = 8
        let squareSize = CGSizeMake(squareSizeMultiplier, squareSizeMultiplier)
        let subSquareSize = CGSizeMake(squareSize.width-2,squareSize.height-2)
        let xOffset: CGFloat = (viewWidth - (8 * squareSize.width))
        let yOffset: CGFloat =  (squareSizeMultiplier / 2) + ColorConstants.OffsetFromBottom // + visualElementHeight
        for row in 0...numRows-1 {
            for col in 0...numCols-1 {
                let color = ColorConstants.NormalColor
                let square = SKSpriteNode(color: color, size: subSquareSize)
                square.position = CGPointMake(CGFloat(col) * squareSize.width + xOffset, CGFloat(row) * squareSize.height + yOffset)
                // Set sprite's name (e.g. 07, 24, 31) as column and row (like reading top left to bottom right)
                square.name = "\(col)\(7-row)"
                self.addChild(square)
                boardSquares.append(square)
            }
        }
    }
    
    func recenterBoard() {
        // recalculate reference sizes
        let viewHeight = self.view!.bounds.height
        let viewWidth = self.view!.bounds.width
        let squareSize:CGFloat = (min(viewHeight,viewWidth) - (min(viewHeight, viewWidth) % 9) ) / 9
        let subSquareSize = squareSize - 2
        pieceSize = squareSize - 4
        let xOffset: CGFloat
        let yOffset: CGFloat
        let availableWidth: CGFloat
        let availableHeight: CGFloat
        let okayX: CGFloat
        let okayY: CGFloat
        let cancelX: CGFloat
        let cancelY: CGFloat
        if (viewWidth < viewHeight){
            // portrait
            xOffset = viewWidth - (8 * squareSize)
            yOffset = xOffset // may need to change this for SplitView
            availableWidth = viewWidth
            availableHeight = viewHeight - 8.5 * squareSize
            okayX = availableWidth / 2 - 2 * squareSize
            okayY = viewHeight - squareSize / 2 - 2 * availableHeight / 3 // play with this
            cancelX = availableWidth / 2 + 2 * squareSize
            cancelY = viewHeight - squareSize / 2 - 2 * availableHeight / 3 // play with this
            
        }
        else {
            // landscape
            yOffset = viewHeight - (8 * squareSize)
            xOffset = viewWidth - (8 * squareSize) // - yOffset
            availableWidth = viewWidth - 8.5 * squareSize
            availableHeight = viewHeight
            okayX = availableWidth / 2
            okayY = availableHeight / 2
            cancelX = availableWidth / 2
            cancelY = availableHeight / 4
        }
        
        // tiles
        print("recentering board for \(viewWidth) x \(viewHeight)")
        for row in 0...7 {
            for col in 0...7 {
                if let square = squareWithName("\(col)\(row)"){
                    square.position = CGPointMake(CGFloat(col) * squareSize + xOffset, CGFloat(row) * squareSize + yOffset)
                    square.size = CGSizeMake(subSquareSize, subSquareSize)
                    if let piece = square.childNodeWithName("player1") as! SKSpriteNode? {
                        piece.size = CGSizeMake(pieceSize, pieceSize)
                    }
                    if let piece = square.childNodeWithName("player2") as! SKSpriteNode? {
                        piece.size = CGSizeMake(pieceSize, pieceSize)
                    }
                }
            }
        }
        
        // title graphic
        let maxHeight = availableHeight / 3
        let maxWidth = availableWidth - squareSize
        let titleWidth = min(maxWidth, 6 * maxHeight)
        let titleHeight = min(maxHeight, maxWidth / 6)
        let titlePosition = CGPointMake(availableWidth / 2, viewHeight - squareSize / 2 - titleHeight / 2)
        let titleSize = CGSizeMake(titleWidth, titleHeight)
        if let title = self.childNodeWithName("gameTitleLabel") as! SKSpriteNode? {
            title.size = titleSize
            title.position = titlePosition
        }
        
        // status label
        let statusPosition = CGPointMake(availableWidth / 2, viewHeight - squareSize / 2 - titleHeight / 2 - maxHeight)
        if let status = self.childNodeWithName("statusLabel") as! SKLabelNode? {
            status.position = statusPosition
        }
        
        // okay and cancel buttons
        let okayPosition = CGPointMake(okayX, okayY)
        if let okay = self.childNodeWithName("okayMoveButton") as! SKSpriteNode? {
            okay.position = okayPosition
        }
        
        let cancelPosition = CGPointMake(cancelX, cancelY)
        if let cancel = self.childNodeWithName("cancelMoveButton") as! SKSpriteNode? {
            cancel.position = cancelPosition
        }
   }
    
    func drawButtonsAndStatusLabel(){

        let viewHeight = self.view!.bounds.height
        let viewWidth = self.view!.bounds.width
        
        let verticalSpaceForEachVisualComponent: CGFloat
        
        if (viewHeight > viewWidth){
            // portrait
            let verticalSpaceAboveGameBoard = viewHeight - 8 * squareSizeMultiplier - 2 * CGFloat( ColorConstants.OffsetFromBottom)
            verticalSpaceForEachVisualComponent = verticalSpaceAboveGameBoard / 3
        }
        else{
            // landscape
            let verticalSpaceAboveGameBoard = viewWidth - 8 * squareSizeMultiplier - 2 * CGFloat( ColorConstants.OffsetFromBottom)
            verticalSpaceForEachVisualComponent = verticalSpaceAboveGameBoard / 3
        }

        
        let okayButtonHorizontalCenter = (viewWidth / 2 ) - 2 * squareSizeMultiplier
        let cancelButtonHorizontalCenter = (viewWidth / 2) + 2 * squareSizeMultiplier
        let okayAndCancelVerticalCenter = ColorConstants.OffsetFromBottom + ( visualElementHeight / 2) + squareSizeMultiplier * 8 // This puts the buttons above the game board.
        let okayAndCancelButtonHeight = 0.8 * min(verticalSpaceForEachVisualComponent, viewWidth / 4)
        let okayAndCancelButtonWidth = 2 * okayAndCancelButtonHeight
        
        squareSizeMultiplier = (min(viewHeight,viewWidth) - (min(viewHeight, viewWidth) % 9) ) / 9
        
        let okayMoveButton = SKSpriteNode(imageNamed: "Check Button.png")
        okayMoveButton.size = CGSizeMake(okayAndCancelButtonWidth, okayAndCancelButtonHeight)
        okayMoveButton.position = CGPointMake(okayButtonHorizontalCenter, okayAndCancelVerticalCenter)
        okayMoveButton.name = "okayMoveButton"
        self.addChild(okayMoveButton)
        okayMoveButton.hidden = true
        
        let cancelMoveButton = SKSpriteNode(imageNamed: "X Button.png")
        cancelMoveButton.size = CGSizeMake(okayAndCancelButtonWidth, okayAndCancelButtonHeight)
        cancelMoveButton.position = CGPointMake(cancelButtonHorizontalCenter, okayAndCancelVerticalCenter)
        cancelMoveButton.name = "cancelMoveButton"
        self.addChild(cancelMoveButton)
        cancelMoveButton.hidden = true
        
        let backButton = SKLabelNode(fontNamed: "Arial")
        backButton.text = "Back to Menu"
        backButton.fontSize = 0.35 * verticalSpaceForEachVisualComponent
        backButton.fontColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        backButton.name = "backButton"
        backButton.position = CGPointMake(backButton.fontSize * 3.3, viewHeight - 26)
        self.addChild(backButton)
        
        let currentPlayerLabelVerticalCenter = ColorConstants.OffsetFromBottom + boardHeight + 1.5 * visualElementHeight - squareSizeMultiplier
        
        currentPlayerLabel = SKLabelNode(fontNamed: "Arial")
        currentPlayerLabel.text = "Your Move"   /// CHANGE THIS TO ASSET
        currentPlayerLabel.fontSize = 0.5 * verticalSpaceForEachVisualComponent
        currentPlayerLabel.position = CGPointMake(viewWidth / 2, currentPlayerLabelVerticalCenter)
        currentPlayerLabel.fontColor = UIColor(white: 0, alpha: 1)
        currentPlayerLabel.name = "statusLabel"
        self.addChild(currentPlayerLabel)
        
        let gameTitleLabelVerticalCenter = currentPlayerLabelVerticalCenter + visualElementHeight
        
        let gameTitleWidth = currentPlayerLabel.fontSize * 9
        let gameTitleHeight = gameTitleWidth / 6
        
        gameTitleLabel = SKSpriteNode(imageNamed: "TitleText")
        gameTitleLabel.position = CGPointMake(viewWidth / 2, gameTitleLabelVerticalCenter)
        gameTitleLabel.size = CGSizeMake(gameTitleWidth, gameTitleHeight)
        gameTitleLabel.name = "gameTitleLabel"
        self.addChild(gameTitleLabel!)
    }
    
    
    
    func squareWithName(name: String) -> SKSpriteNode? {
        let square:SKSpriteNode? = self.childNodeWithName(name) as! SKSpriteNode?
        return square
    }
        
    
    
    // MARK: touchesBegan
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            
            let location = (touch as UITouch).locationInNode(self)
            let placeTouched = self.nodeAtPoint(location)
            // print(placeTouched.name)
            if let nameOfSpriteTouched = placeTouched.name{
                switch nameOfSpriteTouched {
                    
                    
                case "backButton":
                    print("Pressed Back Button")
                    pressedBackButton()
                    
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
    
    func startJump(touchedPiece: SKNode) {
        
        // ADD a check here to make sure that there are legal targets for a jump.
        let mark = playerNumber(currentPlayer)
        let coordinates = getSquareCoordinatesFromSquareName(touchedPiece.parent!.name!)
        let startingRow = coordinates.1 // recall that the name of the tile is in the order column then row
        let startingColumn = coordinates.0
        if let targets = currentViewedBoard.legalJumpTargetsFromTile(startingRow, column: startingColumn, mark: mark) {
            // if targets is not nil, then there are legal jump targets available for the selected piece            
            if (!targets.isEmpty) {
                gameState = GameState.WaitingForJumpTargetTile
                activePiece = touchedPiece
                // add code here for highlighting target tiles
                legalJumpTargetTiles = targets
                highlightTiles(legalJumpTargetTiles)
                touchedPiece.alpha = ColorConstants.OpacityConstant
                revealCancelMoveButton()
                userJumpSequence = [(startingRow,startingColumn)]
            }
        }
        
    }
    
    
    func highlightTiles(tiles: [(Int,Int)]) {
        //print("highlighting legal jump targets")
        for coordinatePair in tiles {
            let targetRow = coordinatePair.0 // Board methods return (row, column)
            let targetColumn = coordinatePair.1
            let targetSquare = squareWithName("\(targetColumn)\(targetRow)")
            targetSquare?.color = ColorConstants.HighlightedColor
        }
    }
    
    func displayJumpResult(targetRow: Int, targetColumn: Int) {
        //print("displaying result of jump")
        addPieceToBoard("\(targetColumn)\(targetRow)", player: currentPlayer)
        let newPiece = squareWithName("\(targetColumn)\(targetRow)")?.childNodeWithName(playerName(currentPlayer))
        newPiece?.alpha = ColorConstants.OpacityConstant
        let startingCoordinates = getSquareCoordinatesFromSquareName(activePiece!.parent!.name!)
        let startingRow = startingCoordinates.1
        let startingColumn = startingCoordinates.0
        resetHighlighting()
        let jumpedRow = (startingRow + targetRow) / 2
        let jumpedColumn = (startingColumn + targetColumn) / 2
        let jumpedPiece = squareWithName("\(jumpedColumn)\(jumpedRow)")!.childNodeWithName(playerName(adversaryPlayer(currentPlayer)))
        jumpedPiece?.alpha = ColorConstants.OpacityConstant
        gameState = GameState.WaitingForJumpCommitOrExtendedJumpSequence
        currentViewedBoard = currentViewedBoard.jumpSingleTile(startingRow, startingColumn: startingColumn, endingRow: targetRow, endingColumn: targetColumn, mark: playerNumber(currentPlayer))
        activePiece?.removeFromParent()
        activePiece = newPiece
        if let legalTargets = currentViewedBoard.legalJumpTargetsFromTile(targetRow, column: targetColumn, mark: playerNumber(currentPlayer)){
            legalJumpTargetTiles = legalTargets
        }
        else {
            legalJumpTargetTiles = []
        }
        highlightTiles(legalJumpTargetTiles)
        revealCommitButtons()
    }
    
    
    func displayAIJumpSequenceAnimated() {
        
        let locations = currentGameBoard.generatingMove!
        
        let startingRow = locations[0].0
        let startingColumn = locations[0].1
        
        let endingRow = locations[locations.count-1].0
        let endingColumn = locations[locations.count-1].1
        
        let startingSquare = squareWithName("\(startingColumn)\(startingRow)")!
        let movingPiece = startingSquare.childNodeWithName(playerName(currentPlayer))!
        let endingSquare = squareWithName("\(endingColumn)\(endingRow)")!
        
        // first we change the opacity of the piece at the initial coordinates,
        movingPiece.alpha = ColorConstants.OpacityConstant
        
        //we re-attach it to a new parent at the end of the jump sequence,
        movingPiece.removeFromParent()
        endingSquare.addChild(movingPiece)
        
        //and we change the locations to make it appear to still be located at the start.
        let locationVector = CGPointMake(startingSquare.position.x - endingSquare.position.x, startingSquare.position.y - endingSquare.position.y)
        let instantaneousMove = SKAction.moveTo(locationVector, duration: 0)
        movingPiece.runAction(instantaneousMove)
        
        // then for each successive pair of coordinates, we need to append to an array of SKActions
        // that will animate moving the active piece to the new jump location
        // we also compute the jumpedPiece and change it's opacity, and add it to a list of pieces for laeter deletion
        
        var actionSequence = [SKAction]()
        
        var jumpDuration = 0.0
        
        // change the opacity as the first action
        let fadeOutALittle = SKAction.fadeAlphaTo(CGFloat(ColorConstants.OpacityConstant), duration: 0)
        actionSequence.append(fadeOutALittle)
        
        let playSound = SKAction.playSoundFileNamed("clink.wav", waitForCompletion: false)
        
        var jumpedSquares = [(Int,Int)]()
        
        for k in 1...(locations.count-1) {
            
            let r = locations[k].0
            let c = locations[k].1
            
            let intermediateSquare = squareWithName("\(c)\(r)")!
            
            let newLocationVector = CGPointMake(intermediateSquare.position.x - endingSquare.position.x, intermediateSquare.position.y - endingSquare.position.y)
            
            let scaleUp = SKAction.scaleBy(CGFloat(1.25), duration: ColorConstants.PlacementDuration)
            let movePiece = SKAction.moveTo(newLocationVector, duration: ColorConstants.PlacementDuration)
            let scaleDown = SKAction.scaleBy(CGFloat(0.8), duration: ColorConstants.PlacementDuration)
            
            jumpDuration += 3 * ColorConstants.PlacementDuration
            
            actionSequence.append(scaleUp)
            actionSequence.append(movePiece)
            actionSequence.append(scaleDown)
            actionSequence.append(playSound)
            
            let jumpedRow = (r+locations[k-1].0)/2
            let jumpedColumn = (c+locations[k-1].1)/2
            
            jumpedSquares.append((jumpedRow,jumpedColumn))
        }
        
        // change the opacity back as the final action
        let fadeBackIn = SKAction.fadeAlphaTo(CGFloat(1), duration: 0)
        actionSequence.append(fadeBackIn)
        
        let jumpedPieces = [SKNode]()
        
        // change the opacity of the jumped pieces
        let firstOpacityReduction = SKAction.fadeAlphaTo(CGFloat(ColorConstants.OpacityConstant), duration: 0)
        let secondOpacityReduction = SKAction.fadeAlphaTo(CGFloat(0.9 * ColorConstants.OpacityConstant), duration: jumpDuration)
        let removal = SKAction.removeFromParent()
        let removalSequence = SKAction.sequence([firstOpacityReduction, secondOpacityReduction, removal])
        
        
        for jumpedSquare in jumpedSquares {
            let jumpedPiece = squareWithName("\(jumpedSquare.1)\(jumpedSquare.0)")!.childNodeWithName(playerName(adversaryPlayer(currentPlayer)))!
            jumpedPiece.runAction(removalSequence)
            //jumpedPieces.append(jumpedPiece)
        }
        
        // we run the SKAction sequence to animate the jumps
        let animationSequence = SKAction.sequence(actionSequence)
        movingPiece.runAction(animationSequence)
        
        // delete all the jumped pieces
        self.removeChildrenInArray(jumpedPieces)
        
    }
    
    func displayJumpResultAnimated(targetRow: Int, targetColumn: Int) {
        // animates the movement of a single jump
        
        // used below to make jumped pieces transluscent:
        let startingCoordinates = getSquareCoordinatesFromSquareName(activePiece!.parent!.name!)
        let startingRow = startingCoordinates.1
        let startingColumn = startingCoordinates.0
        
        // instead of adding a piece, we want to move the piece that was active
        //addPieceToBoard("\(targetColumn)\(targetRow)", player: currentPlayer)
        
        let targetSquare = squareWithName("\(targetColumn)\(targetRow)")!
        let sourceSquare = activePiece!.parent!
        
        // we need to detach the active piece from its old parent and add it to the target
        activePiece!.removeFromParent()
        targetSquare.addChild(activePiece!)
        // but we want the position to, temporarily, appear at the old location
        let movementVector = CGPointMake(sourceSquare.position.x - targetSquare.position.x, sourceSquare.position.y - targetSquare.position.y )
        let instantaneousMove = SKAction.moveTo(movementVector, duration: 0)
        activePiece?.runAction(instantaneousMove)
        
        // now we animate the movement to the new center
        let scaleUp = SKAction.scaleBy(CGFloat(1.25), duration: ColorConstants.PlacementDuration)
        let movePiece = SKAction.moveTo(CGPointMake(0, 0), duration: ColorConstants.PlacementDuration)
        let scaleDown = SKAction.scaleBy(CGFloat(0.8), duration: ColorConstants.PlacementDuration)
        let playSound = SKAction.playSoundFileNamed("clink.wav", waitForCompletion: false)
        let sequence = SKAction.sequence([scaleUp, movePiece, scaleDown, playSound])
        activePiece!.runAction(sequence)
        

        resetHighlighting()
        let jumpedRow = (startingRow + targetRow) / 2
        let jumpedColumn = (startingColumn + targetColumn) / 2
        let jumpedPiece = squareWithName("\(jumpedColumn)\(jumpedRow)")!.childNodeWithName(playerName(adversaryPlayer(currentPlayer)))
        jumpedPiece?.alpha = ColorConstants.OpacityConstant
        gameState = GameState.WaitingForJumpCommitOrExtendedJumpSequence
        currentViewedBoard = currentViewedBoard.jumpSingleTile(startingRow, startingColumn: startingColumn, endingRow: targetRow, endingColumn: targetColumn, mark: playerNumber(currentPlayer))
        if let legalTargets = currentViewedBoard.legalJumpTargetsFromTile(targetRow, column: targetColumn, mark: playerNumber(currentPlayer)){
            legalJumpTargetTiles = legalTargets
        }
        else {
            legalJumpTargetTiles = []
        }
        highlightTiles(legalJumpTargetTiles)
        revealCommitButtons()
    }
    
    func addPieceToBoard(squareName: String, player: Players){
        if let square = squareWithName(squareName) {
            let gamePiece = SKSpriteNode(imageNamed: pieceImage(player))
            gamePiece.size = CGSizeMake(CGFloat(pieceSize), CGFloat(pieceSize))
            gamePiece.name = playerName(player)
            
            square.addChild(gamePiece)
            
        }
    }
    
    func addPieceToBoardAnimated(squareName: String, player: Players){
        if let square = squareWithName(squareName) {
            let gamePiece = SKSpriteNode(imageNamed: pieceImage(player))
            gamePiece.size = CGSizeMake(pieceSize*1.25, pieceSize*1.25)
            gamePiece.name = playerName(player)
            gamePiece.position = CGPointMake(square.size.width, square.size.height)
            
            square.addChild(gamePiece)
            let movePiece = SKAction.moveTo(CGPointMake(0,0), duration: ColorConstants.PlacementDuration)
            let scaleDown = SKAction.scaleTo(CGFloat(0.8), duration: ColorConstants.PlacementDuration)
            //let disappear = SKAction.removeFromParent()
            let playSound = SKAction.playSoundFileNamed("clink.wav", waitForCompletion: false)
            let sequence = SKAction.sequence([movePiece, scaleDown, playSound])
            gamePiece.runAction(sequence)
            activePiece = gamePiece
        }
    }
    
    func resetHighlighting() {
        //activePiece?.alpha = CGFloat(1) // resets opacity of active piece
        for r in 0...7 {
            for c in 0...7 {
                squareWithName("\(c)\(r)")?.color = ColorConstants.NormalColor
            }
        }
        
    }
    
    func revealCancelMoveButton() {
        self.childNodeWithName("cancelMoveButton")?.hidden = false
    }
    
    func revealCommitButtons() {
        self.childNodeWithName("okayMoveButton")?.hidden = false
        self.childNodeWithName("cancelMoveButton")?.hidden = false
    }
    
    func hideCommitButtons() {
        self.childNodeWithName("okayMoveButton")?.hidden = true
        self.childNodeWithName("cancelMoveButton")?.hidden = true
    }
    
    func submitCurrentViewAsMove() {
        if (gameState == GameState.WaitingForJumpCommitOrExtendedJumpSequence) {
            currentGameBoard = currentGameBoard.jumpTiles(userJumpSequence)
        }
        else {
            currentGameBoard = currentViewedBoard // commits the current move
        }
        legalJumpTargetTiles = []
        activePiece = nil
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func adversaryPlayer(player: Players) -> Players {
        switch player {
        case .player1:
            return .player2
        case .player2:
            return .player1
        }
    }
    
    func playerName(player: Players) -> String {
        if (player == .player1) {return "player1"}
        if (player == .player2) {return "player2"}
        else {return ""}
    }
    
    func playerNumber(player: Players) -> Int {
        if (player == .player1) { return 1 }
        if (player == .player2) { return 2 }
        else { return 0 } // This should never happen.
    }
    
    func pieceImage(piece: Players) -> String {
        if (piece == .player1) {return player1Piece}
        if (piece == .player2) {return player2Piece}
        else {return ""}
    }
    

    
    func applyCurrentGameBoard() {
        clearPiecesFromView()
        for r in 0...7 {
            for c in 0...7 {
                let v = currentGameBoard.getValue(r, column: c)
                if (v == 1) { addPieceToBoard("\(c)\(r)", player: Players.player1) }
                if (v == 2) { addPieceToBoard("\(c)\(r)", player: Players.player2) }
            }
        }
    }
    
    func displayGameState() {
        if (gameState == GameState.ReadyForPlayerMove) {
            currentPlayerLabel.text = "Your Move"   // Change this to ASSET
            currentPlayerLabel.fontColor = UIColor.blackColor()
            //print(ai.ratePosition(currentGameBoard))
        }
        if (gameState == GameState.WaitingForAI) {
            currentPlayerLabel.text = "Thinking"  // Change this to ASSET
            currentPlayerLabel.fontColor = UIColor.blueColor()
        }
        if (gameState == GameState.GameOver) {
            let message: String
            let messageColor = UIColor.blackColor()
            if (currentGameBoard.win == 1) {message = "You Win!"}
            else {message = "Game Over"}
            currentPlayerLabel.text = message   // Change this to ASSET
            currentPlayerLabel.fontColor = messageColor
        }
    }
    
    func checkWhetherCurrentPlayerHasWon() {
        if (currentGameBoard.win == playerNumber(currentPlayer)) {
            //print("Player has just won!")
            gameState = GameState.GameOver
            let s = currentGameBoard.winLocation
            //print("from the currentBoard winLocation:")
            //print(currentGameBoard.winLocation!)  // what's wrong here?  upwrapping nil?
            //print("attempting to highlight tiles:")
            //print([s![0],s![1],s![2],s![3],s![4]])
            highlightTiles([s![0],s![1],s![2],s![3],s![4]])
            //alertGameOver()
        }
    }
    
    func alertGameOver() {
        let alert = UIAlertView(title: "GAME OVER", message: "Player \(playerNumber(currentPlayer)) wins!", delegate: nil, cancelButtonTitle: "Okay")
        alert.show()
    }
    
    func checkForDraw() {
        let numberOfUsedLocations = currentGameBoard.usedLocations[1]!.count + currentGameBoard.usedLocations[2]!.count
        if (numberOfUsedLocations == 64) {
            gameState = GameState.GameOver
            alertDraw("No legal moves remaining.")
        }
        else {
            var numberOfRepititions = 0
            for board in boardHistory {
                if (currentGameBoard.isEquivalentTo(board)) {
                    numberOfRepititions += 1
                }
            }
            if (numberOfRepititions >= 3) {
                gameState = GameState.GameOver
                alertDraw("Reached same board position three times.")
            }
            

        }
    }
    
    func pressedBackButton() {
        print("Unwinding Segue")
        self.viewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func alertDraw(message: String) {
        let alert = UIAlertView(title: "GAME OVER", message: "Draw: \(message)", delegate: nil, cancelButtonTitle: "Okay")
        alert.show()
    }

    

    func submitMoveToAI(board: FastBoard) {
        if (gameState == GameState.GameOver) {return}
        // multithreading
        let qualityOfService = Int(QOS_CLASS_USER_INITIATED.rawValue)
        dispatch_async(dispatch_get_global_queue(qualityOfService, 0)) {
            let newBoard = ai.getMove(self.currentGameBoard, ply: self.aiPly) // This was just changed!
            dispatch_async(dispatch_get_main_queue()) {
                if (self.gameState == GameState.WaitingForAI) {
                    self.currentGameBoard = newBoard
                    self.currentViewedBoard = newBoard
                    if (newBoard.generatingMoveIndices.count == 1) {
                        let location = newBoard.generatingMoveIndices[0]
                        // ai move was placing a piece
                        let column = location % 8
                        let row = (location - column) / 8
                        self.addPieceToBoardAnimated("\(column)\(row)", player: currentPlayer)
                    }
                    else {
                        // ai move was a jump or jump sequence
                        self.displayAIJumpSequenceAnimated()
                    }
                    
                    switchUser()
                    if (self.gameState != GameState.GameOver)  {
                        self.gameState = GameState.ReadyForPlayerMove
                    }
                }
                
            }
        }
    }

    
    func clearPiecesFromView() {
        resetHighlighting()
        for r in 0...7 {
            for c in 0...7 {
                squareWithName("\(c)\(r)")!.removeAllChildren()
                }
            }
        }
    

}  // This is the end of the GameScene Class definition.  ???????


    
    func getSquareCoordinatesFromSquareName(squareName: String) -> (Int, Int) {
        var nameIntegers = [Int]()
        for i in squareName.characters {
            let nameCharacter = String(i)
            let nameInteger = Int(nameCharacter)
            nameIntegers.append(nameInteger!)
        }
        let col = nameIntegers[0]
        let row = nameIntegers[1]
        return (col, row)
        
    }





func switchUser(){
    switch currentPlayer {
    case .player1:
        currentPlayer = Players.player2
        
    case .player2:
        currentPlayer = Players.player1
    }
}



struct ColorConstants {
    static let NormalColor = SKColor.purpleColor()
    static let HighlightedColor = SKColor.yellowColor()
    //static let HighlightedColor = SKColor.init(red: 255, green: 215, blue: 0, alpha: 1)  // gold1
    static let OpacityConstant = CGFloat(0.4)
    static let PlacementDuration = 0.25
    static let OffsetFromBottom = CGFloat(50)
    static let OffsetFromTop = CGFloat(10)
    static let WallpaperOpacity = CGFloat(0.2)
    //static let BackgroundColor = UIColor(white: 1, alpha: 1)  // White Background
    //static let BackgroundColor = UIColor(red: 255, green: 215, blue: 0, alpha: 1) // Gold Background
    //static let BackgroundColor = UIColor(red: 100, green: 59, blue: 15, alpha: 1) // Sepia? Background
    static let BackgroundColor = UIColor(red: 112, green: 66, blue: 20, alpha: 1) // Another Sepia? Background

}

enum Players{
    case player1
    case player2
}

enum GameState {
    case ReadyForPlayerMove
    case WaitingForPlacementCommit
    case WaitingForJumpTargetTile
    case WaitingForJumpCommitOrExtendedJumpSequence
    case WaitingForAI
    case GameOver
}

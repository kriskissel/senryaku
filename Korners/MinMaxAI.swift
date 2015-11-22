//
//  MinMaxAI.swift
//  Korners
//
//  Created by Kris Kissel on 10/17/15.
//  Copyright © 2015 Kris Kissel. All rights reserved.
//

import Foundation



class MiniMaxAI {
    
    let aiMark: Int
    let humanMark: Int
    let tilesCoefficient: Int
    let adjacenciesCoefficient: Int
    let protoCornersCoefficient: Int
    
    init(aiMark: Int) {
        tilesCoefficient = 1
        adjacenciesCoefficient = 1
        self.protoCornersCoefficient = 100
        self.aiMark = aiMark
        self.humanMark = 3 - aiMark
    }
    
    init(aiMark: Int, tilesCoeff: Int, adjacenciesCoeff: Int, protoCornersCoeff: Int){
        tilesCoefficient = tilesCoeff
        adjacenciesCoefficient = adjacenciesCoeff
        protoCornersCoefficient = protoCornersCoeff
        self.aiMark = aiMark
        self.humanMark = 3 - aiMark
    }
    
    func ratePosition(board: FastBoard) -> Float {
        if (board.win == aiMark) { return Float.infinity }
        if (board.win == humanMark) { return -Float.infinity }
        
        //        let score = Float(board.numberOfUsedLocations[mark]! - board.numberOfUsedLocations[adversaryMark]!) * self.tilesCoefficient + Float(board.adjacencies[mark]! - board.adjacencies[adversaryMark]!) * self.adjacenciesCoefficient + Float(board.oneGaps[mark]! - board.oneGaps[adversaryMark]!) * self.oneGapsCoefficient + Float(board.protoCorners[mark]! - board.protoCorners[adversaryMark]!) * self.protoCornersCoefficient
        
        // without oneGaps or protoCorners
        let score = (board.usedLocations[aiMark]!.count - board.usedLocations[humanMark]!.count) * self.tilesCoefficient + (board.adjacencies[aiMark] - board.adjacencies[humanMark]) * self.adjacenciesCoefficient + (board.protoCorners[aiMark] - board.protoCorners[humanMark]) * self.protoCornersCoefficient
        
        return Float( score )
    }
    
    func minimaxSearch(board: FastBoard, ply: Int, humanSimulation: Bool) -> (Float, FastBoard) {
        // if at max search depth:
        if (ply == 0) {
            return (ratePosition(board),board)
        }
        var bestScore: Float
        var boardForBestScore = FastBoard()
        if humanSimulation {
            bestScore = Float.infinity
            let childBoards = board.preferredChildBoards(humanMark)
            for child in childBoards {
                if (child.win == aiMark) {
                    //print("win detected for human")
                    return (-Float.infinity, child)
                }
                let searchResult = minimaxSearch(child, ply: ply - 1, humanSimulation: false)
                let score = searchResult.0
                if (score <= bestScore) {
                    bestScore = score
                    boardForBestScore = child
                }
            }
        }
        else {
            bestScore = -Float.infinity
            let childBoards = board.preferredChildBoards(aiMark)
            for child in childBoards {
                if (child.win == aiMark) {
                    //print("win detected for ai")
                    return (Float.infinity, child)
                }
                let searchResult = minimaxSearch(child, ply: ply - 1, humanSimulation: true)
                let score = searchResult.0
                if (score >= bestScore) {
                    bestScore = score
                    boardForBestScore = child
                }
            }
        }
        
        //print("MiniMaxAI returning projected score of \(bestScore) at depth \(ply) on board:")
        //print(boardForBestScore)
        return (bestScore,boardForBestScore)
    }
    
    func getMove(board: FastBoard, ply: Int) -> FastBoard {
        
        // The following line uses a random move selector to provide AI moves for the easiest game level.
        //if (ply == 0) { return randomResponse(board) }
        
        if let winningBoard = checkForWinningMove(board){
            return winningBoard
        }
        
        let totalUsedLocations = board.usedLocations[1]!.count + board.usedLocations[2]!.count
        
        if (totalUsedLocations <= 2) {
            return randomizeOpening(board)!
        }
        
        if let interruptThreeInARow = findThreeInARow(board) {
            return interruptThreeInARow
        }
        
        let searchResult = minimaxSearch(board, ply: ply, humanSimulation: false).1
        var numberOfHumanProtoCornersInSearchResult = 0
        var numberOfHumanProtoCornersInBoard = 0
        print("number of human protoCorners in Search Result: \(numberOfHumanProtoCornersInSearchResult)")
        print("number of human protoCorners in previous board: \(numberOfHumanProtoCornersInBoard)")
        for r in 0...7 {
            for c in 0...7 {
                numberOfHumanProtoCornersInBoard += board.countProtoCornersThroughTile(r, column: c , mark: humanMark)
                numberOfHumanProtoCornersInSearchResult += searchResult.countProtoCornersThroughTile(r, column: c , mark: humanMark)
            }
        }
        
        if (numberOfHumanProtoCornersInBoard == 0){
            if (totalUsedLocations <= 6){
                print("totalUsedLocations at most 6")
                if let miniCornerBlockingMove = blockMiniCorner(board, alternateBoard: searchResult){
                    print("move found to block mini corner")
                    return miniCornerBlockingMove
                }
            }
        }
        
        if (numberOfHumanProtoCornersInBoard > numberOfHumanProtoCornersInSearchResult || numberOfHumanProtoCornersInSearchResult == 0) {
            return searchResult
        }
        else {
            return blockingMove(board)!
        }
    }
    
    func checkForWinningMove(board: FastBoard) -> FastBoard? {
        for r in 0...7 {
            for c in 0...7 {
                if (board.getValue(r, column: c) == 0) {
                    let newBoard = board.placePiece(r, column: c, mark: aiMark)
                    if (newBoard.win == aiMark) {
                        return newBoard
                    }
                }
            }
        }
        return nil
    }
    
    func blockMiniCorner(board: FastBoard, alternateBoard: FastBoard) -> FastBoard? {
        for r in 0...7 {
            for c in 0...7 {
                if (board.checkForMiniCornerGapAtTile(r, column: c, mark: humanMark) && alternateBoard.checkForMiniCornerGapAtTile(r, column: c, mark: humanMark)) {
                    return board.placePiece(r, column: c , mark: aiMark)
                }
            }
        }
        return nil
    }
    
    func blockingMove(board: FastBoard) -> FastBoard? {
        for r in 0...7 {
            for c in 0...7 {
                if (board.countProtoCornersThroughTile(r, column: c , mark: humanMark) > 0 && board.getValue(r, column: c ) == 0) {
                    return board.placePiece(r, column: c , mark: aiMark)
                }
            }
        }
        return nil // this should never fire when it is actually used    }
    }
    
    func randomizeOpening(board: FastBoard) -> FastBoard? {
        
        let n = board.usedLocations[1]!.count + board.usedLocations[2]!.count
        if (n == 0) {
            let k = Int(arc4random_uniform(UInt32(4)))
            let l = Int(arc4random_uniform(UInt32(4)))
            let r = 2 + k
            let c = 2 + l
            return board.placePiece(r, column: c , mark: aiMark)
        }
        if ( n <= 2 ) {
            var possiblePlacementLocations = [(Int,Int)]()
            let usedLocations = Array( board.usedLocations[1]!) + Array( board.usedLocations[2]!)
            for location in usedLocations {
                let column = location % 8
                let row = (location - column) / 8
                for difference in [(2,0),(2,1),(2,2),(2,-1),(2,-2),(-2,-2),(-2,-1),(-2,0),(-2,1),(-2,2),(-1,2),(0,2),(1,2),(-1,-2),(0,-2),(1,-2)] {
                    let r = row + difference.0
                    let c = column + difference.1
                    if (r >= 2 && r <= 5 && c >= 2 && c <= 5 &&  board.getValue(r, column: c) == 0) {
                        possiblePlacementLocations.append((r,c))
                    }
                }
            }
            let choice = Int(arc4random_uniform(UInt32(possiblePlacementLocations.count)))
            return board.placePiece(possiblePlacementLocations[choice].0, column: possiblePlacementLocations[choice].1, mark: aiMark)
        }
        return nil
    }
    
    func findThreeInARow(board: FastBoard) -> FastBoard? {
        if (board.usedLocations[humanMark]!.count == 3 && board.adjacencies[humanMark] == 2) {
            var rowTotal = 0
            var columnTotal = 0
            for row in 0...7 {
                for column in 0...7 {
                    if (board.getValue(row, column: column) == humanMark){
                        rowTotal += row
                        columnTotal += column 
                    }
                }
            }
            let midRow = rowTotal / 3
            let midColumn = columnTotal / 3
            if (midRow > 0 && board.getValue(midRow - 1, column: midColumn) == 0) {
                return board.placePiece(midRow - 1, column: midColumn, mark: aiMark)
            }
            if (midRow < 7 && board.getValue(midRow + 1, column: midColumn) == 0) {
                return board.placePiece(midRow + 1, column: midColumn, mark: aiMark)
            }
            if (midColumn > 0 && board.getValue(midRow, column: midColumn - 1) == 0) {
                return board.placePiece(midRow, column: midColumn - 1, mark: aiMark)
            }
            if (midColumn < 7 && board.getValue(midRow, column: midColumn + 1) == 0) {
                return board.placePiece(midRow, column: midColumn + 1, mark: aiMark)
            }
        }
        return nil
    }
    
    func randomResponse(board: FastBoard) -> FastBoard {
        // This method is used to provide a weak opponent for level 1.
        // It generates all legal (preferred) moves for the current board, thens scores each with
        // the ratePosition method.  Then it sorts the moves in decreasing order of position rating.
        // It randomly selects one of the two (I'LL NEED TO PLAY WITH THIS NUMBER) of moves
        // as its response.
        
        
        if (board.usedLocations[1]!.count + board.usedLocations[2]!.count < 3) {
            return randomizeOpening(board)!
        }
        
        
        
        // let's throw in an extra 75% chance of using a blocking move
        let blockMove: FastBoard?
        if (board.protoCorners[humanMark] > 0) {
            blockMove = blockingMove(board)
            let p = Int(arc4random_uniform(UInt32(Int(4))))
            if (p < 3) {
                return blockMove!
            }
        }
        
        
        let childBoards = board.preferredChildBoards(aiMark)
        
        
        
        var scoredChildBoards = [(Float, FastBoard)]()
        for child in childBoards {
            scoredChildBoards.append((ratePosition(child), child))
        }
        scoredChildBoards.sortInPlace { $0.0 > $1.0 }
        
        //let l = ceil( Float(scoredChildBoards.count) / 4.0 )
        let l: Int
        if (scoredChildBoards.count > 1) {
            l = 2
        }
        else {
            l = 1
        }
        let k = Int(arc4random_uniform(UInt32(Int(l))))
        
        return scoredChildBoards[k].1
    }

    
}
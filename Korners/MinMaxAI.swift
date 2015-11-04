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
    let tilesCoefficient: Float
    let adjacenciesCoefficient: Float
    
    init(aiMark: Int) {
        tilesCoefficient = Float(1)
        adjacenciesCoefficient = Float(1)
        //oneGapsCoefficient = 0 // used to be 3, now testing if we can do without
        //protoCornersCoefficient = 100
        self.aiMark = aiMark
        self.humanMark = 3 - aiMark
    }
    
    func ratePosition(board: FastBoard) -> Float {
        if (board.win == aiMark) { return Float.infinity }
        if (board.win == humanMark) { return -Float.infinity }
        
        //        let score = Float(board.numberOfUsedLocations[mark]! - board.numberOfUsedLocations[adversaryMark]!) * self.tilesCoefficient + Float(board.adjacencies[mark]! - board.adjacencies[adversaryMark]!) * self.adjacenciesCoefficient + Float(board.oneGaps[mark]! - board.oneGaps[adversaryMark]!) * self.oneGapsCoefficient + Float(board.protoCorners[mark]! - board.protoCorners[adversaryMark]!) * self.protoCornersCoefficient
        
        // without oneGaps or protoCorners
        let score = Float(board.usedLocations[aiMark]!.count - board.usedLocations[humanMark]!.count) * self.tilesCoefficient + Float(board.adjacencies[aiMark] - board.adjacencies[humanMark]) * self.adjacenciesCoefficient
        
        return score
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
        
        if let winningBoard = checkForWinningMove(board){
            return winningBoard
        }
        
        let totalUsedLocations = board.usedLocations[1]!.count + board.usedLocations[2]!.count
        
        if (totalUsedLocations <= 2) {
            return randomizeOpening(board)!
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

    
}
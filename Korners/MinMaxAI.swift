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
        if (numberOfHumanProtoCornersInBoard > numberOfHumanProtoCornersInSearchResult || numberOfHumanProtoCornersInSearchResult == 0) {
            return searchResult
        }
        else {
            return blockingMove(board)!
        }
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
    
}
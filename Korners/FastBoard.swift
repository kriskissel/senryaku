//
//  FastBoard.swift
//  Korners
//
//  Created by Kris Kissel on 10/9/15.
//  Copyright © 2015 Kris Kissel. All rights reserved.
//

import Foundation


// MARK: class constants

private let winSites = buildWinSites(true)
let protoCornerStes = buildWinSites(false)

private let adjacencySites = buildAdjacencySites()
private let jumpTargets = buildJumpTargets()


// MARK: FastBoard Definition

class FastBoard : CustomStringConvertible {
    
    private var boardArray: [Int]
    var generatingMove: [(row: Int, column: Int)]? {
        if generatingMoveIndices.count > 0 {
            var output = [(row: Int, column: Int)]()
            for location in generatingMoveIndices {
                output.append(arrayIndexToCoordinates(location))
            }
            return output
        }
        return nil
    }
    var generatingMoveIndices: [Int]
    var usedLocations: [Int: Set<Int>]
    var adjacencies: [Int]
    var win: Int // records the mark of whoever has won
    var withinOneOfPreviousPlacement: Set<Int>
    var winLocation: [(row: Int, column: Int)]?
    var description: String {
        var result = ""
        for r in 0...7 {
            for c in 0...7 {
                result = result + String(boardArray[8*r+c])
            }
            result = result + ("\n")
        }
        //result += "used locations for player 1: \(usedLocations[1]!) \n"
        //result += "used locations for player 2; \(usedLocations[2]!) \n"
        result += "adjacencies for player 1: \(adjacencies[1]) \n"
        result += "adjacencies for player 2: \(adjacencies[2]) \n"
        result += "win: \(win) \n"
        //result += "win location: \n"
        //result += String(winLocation)
        
        return result
    }
    
    init () {
        boardArray = [  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ]
        usedLocations = [Int: Set<Int>]()
        usedLocations[1] = Set<Int>()
        usedLocations[2] = Set<Int>()
        adjacencies = [0,0,0]
        win = 0
        withinOneOfPreviousPlacement = Set<Int>()
        generatingMoveIndices = [Int]()
    }
    
    init(board: FastBoard) {
        self.boardArray = Array(board.boardArray)
        self.usedLocations = [Int: Set<Int>]()
        self.usedLocations[1] = Set( Array( board.usedLocations[1]! ) )
        self.usedLocations[2] = Set( Array( board.usedLocations[2]! ) )
        self.adjacencies = Array( board.adjacencies )
        self.win = 0 // we skip a lookup by assuming that winning boards will have no children
        self.withinOneOfPreviousPlacement = Set(board.withinOneOfPreviousPlacement)
        self.generatingMoveIndices = Array( board.generatingMoveIndices )
    }
    
    // MARK: Placement
    
    func placePiece(index: Int, mark: Int) -> FastBoard {
        // We're going to skip checking whether this is legal in order to speed things up.
        let newBoard = FastBoard(board: self)
        newBoard.boardArray[index] = mark
        newBoard.usedLocations[mark]!.insert(index)
        for tile in adjacencySites[index] {
            if (newBoard.boardArray[tile] == mark) { newBoard.adjacencies[mark] += 1 }
            else if (newBoard.boardArray[tile] == 0) { newBoard.withinOneOfPreviousPlacement.insert(tile) }
        }
        newBoard.win = newBoard.checkForWin(index: index, mark: mark)
        newBoard.generatingMoveIndices = [index]
        return newBoard
    }
    
    func placePiece(row: Int, column: Int, mark: Int) -> FastBoard{
        return placePiece(8*row + column, mark: mark)
    }
    
    // MARK: Jumping
    
    // convenience for UI
    func jumpSingleTile(startingRow: Int, startingColumn: Int, endingRow: Int, endingColumn: Int, mark: Int) -> FastBoard {
        return jumpSingleTile(8 * startingRow + startingColumn, endingIndex: 8 * endingRow + endingColumn)
    }
    
    // convenience for UI
    func jumpTiles(locations: [(Int,Int)]) -> FastBoard {
        var locationIndices = [Int]()
        for location in locations {
            locationIndices.append(8 * location.0 + location.1)
        }
        return jumpTiles(locationIndices)
    }
    
    
    
    func jumpSingleTile(startingIndex: Int, endingIndex: Int) -> FastBoard {
        let newBoard = FastBoard(board: self)
        let mark = self.boardArray[startingIndex]
        let opponentMark = 3 - mark
        let jumpedIndex = (startingIndex + endingIndex) / 2
        newBoard.boardArray[startingIndex] = 0
        newBoard.boardArray[endingIndex] = mark
        newBoard.boardArray[jumpedIndex] = 0 // the jumped tile index is, amazingly, the average of the starting and ending tile indices
        newBoard.usedLocations[mark]!.insert(endingIndex)
        newBoard.usedLocations[mark]!.remove(startingIndex)
        newBoard.usedLocations[opponentMark]!.remove(jumpedIndex)
        for tile in adjacencySites[startingIndex] {
            if (self.boardArray[tile] == mark) {
                newBoard.adjacencies[mark] -= 1
                //print("lost adjacency at \(tile), adjacency count now \(newBoard.adjacencies[mark])")
            }
        }
        for tile in adjacencySites[endingIndex] {
            if (self.boardArray[tile] == mark) {
                newBoard.adjacencies[mark] += 1
                //print("gained adjacency at \(tile), adjacency count now \(newBoard.adjacencies[mark])")
            }
        }
        for tile in adjacencySites[jumpedIndex] {
            if (self.boardArray[tile] == opponentMark ) {
                newBoard.adjacencies[opponentMark] -= 1
                //print("opponent lost adjacency at \(tile), adjacency count now \(newBoard.adjacencies[opponentMark])")
            }
        }
        newBoard.win = newBoard.checkForWin(index: endingIndex, mark: mark)
        newBoard.generatingMoveIndices = [startingIndex, endingIndex]
        return newBoard
    }
    
    func jumpTiles(locations: [Int]) -> FastBoard {
        var result = self
        for k in 0...(locations.count - 2) {
            result = result.jumpSingleTile(locations[k], endingIndex: locations[k+1])
        }
        result.generatingMoveIndices = locations
        return result
    }
    
    

    func getValue(row: Int, column: Int) -> Int {
        return boardArray[8*row + column]
    }
    
    // Redo this with a lookup dictionary?
    func legalJumpTargetsFromTile(row: Int, column: Int, mark: Int) -> [(Int,Int)]? {
        if (getValue(row, column: column) != mark) { return nil }
        else {
            let adversaryMark = 3 - mark
            var result = [(Int, Int)]()
            if (row > 1) {
                if (getValue(row-2, column: column) == 0 && getValue(row-1, column: column) == adversaryMark) { result.append((row-2,column)) }
                if (column > 1 && getValue(row-2, column: column-2) == 0 && getValue(row-1, column: column-1) == adversaryMark) { result.append((row-2,column-2)) }
                if (column < 6 && getValue(row-2, column: column+2) == 0 && getValue(row-1, column: column+1) == adversaryMark) { result.append((row-2, column+2)) }
            }
            if (row < 6) {
                if (getValue(row+2, column: column) == 0 && getValue(row+1, column: column) == adversaryMark) { result.append((row+2,column)) }
                if (column > 1 && getValue(row+2, column: column-2) == 0 && getValue(row+1, column: column-1) == adversaryMark) { result.append((row+2,column-2)) }
                if (column < 6 && getValue(row+2, column: column+2) == 0 && getValue(row+1, column: column+1) == adversaryMark) { result.append((row+2, column+2)) }
            }
            if (column > 1 && getValue(row, column: column-2) == 0 && getValue(row, column: column-1) == adversaryMark) { result.append((row, column-2)) }
            if (column < 6 && getValue(row, column: column+2) == 0 && getValue(row, column: column+1) == adversaryMark) { result.append((row, column+2)) }
            if result.isEmpty { return nil }
            else { return result }
        }
    }
    
    func isEquivalentTo(board: FastBoard) -> Bool {
        var result = true
        for r in 0...7 {
            for c in 0...7 {
                if (getValue(r, column: c) != board.getValue(r, column: c)) {
                    result = false
                }
            }
        }
        return result
    }
    
    func legalSingleJumpChildBoardsFromTile(index: Int, mark: Int) -> [FastBoard] {
        let adversaryMark = 3-mark
        var legalJumpChildren = [FastBoard]()
        // redo this with indices instead of coordinates
        // prebuild a dictionary of sites so that we won't need to do as many comparisons inside the loop
        let targetTiles = jumpTargets[index]
        for targetIndex in targetTiles {
            if (boardArray[targetIndex] == 0 && boardArray[ (index + targetIndex) / 2 ] == adversaryMark) {
                legalJumpChildren.append(self.jumpSingleTile(index, endingIndex: targetIndex))
            }
        }
        return legalJumpChildren
    }
    
    func childBoardsOfJumpSequencesFromTile(index: Int, mark: Int) -> [FastBoard] {
        var childBoards = [FastBoard]()
        
        var stack = [([Int],FastBoard)]() // the first element of the tuple records the jump sequences
        
        let firstRoundOfJumps = legalSingleJumpChildBoardsFromTile(index, mark: mark) // this is all of the child boards that can be reached by a single jump from the starting location
        
        for b in firstRoundOfJumps {
            childBoards.append(b)
            stack.append((b.generatingMoveIndices, b))
        }
        
        // now we use the stack to implement a DFS approach to generating jump sequences
        while (!stack.isEmpty) {
            let b = stack.popLast()!
            // find the children that can be reached by continuing a jump
            let childrenOfb = b.1.legalSingleJumpChildBoardsFromTile(b.0.last!, mark: mark)  // b.0 is the jump sequence up to that point, b.0.last! is the last location reached by jumping.
            for c in childrenOfb {
                let jumpSequence = b.0 + [c.generatingMoveIndices.last!]
                c.generatingMoveIndices = jumpSequence
                childBoards.append(c)
                stack.append((jumpSequence,c ))
            }
        }
        return childBoards
    }
    
    func jumpChildren(mark: Int) -> [FastBoard] {
        var children = [FastBoard]()
        for startingPosition in self.usedLocations[mark]! {
            children += childBoardsOfJumpSequencesFromTile(startingPosition, mark: mark)
        }
        return children
    }
    
    func preferredChildBoards(mark: Int) -> [FastBoard] {
        var result = self.jumpChildren(mark)
        for location in withinOneOfPreviousPlacement {
            if (boardArray[location] == 0) { result.append(self.placePiece(location, mark: mark)) }
        }
        return result
    }
    
    func legalToJump(startingRow: Int, startingColumn: Int, endingRow: Int, endingColumn: Int, mark: Int) -> Bool {
        if (abs(abs(startingRow - endingRow) - 1) != 1) {return false}
        if (abs(abs(startingColumn - endingColumn) - 1) != 1) {return false}
        if (startingRow == endingRow && startingColumn == endingColumn) {return false}
        let jumpedRow = (startingRow + endingRow)/2
        let jumpedColumn = (startingColumn + endingColumn)/2
        let adversaryMark = 3-mark
        if (getValue(startingRow, column: startingColumn) == mark && getValue(endingRow, column: endingColumn) == 0 && getValue(jumpedRow, column: jumpedColumn) == adversaryMark) {
            return true
        }
        else { return false }
    }
    
    func isEmptyTile(row: Int, column: Int) -> Bool {
        if (boardArray[coordinatesToArrayIndex(row, column: column)]==0) { return true }
        else { return false }
    }
    
    
    // MARK: Board data maintenence utilities
    
    func checkForWin(index index: Int, mark: Int) -> Int {
        //print("checking for win by player \(mark) at tile index \(index)")
        for site in winSites[index]! {
            //print("checking win site: \(site)")
            //print([boardArray[site[0]],boardArray[site[1]], boardArray[site[2]], boardArray[site[3]]])
            if ([boardArray[site[0]],boardArray[site[1]], boardArray[site[2]], boardArray[site[3]]] == [mark, mark, mark, mark]) {
                //print("found a win")
                self.winLocation = [arrayIndexToCoordinates(site[0]), arrayIndexToCoordinates(site[1]), arrayIndexToCoordinates(site[2]), arrayIndexToCoordinates(site[3]), arrayIndexToCoordinates(index)]
                //print("setting the winLocation to:")
                //print(self.winLocation!)
                return mark
            }
        }
        return 0
    }
    
    func countProtoCornersThroughTile(row: Int, column: Int, mark: Int) -> Int {
        var count = 0
        let arrayIndex = coordinatesToArrayIndex(row, column: column)
        let sitesToCheck = protoCornerStes[arrayIndex]
        for s in sitesToCheck! {
            let strand = [boardArray[s[0]],boardArray[s[1]],boardArray[s[2]],boardArray[s[3]],boardArray[s[4]]]
            if (strand == [0,mark,mark,mark,mark]) { count += 1 }
            if (strand == [mark,0,mark,mark,mark]) { count += 1 }
            if (strand == [mark,mark,0,mark,mark]) { count += 1 }
            if (strand == [mark,mark,mark,0,mark]) { count += 1 }
            if (strand == [mark,mark,mark,mark,0]) { count += 1 }
        }
        return count
    }
    

    
}  // end of FastBoard class defintiion





// MARK: class constant defining functions

private func buildWinSitesByTile(row: Int, column: Int, omitCenter: Bool = true) -> [[Int]] {
    var sitesToCheckInTupleForm = [[(Int,Int)]]()
    var vectorsToCheck = [([Int],[Int])]()
    if (row < 6 && column < 6) {
        vectorsToCheck.append(([0,0,0,1,2],[0,1,2,2,2]))
        vectorsToCheck.append(([0,1,2,2,2],[0,0,0,1,2]))
        vectorsToCheck.append(([2,1,0,0,0],[0,0,0,1,2]))
    }
    if (row < 7 && row > 0 && column < 6) {
        vectorsToCheck.append(([-1,0,1,1,1],[0,0,0,1,2]))
        vectorsToCheck.append(([1,0,-1,-1,-1],[0,0,0,1,2]))
    }
    if (row > 1 && column < 6) {
        vectorsToCheck.append(([-2,-2,-2,-1,0],[2,1,0,0,0]))
        vectorsToCheck.append(([0,0,0,-1,-2],[0,1,2,2,2]))
        vectorsToCheck.append(([-2,-1,0,0,0],[0,0,0,1,2]))
    }
    if (row < 6 && column > 0 && column < 7) {
        vectorsToCheck.append(([0,0,0,1,2],[1,0,-1,-1,-1]))
        vectorsToCheck.append(([0,0,0,1,2],[-1,0,1,1,1]))
    }
    if (row < 6 && column > 1) {
        vectorsToCheck.append(([0,0,0,1,2],[0,-1,-2,-2,-2]))
        vectorsToCheck.append(([0,0,0,1,2],[-2,-1,0,0,0]))
        vectorsToCheck.append(([0,1,2,2,2],[0,0,0,-1,-2]))
    }
    if (row > 0 && row < 7 && column > 1) {
        vectorsToCheck.append(([-1,-1,-1,0,1],[-2,-1,0,0,0]))
        vectorsToCheck.append(([1,1,1,0,-1],[-2,-1,0,0,0]))
    }
    if (row > 1 && column > 1) {
        vectorsToCheck.append(([-2,-2,-2,-1,0],[-2,-1,0,0,0]))
        vectorsToCheck.append(([-2,-1,0,0,0],[-2,-2,-2,-1,0]))
        vectorsToCheck.append(([0,0,0,-1,-2],[-2,-1,0,0,0]))
    }
    if (row > 1 && column > 0 && column < 7) {
        vectorsToCheck.append(([-2,-1,0,0,0],[-1,-1,-1,0,1]))
        vectorsToCheck.append(([0,0,0,-1,-2],[-1,0,1,1,1]))
    }
    for vector in vectorsToCheck {
        var rowIndices = vector.0
        var columnIndices = vector.1
        var entry = [(Int,Int)]()
        for i in 0...4 {
            entry.append((row + rowIndices[i],column + columnIndices[i]))
        }
        sitesToCheckInTupleForm.append(entry)
    }
    var sitesToCheck = [[Int]]()
    for site in sitesToCheckInTupleForm {
        var newSite = [Int]()
        for location in site {
            let tileLocation = 8 * location.0 + location.1
            if (omitCenter) {
                if ( tileLocation != (8 * row + column)) { // no need to include the location where the tile was just placed in our check
                    newSite.append( 8 * location.0 + location.1 )
                }
            }
            else {
                newSite.append( 8 * location.0 + location.1 )            }
            
        }
        sitesToCheck.append(newSite)
    }
    
    return sitesToCheck
}

private func buildWinSites(omitCenter : Bool = true) -> [Int: [[Int]]] {
    // Returns a dictionary used to look up the sets of tile combinations through
    // a point that could contain win corners.  The keys are the ARRAY INDICES of
    // a point on the game board  (e.g. a key of 1 is row 1, column 5).
    // The dictionary values are arrays of tile indices.
    var siteDictionary = [Int: [[Int]]]()
    for row in 0...7 {
        for column in 0...7 {
            let arrayIndex = coordinatesToArrayIndex(row, column: column)
            siteDictionary[arrayIndex] = buildWinSitesByTile(row, column: column, omitCenter: omitCenter)
        }
    }
    
    return siteDictionary
}

private func buildAdjacencySites() -> [[Int]] {
    // Builds a dictionary used for constant-time lookups of the indices of boardArray elements that
    // correspond to tiles adjacent to the tile represented by the index used as the dictionary key.
    // Includes diagonal adjacencies.
    var result = [[Int]]()
    for index in 0...63 {
        var adjacentLocations = [Int]()
        if (index > 7) { adjacentLocations.append(index - 8) } // tile is not in first row
        if (index < 56) { adjacentLocations.append(index + 8) } // tile is not in last row
        if (index % 8 != 0) { adjacentLocations.append(index - 1) } // tile is not in the first column
        if (index % 8 != 7) {adjacentLocations.append(index + 1) } // tile is not in last column
        if (index > 7 && index % 8 != 0) {adjacentLocations.append(index - 9) } // above left
        if (index > 7 && index % 8 != 7) {adjacentLocations.append(index - 7) } // above right
        if (index < 56 && index % 8 != 0) {adjacentLocations.append(index + 7) } // below left
        if (index < 56 && index % 8 != 7) {adjacentLocations.append(index + 9) } // below right
        result.append(adjacentLocations)
    }
    return result
}

private func buildJumpTargets() -> [[Int]] {
    // Builds a dictionary used for constant-time lookups of the indices of boardArray elements that
    // correspond to tiles adjacent to the tile represented by the index used as the dictionary key.
    // Includes diagonal adjacencies.
    var result = [[Int]]()
    for index in 0...63 {
        var targets = [Int]()
        if (index > 15) { targets.append(index - 16) } // tile is not in first row
        if (index < 48) { targets.append(index + 16) } // tile is not in last row
        if (index % 8 > 1 ) { targets.append(index - 2) } // tile is not in the first column
        if (index % 8 < 6) {targets.append(index + 2) } // tile is not in last column
        if (index > 15 && index % 8 > 1 ) { targets.append(index - 18) } // above left
        if (index > 15 && index % 8 < 6) { targets.append(index - 14) } // above right
        if (index < 48 && index % 8 > 1) { targets.append(index + 14) } // below left
        if (index < 48 && index % 8 < 6) { targets.append(index + 18) } // below right
        result.append(targets)
    }
    return result
}

// MARK: Helper functions


func coordinatesToArrayIndex(row: Int, column: Int) -> Int {
    return 8*row+column
}

func arrayIndexToCoordinates(index: Int) -> (Int,Int){
    let row: Int = index / 8
    let column: Int = index % 8
    return (row, column)
}

// MARK: Utility for testing purposes

func buildGameBoardFromPiecePlacements(player1tiles: [(Int,Int)], player2tiles: [(Int,Int)]) -> FastBoard {
    var board = FastBoard()
    for tile in player1tiles {
        board = board.placePiece(coordinatesToArrayIndex(tile.0, column: tile.1), mark: 1)
    }
    for tile in player2tiles {
        board = board.placePiece(coordinatesToArrayIndex(tile.0, column: tile.1), mark: 2)
    }
    //print("Intermediate board:")
    //print(board)
    return board
}

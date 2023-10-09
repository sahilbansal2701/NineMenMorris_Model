#lang forge

// Player
abstract sig Player {}
one sig P1, P2 extends Player {}

// Board
sig State {
    board: pfunc Int -> Int -> Player,
    turn: one Player
}

// Optimization Helper
one sig Helper {
    intsSquare: set Int,
    intsI: set Int
}

pred wellformed {
    // each square has slots 0 to 7
    all s: State | all square: Int | all i: Int {
        some s.board[square][i] => (i >= 0 and i <= 7 and square >= 0 and square <= 1)
    }
}

fun countPiecesPlayer[s: State, p: Player]: Int {
    add[#{i: Helper.intsI | s.board[0][i] = p}, #{i: Helper.intsI | s.board[1][i] = p}]
}

pred starting[s: State] {
    // 1 player has 3 tokens on the board, the other player has 4 to 9 tokens on the board.
    (countPiecesPlayer[s, P1] = 3 and (countPiecesPlayer[s, P2] >= 4 and countPiecesPlayer[s, P2] <= 6))
    or
    (countPiecesPlayer[s, P2] = 3 and (countPiecesPlayer[s, P1] >= 4 and countPiecesPlayer[s, P1] <= 6))
}

pred P1Turn[s: State] {
    s.turn = P1
}

pred P2Turn[s: State] {
    s.turn = P2
}

pred loser[s: State, p: Player] {
     countPiecesPlayer[s, p] = 2
}

pred someValidMove[s: State, p: Player] {
    some square: Helper.intsSquare | some i: Helper.intsI | { // pieces player has
        s.board[square][i] = p
        (remainder[i, 2] = 1) => {
            no s.board[square][remainder[add[i, 1], 8]] or
            no s.board[square][remainder[subtract[i, 1], 8]] or
            (square = 0 and no s.board[1][i]) or
            (square = 1 and no s.board[0][i])
        } else {
            no s.board[square][remainder[add[i, 1], 8]] or
            no s.board[square][remainder[subtract[i, 1], 8]]
        }
    }
}

pred gameOver[s: State] {
    (some p: Player | loser[s, p] or not someValidMove[s, p])
}

pred gameOverPlayer[s: State, p: Player] {
    loser[s, p] or not someValidMove[s, p]
}

// Instance Optimizer
inst opt {
    State = `State0
    Helper = `Helper0
    P1 = `P10
    P2 = `P20
    Player = P1 + P2
    board in State -> (0 + 1)->(0 + 1 + 2 + 3 + 4 + 5 + 6 + 7)->(P1 + P2)
    intsSquare = `Helper0->{0 + 1}
    intsI = `Helper0->{0 + 1 + 2 + 3 + 4 + 5 + 6 + 7}
}

run {
    wellformed
    all s: State | starting[s]
} for exactly 4 Int, exactly 1 State for opt
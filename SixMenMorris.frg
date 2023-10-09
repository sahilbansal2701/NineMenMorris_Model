#lang forge

// Player
abstract sig Player {}
one sig P1, P2 extends Player {}

// Board
sig State {
    board: pfunc Int -> Int -> Player, // first int is the square we are on. 1 = outer, 0 = inner
    turn: one Player // Denotes person who is going to move
}

// Trace of Game
one sig Trace {
    initial_state: one State,
    next: pfunc State -> State
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

fun oppositePlayer[p: Player]: Player {
    Player - p
}

pred starting[s: State] {
    // 1 player has 3 tokens on the board, the other player has 4 to 6 tokens on the board.
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

pred millPostNotPre[pre: State, p: Player, post: State] {
    // if mill in post that is not in pre

    // inner square
    {{post.board[0][0] = p and post.board[0][1] = p and post.board[0][2] = p} and {pre.board[0][0] != p or pre.board[0][1] != p or pre.board[0][2] != p}} or
    {{post.board[0][2] = p and post.board[0][3] = p and post.board[0][4] = p} and {pre.board[0][2] != p or pre.board[0][3] != p or pre.board[0][4] != p}} or
    {{post.board[0][4] = p and post.board[0][5] = p and post.board[0][6] = p} and {pre.board[0][4] != p or pre.board[0][5] != p or pre.board[0][6] != p}} or
    {{post.board[0][6] = p and post.board[0][7] = p and post.board[0][0] = p} and {pre.board[0][6] != p or pre.board[0][7] != p or pre.board[0][0] != p}} or

    // middle square
    {{post.board[1][0] = p and post.board[1][1] = p and post.board[1][2] = p} and {pre.board[1][0] != p or pre.board[1][1] != p or pre.board[1][2] != p}} or
    {{post.board[1][2] = p and post.board[1][3] = p and post.board[1][4] = p} and {pre.board[1][2] != p or pre.board[1][3] != p or pre.board[1][4] != p}} or
    {{post.board[1][4] = p and post.board[1][5] = p and post.board[1][6] = p} and {pre.board[1][4] != p or pre.board[1][5] != p or pre.board[1][6] != p}} or
    {{post.board[1][6] = p and post.board[1][7] = p and post.board[1][0] = p} and {pre.board[1][6] != p or pre.board[1][7] != p or pre.board[1][0] != p}}
}

pred slide[pre: State, p: Player, post: State] {
    // Guard
    not gameOver[pre]
    p = P1 implies P1Turn[pre]
    p = P2 implies P2Turn[pre]

    // Action
    pre.turn != post.turn -- change turn to next player

    some square: Helper.intsSquare | some i: Helper.intsI | {
        // Constrain square and i
        pre.board[square][i] = p

        // remove as moving
        no post.board[square][i]

        some square1: Helper.intsSquare | some i1: Helper.intsI | {
            // ints are different so piece moves, only one should differ though, XOR!
            ((square != square1) or (i != i1)) and ((square = square1) or (i = i1))

            // square1 is in bounds
            square1 <= 1 and square1 >= 0

            // i1 is in bounds
            i1 <= 7 and i1 >= 0

            // constrain where you can slide the piece to: only one of i or square changes
            {
                // i is odd means that square can change; square1 will be 1 off from square and i won't change
                // i is odd comes after because of implies logic
                {{(square1 = add[square, 1] or square1 = subtract[square, 1]) and i = i1} and remainder[i, 2] = 1}
                or 
                // if square doesn't move, then i can move: technically i can always move...
                // i must (i+1)%8 or (i-1)%8 and square won't change
                {(i1 = remainder[add[i, 1], 8] or i1 = remainder[subtract[i, 1], 8]) and square = square1}
            }

            // there is nothing at this place before this turn
            no pre.board[square1][i1]

            // there is something at this place after this turn, i.e. make the move
            post.board[square1][i1] = p

            millPostNotPre[pre, p, post] => {

                // remove a random piece from the opposite player
                some squareRem: Helper.intsSquare | some iRem: Helper.intsI | all square2: Helper.intsSquare | all i2: Helper.intsI | {
                    // Constrain squareRem and iRem
                    pre.board[squareRem][iRem] = oppositePlayer[p]

                    no post.board[squareRem][iRem]

                    // Frame Condition
                    post.board = pre.board - square->i->p + square1->i1->p - squareRem->iRem->oppositePlayer[p]
                 }
            } else {
                // Frame Condition
                post.board = pre.board - square->i->p + square1->i1->p
            }
        }
    }
}

pred flyingMove[pre: State, p: Player, post: State] {
    // Guard
    not gameOver[pre]
    p = P1 implies P1Turn[pre]
    p = P2 implies P2Turn[pre]

    //make sure that the current player only has 3 pieces on the board
    countPiecesPlayer[pre, p] = 3

    // Action
    pre.turn != post.turn -- change turn to next player

    some square: Helper.intsSquare | some i: Helper.intsI | {
        // Constrain square and i
        pre.board[square][i] = p

        // remove as moving
        no post.board[square][i]

        some square1: Helper.intsSquare | some i1: Helper.intsI | {
            // ints are different so piece moves
            (square != square1) or (i != i1)

            // square1 is in bounds
            square1 <= 1 and square1 >= 0

            // i1 is in bounds
            i1 <= 7 and i1 >= 0

            // there is nothing at this place before this turn
            no pre.board[square1][i1]

            // there is something at this place after this turn, i.e. make the move
            post.board[square1][i1] = p

            millPostNotPre[pre, p, post] => {

                // remove a random piece from the opposite player
                some squareRem: Helper.intsSquare | some iRem: Helper.intsI | all square2: Helper.intsSquare | all i2: Helper.intsI | {
                    // Constrain squareRem and iRem
                    pre.board[squareRem][iRem] = oppositePlayer[p]

                    no post.board[squareRem][iRem]

                    // Frame Condition
                    post.board = pre.board - square->i->p + square1->i1->p - squareRem->iRem->oppositePlayer[p]
                 }
            } else {
                // Frame Condition
                post.board = pre.board - square->i->p + square1->i1->p
            }
        }
    }
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

pred loser[s: State, p: Player] {
     countPiecesPlayer[s, p] = 2
}

pred gameOver[s: State] {
    (some p: Player | loser[s, p] or not someValidMove[s, p])
}

pred gameOverPlayer[s: State, p: Player] {
    loser[s, p] or not someValidMove[s, p]
}

pred doNothing[pre: State, post: State] {
    // Guard
    gameOver[pre]

    // Action
    pre.board = post.board
    pre.turn = post.turn
}

pred tracesWithoutFlying {
    -- initial board is a starting board (rules of Nine Men Morris)
    starting[Trace.initial_state]
    -- initial board is initial in the sequence (trace)
    not (some sprev: State | Trace.next[sprev] = Trace.initial_state)
    --"next” enforces move predicate (valid transitions!)
    all s: State | {
        some Trace.next[s] implies {
            (some p: Player | slide[s, p, Trace.next[s]])
            or
            (doNothing[s, Trace.next[s]])
        }   
    }
}

pred tracesWithFlying {
    -- initial board is a starting board (rules of Nine Men Morris)
    starting[Trace.initial_state]
    -- initial board is initial in the sequence (trace)
    not (some sprev: State | Trace.next[sprev] = Trace.initial_state)
    --"next” enforces move predicate (valid transitions!)
    all s: State | {
        some Trace.next[s] implies {
            // change to say player with 3 tokens always flies makes life easier, not needed actually as slide or fly up to them even though fly is just a better slide
            (some p: Player | slide[s, p, Trace.next[s]] or flyingMove[s, p, Trace.next[s]])
            or
            (doNothing[s, Trace.next[s]])
        }
        
    }
}

// Instance Optimizers

inst opt2 { // Two States
    Trace = `Trace0
    State = `State0 + `State1
    Helper = `Helper0
    P1 = `P10
    P2 = `P20
    Player = P1 + P2
    board in State -> (0 + 1)->(0 + 1 + 2 + 3 + 4 + 5 + 6 + 7)->(P1 + P2)
    initial_state = `Trace0->`State0
    next = `Trace0->`State0->`State1
    intsSquare = `Helper0->{0 + 1}
    intsI = `Helper0->{0 + 1 + 2 + 3 + 4 + 5 + 6 + 7}
}

inst opt3 { // Three States
    Trace = `Trace0
    State = `State0 + `State1 + `State2
    Helper = `Helper0
    P1 = `P10
    P2 = `P20
    Player = P1 + P2
    board in State -> (0 + 1)->(0 + 1 + 2 + 3 + 4 + 5 + 6 + 7)->(P1 + P2)
    initial_state = `Trace0->`State0
    next = `Trace0->`State0->`State1 + 
           `Trace0->`State1->`State2
    intsSquare = `Helper0->{0 + 1}
    intsI = `Helper0->{0 + 1 + 2 + 3 + 4 + 5 + 6 + 7}
}

inst opt4 { // Four States
    Trace = `Trace0
    State = `State0 + `State1 + `State2 + `State3
    Helper = `Helper0
    P1 = `P10
    P2 = `P20
    Player = P1 + P2
    board in State -> (0 + 1)->(0 + 1 + 2 + 3 + 4 + 5 + 6 + 7)->(P1 + P2)
    initial_state = `Trace0->`State0
    next = `Trace0->`State0->`State1 +
           `Trace0->`State1->`State2 + 
           `Trace0->`State2->`State3 
    intsSquare = `Helper0->{0 + 1}
    intsI = `Helper0->{0 + 1 + 2 + 3 + 4 + 5 + 6 + 7}
}

inst opt5 { // Five States
    Trace = `Trace0
    State = `State0 + `State1 + `State2 + `State3 + `State4
    Helper = `Helper0
    P1 = `P10
    P2 = `P20
    Player = P1 + P2
    board in State -> (0 + 1)->(0 + 1 + 2 + 3 + 4 + 5 + 6 + 7)->(P1 + P2)
    initial_state = `Trace0->`State0
    next = `Trace0->`State0->`State1 +
           `Trace0->`State1->`State2 + 
           `Trace0->`State2->`State3 +
           `Trace0->`State3->`State4 
    intsSquare = `Helper0->{0 + 1}
    intsI = `Helper0->{0 + 1 + 2 + 3 + 4 + 5 + 6 + 7}
}

// Generate Traces Without Flying
// run {
//     wellformed
//     tracesWithoutFlying
// } for exactly 5 Int, exactly 4 State for opt4

// Generate Traces With Flying
run {
    wellformed
    tracesWithFlying
} for exactly 5 Int, exactly 4 State for opt4

// Generate Traces Without Flying Where Player with 3 Pieces Wins
// run {
//     wellformed
//     tracesWithoutFlying
//     some s: State | gameOverPlayer[s, P1]
//     (countPiecesPlayer[Trace.initial_state, P2] = 3 and (countPiecesPlayer[Trace.initial_state, P1] >= 4 and countPiecesPlayer[Trace.initial_state, P1] <= 6))
// } for exactly 5 Int, exactly 5 State for opt5
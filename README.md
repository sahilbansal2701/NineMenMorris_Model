# 1710 Final Project: Nine Men's Morris

## Introduction:
    For our final project we have chosen to model a game called Nine Men's Morris. The game has three phases. In the first phase, the players put down a single token on the board in alternating turns. In the second phase, players can only make moves by sliding pieces to adjacent slots ont he board. In the third phase of the game, one player is left with only 3 pieces and is allowed to employ a flying move. The goal of this project is to figure out whether or not the flying move is necessary for the player with 3 pieces left to win. Hence, we will only be modelling the game from the third phase onwards. Here is a link to a Wikipedia pages for more rules of the game. (https://en.wikipedia.org/wiki/Nine_men%27s_morris)
    - Please only look at the NineMenMorris.frg and NineMenMorrisVisualizer.js. The Six Men Morris was for testing out the runtime when it used to take very long.

## Our Goals
    - Our target goal is to figure out whether or not the flying move was necessary for the player left with 3 pieces to win.
    - Our reach goal is to figure out if the game if fair if flying move is employed (i.e. run x times, 50/50 win split)

## Modeling Decisions
    - Each of the squares on the board is represented by an integer. The innermost square is represented by a 0, the middle square is represented by 1, and the outermost square is represented by 2.
    - Each of the squares have eight slots which is represented by having indices from 0 to 7. We start at 0 so when we move left or right i.e. +1 or -1 we can mod by 8 and make a circular array.
    - If a piece's index is an odd number, then it can jump across squares
    - A board is an int to int to player pfunc. The first integer is the square you are on, the second integer is the slot on the board.
    - We are not enforcing that if we are removing a piece from a mill there cannot be any other free non-mill-ed pieces.
    - We decided that when a mill was created a piece from the opposing player would be removed in the same state that the mill was created. This makes the process of checking if a new mill was created and propagating that information so we can remove a piece easier.

## Understanding the Model and Visualizer
    An instance of our model shows a trace of the game. A trace is comprised of states and each state has a board, and whose turn it is. The visualizer will have the outline of the board and circles that are either black or white to represent different players pieces. As we move along the states in the trace using the next relation, the pieces of the board may change positions based on the moves the player makes. A piece may slide to a new position or be removed depending on if a mill was created. The different states in a trace of the game are show sequentially by the visualizer.

    Visualizer Video Demo: https://youtu.be/bSCQMbWb-RE

## Findings
    - We ran the model with a varying number of states and checked whether a player with 3 pieces could win without flying.
        - 2 States: UNSAT
        - 3 States: UNSAT
        - 4 States: UNSAT
        - 5 States: UNSAT
        - 6 States: SAT
    - We reached a conclusion that without flying the player with 3 pieces would need a minimum of 6 states in order to win

    - We then ran the model with varying number of states with the flying move enabled
        - 2 States: UNSAT
        - 3 States: UNSAT
        - 4 States: UNSAT
        - 5 States: UNSAT
        - 6 States: SAT
    - We reached the conclution that with flying, the player with 3 pieces would still need a minimum of 6 states in order to win.

    - Overall, we discovered that with or without flying, the player with 3 pieces needs at least 6 states to win, thus supporting the idea that flying is not absolutely essential for the player with less pieces to win.

## Tradeoffs and Issues
    - A tradeoff we made was that to save some compute time due to complexity, we got rid of the rule that when removing pieces, non-mill-ed pieces should be removed first.
    - An issue we first encountered was that our model took a long time to run. 
        - We resolved this by creating an optimization instance that constrains what the states in the trace will be and what possible values the pfunc that represents our board can take on.
        - We optimized further by creating a helper sig that has sets of numbers. Since we are only interested in certain sets of ints as the first and second input to the pfunc board, we can constrain our quantifiers further using the helper sig sets. i.e. when using quantifiers for our pfunc board instead of saying quantifying over all the possible integers we constrain the set of integers we are quantifying over.
    - Another issue we encountered was with our frame condition in the slide and flyingMove transition predicates. We originially wrote the frame condition using quantifiers, however, that did not work so we switched to using set notation.

## Reflection
    - Our model is limited by the fact that it only models the game from the third phase onwards and that as the trace length increases computation time increases dramatically.
    - Our goals did not change from the proposal. We were able to reach our target goal of figuring out whether or not flying was necessary for the player with 3 pieces to win. We, however, were unable to hit our reach goal with our current definition of fairness. It requires higher-order quantification, which would take a really long time to run and could potentially be unrealistic.
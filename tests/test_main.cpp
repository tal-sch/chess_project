#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"

#include "Board.h"
#include "Game.h"
#include "Piece.h"
#include "Square.h"
#include "Move.h"
#include "ChessConstants.h"

#include <algorithm>

// ---------------------------------------------------------------------------
// Helper: check whether a move (src -> dst) appears in possibleMoves(src)
// ---------------------------------------------------------------------------
static bool move_exists(const Board& board, const Square& src, const Square& dst)
{
    MoveList moves = board.possibleMoves(src);
    return std::find_if(moves.begin(), moves.end(),
        [&src, &dst](const Move& m) { return m.src() == src && m.dst() == dst; })
        != moves.end();
}

// ===========================================================================
// Pawn movement tests
// ===========================================================================
TEST_CASE("White pawn cannot move backward")
{
    Board board;   // standard starting position

    // White pawn on e2  (rank=1, file=4)
    Square e2("e2");
    Square e1("e1");  // one step backward

    REQUIRE(board[e2] != nullptr);
    REQUIRE(board[e2]->type() == PieceType::Pawn);
    REQUIRE(board[e2]->color() == chess_constants::WhitePiece);

    // The pawn should NOT be able to move backward (down one rank).
    CHECK_FALSE(move_exists(board, e2, e1));
}

TEST_CASE("Black pawn cannot move backward")
{
    Board board;

    // Black pawn on d7  (rank=6, file=3)
    Square d7("d7");
    Square d8("d8");  // one step backward for black = up one rank

    REQUIRE(board[d7] != nullptr);
    REQUIRE(board[d7]->type() == PieceType::Pawn);
    REQUIRE(board[d7]->color() == chess_constants::BlackPiece);

    CHECK_FALSE(move_exists(board, d7, d8));
}

TEST_CASE("White pawn can move forward one square")
{
    Board board;

    Square e2("e2");
    Square e3("e3");

    CHECK(move_exists(board, e2, e3));
}

TEST_CASE("White pawn can double-step from starting rank")
{
    Board board;

    Square e2("e2");
    Square e4("e4");

    CHECK(move_exists(board, e2, e4));
}

TEST_CASE("Board initial position has pieces")
{
    Board board;

    // White king on e1
    Square e1("e1");
    REQUIRE(board[e1] != nullptr);
    CHECK(board[e1]->type() == PieceType::King);
    CHECK(board[e1]->color() == chess_constants::WhitePiece);

    // Black king on e8
    Square e8("e8");
    REQUIRE(board[e8] != nullptr);
    CHECK(board[e8]->type() == PieceType::King);
    CHECK(board[e8]->color() == chess_constants::BlackPiece);
}

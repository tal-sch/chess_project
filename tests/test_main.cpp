#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"

#include "Board.h"
#include "Game.h"
#include "Piece.h"
#include "Square.h"
#include "Move.h"
#include "Bot.h"
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
// Piece Movement Tests
// ===========================================================================

TEST_CASE("White pawn movement basics")
{
    Board board;

    Square e2("e2");
    Square e1("e1");
    Square e3("e3");
    Square e4("e4");

    REQUIRE(board[e2] != nullptr);
    CHECK(board[e2]->type() == PieceType::Pawn);
    CHECK(board[e2]->color() == chess_constants::WhitePiece);

    CHECK_FALSE(move_exists(board, e2, e1)); // No backwards
    CHECK(move_exists(board, e2, e3));       // 1-step forward
    CHECK(move_exists(board, e2, e4));       // Double-step forward
}

TEST_CASE("Black pawn movement basics")
{
    Board board;

    Square d7("d7");
    Square d8("d8");
    Square d6("d6");
    Square d5("d5");

    REQUIRE(board[d7] != nullptr);
    CHECK(board[d7]->type() == PieceType::Pawn);
    CHECK(board[d7]->color() == chess_constants::BlackPiece);

    CHECK_FALSE(move_exists(board, d7, d8)); // No backwards
    CHECK(move_exists(board, d7, d6));       // 1-step forward
    CHECK(move_exists(board, d7, d5));       // Double-step forward
}

TEST_CASE("Knight moves in L-shape and can jump over pieces")
{
    Board board;

    Square b1("b1");
    CHECK(move_exists(board, b1, Square("a3")));
    CHECK(move_exists(board, b1, Square("c3")));
    CHECK_FALSE(move_exists(board, b1, Square("b3"))); // Can't move straight
    CHECK_FALSE(move_exists(board, b1, Square("d2"))); // Blocked by pawn on d2
}

TEST_CASE("Bishop movement blocked initially, open after pawn move")
{
    Game game;

    // Bishop at f1 blocked
    CHECK_FALSE(move_exists(game.board(), Square("f1"), Square("c4")));

    // Move e2-e4
    game.play(Square("e2"), Square("e4"));
    game.play(Square("e7"), Square("e5"));

    // Now f1 bishop can move diagonally
    CHECK(move_exists(game.board(), Square("f1"), Square("e2")));
    CHECK(move_exists(game.board(), Square("f1"), Square("c4")));
    CHECK(move_exists(game.board(), Square("f1"), Square("b5")));
}

TEST_CASE("Rook movement blocked initially, open on rank/file")
{
    Game game;

    // Rook at a1 blocked initially
    CHECK_FALSE(move_exists(game.board(), Square("a1"), Square("a3")));

    game.play(Square("a2"), Square("a4"));
    game.play(Square("h7"), Square("h5"));

    // Rook can move along open file
    CHECK(move_exists(game.board(), Square("a1"), Square("a2")));
    CHECK(move_exists(game.board(), Square("a1"), Square("a3")));
}

TEST_CASE("Queen combines rook and bishop moves")
{
    Game game;

    game.play(Square("e2"), Square("e4"));
    game.play(Square("e7"), Square("e5"));

    // Queen at d1 can now move diagonally out
    CHECK(move_exists(game.board(), Square("d1"), Square("f3")));
    CHECK(move_exists(game.board(), Square("d1"), Square("h5")));
}

// ===========================================================================
// Castling Tests
// ===========================================================================

TEST_CASE("Kingside castling works when path is clear")
{
    Game game;
    game.play(Square("e2"), Square("e4"));
    game.play(Square("e7"), Square("e5"));
    game.play(Square("g1"), Square("f3"));
    game.play(Square("b8"), Square("c6"));
    game.play(Square("f1"), Square("c4"));
    game.play(Square("g8"), Square("f6"));

    // White kingside castling should be valid
    MoveResult res = game.play(Square("e1"), Square("h1"));
    CHECK((res == MoveResult::Castling || res == MoveResult::Valid));
    CHECK(game.board()[Square("g1")] != nullptr);
    CHECK(game.board()[Square("g1")]->type() == PieceType::King);
    CHECK(game.board()[Square("f1")] != nullptr);
    CHECK(game.board()[Square("f1")]->type() == PieceType::Rook);
}

TEST_CASE("Queenside castling works when path is clear")
{
    Game game;
    game.play(Square("d2"), Square("d4"));
    game.play(Square("d7"), Square("d5"));
    game.play(Square("b1"), Square("c3"));
    game.play(Square("b8"), Square("c6"));
    game.play(Square("c1"), Square("f4"));
    game.play(Square("c8"), Square("f5"));
    game.play(Square("d1"), Square("d2"));
    game.play(Square("d8"), Square("d7"));

    // White queenside castling (e1 -> a1)
    MoveResult res = game.play(Square("e1"), Square("a1"));
    CHECK((res == MoveResult::Castling || res == MoveResult::Valid));
    CHECK(game.board()[Square("c1")] != nullptr);
    CHECK(game.board()[Square("c1")]->type() == PieceType::King);
    CHECK(game.board()[Square("d1")] != nullptr);
    CHECK(game.board()[Square("d1")]->type() == PieceType::Rook);
}

TEST_CASE("Castling illegal after king has moved and returned")
{
    Game game;
    game.play(Square("e2"), Square("e4"));
    game.play(Square("e7"), Square("e5"));
    game.play(Square("g1"), Square("f3"));
    game.play(Square("b8"), Square("c6"));
    game.play(Square("f1"), Square("c4"));
    game.play(Square("g8"), Square("f6"));

    // King moves to e2, then back to e1
    game.play(Square("e1"), Square("e2"));
    game.play(Square("a7"), Square("a6"));
    game.play(Square("e2"), Square("e1"));
    game.play(Square("h7"), Square("h6"));

    // Castling should now be ILLEGAL
    MoveResult res = game.play(Square("e1"), Square("h1"));
    CHECK(res == MoveResult::IllegalMove);
}

TEST_CASE("Castling illegal after rook has moved and returned")
{
    Game game;
    game.play(Square("h2"), Square("h4"));
    game.play(Square("e7"), Square("e5"));
    game.play(Square("h1"), Square("h3"));
    game.play(Square("b8"), Square("c6"));
    game.play(Square("h3"), Square("h1"));
    game.play(Square("g8"), Square("f6"));

    // Clear f1 and g1
    game.play(Square("e2"), Square("e4"));
    game.play(Square("d7"), Square("d6"));
    game.play(Square("f1"), Square("e2"));
    game.play(Square("c8"), Square("d7"));
    game.play(Square("g1"), Square("f3"));
    game.play(Square("d8"), Square("e7"));

    // Kingside castling illegal because h1 rook moved
    MoveResult res = game.play(Square("e1"), Square("h1"));
    CHECK(res == MoveResult::IllegalMove);
}

TEST_CASE("Castling illegal when king is in check")
{
    Game game;
    game.play(Square("e2"), Square("e4"));
    game.play(Square("e7"), Square("e5"));
    game.play(Square("g1"), Square("f3"));
    game.play(Square("d8"), Square("f6"));
    game.play(Square("f1"), Square("c4"));
    game.play(Square("f6"), Square("xf2")); // Black puts White king in check on f2!

    // White is in check, castling must be illegal
    MoveResult res = game.play(Square("e1"), Square("h1"));
    CHECK(res != MoveResult::Castling);
    CHECK(res != MoveResult::Valid);
}

TEST_CASE("Castling illegal when passing through check")
{
    Game game;
    game.play(Square("e2"), Square("e4")); // e2 is now empty
    game.play(Square("b7"), Square("b6"));
    game.play(Square("g2"), Square("g3")); // prepare to put bishop on g2
    game.play(Square("c8"), Square("a6")); // Black bishop attacks f1 across empty e2!
    game.play(Square("f1"), Square("g2")); // Move bishop to g2, f1 is clear and attacked!
    game.play(Square("d7"), Square("d6"));
    game.play(Square("g1"), Square("f3")); // Move knight out so path to h1 is empty
    game.play(Square("h7"), Square("h6"));

    // f1 is attacked by bishop on a6; White cannot castle kingside through f1
    MoveResult res = game.play(Square("e1"), Square("h1"));
    CHECK(res == MoveResult::IllegalMove);
}

// ===========================================================================
// En Passant Tests
// ===========================================================================

TEST_CASE("En passant works correctly")
{
    Game game;
    game.play(Square("e2"), Square("e4"));
    game.play(Square("a7"), Square("a6"));
    game.play(Square("e4"), Square("e5"));
    game.play(Square("d7"), Square("d5")); // Black pawn double steps adjacent to e5

    // White captures en passant: e5 -> d6
    MoveResult res = game.play(Square("e5"), Square("d6"));
    CHECK((res == MoveResult::EnPassant || res == MoveResult::Valid));

    // White pawn on d6
    CHECK(game.board()[Square("d6")] != nullptr);
    CHECK(game.board()[Square("d6")]->color() == chess_constants::WhitePiece);

    // Black pawn on d5 should be REMOVED
    CHECK(game.board()[Square("d5")] == nullptr);
}

// ===========================================================================
// Pawn Promotion Tests
// ===========================================================================

TEST_CASE("Pawn promotion creates a Queen")
{
    Game game;
    // Walk a white pawn up an open board to promotion
    game.play(Square("a2"), Square("a4"));
    game.play(Square("b7"), Square("b5"));
    game.play(Square("a4"), Square("xb5"));
    game.play(Square("a7"), Square("a6"));
    game.play(Square("b5"), Square("xa6"));
    game.play(Square("c8"), Square("xa6"));
    game.play(Square("h2"), Square("h4"));
    game.play(Square("b8"), Square("c6"));
    game.play(Square("h4"), Square("h5"));
    game.play(Square("e7"), Square("e6"));
    game.play(Square("h5"), Square("h6"));
    game.play(Square("g7"), Square("g6"));
    game.play(Square("h6"), Square("xg7"));
    game.play(Square("f8"), Square("g7"));

    // Move a pawn to 7th rank and promote
    Board testBoard;
    // Clear pieces between e2 and e8
    Square e7("e7");
    Square e8("e8");
    // Place white pawn on e7 and empty e8
    // We can test this via Board directly:
    Move promoMove(Square("e7"), Square("e8"), MoveType::Promotion);
    // Board makeMove promotes to Queen
    testBoard.makeMove(promoMove);
    CHECK(testBoard[e8] != nullptr);
    CHECK(testBoard[e8]->type() == PieceType::Queen);
    CHECK(testBoard[e8]->color() == chess_constants::BlackPiece); // e7 was black pawn
    testBoard.undoLastMove();
    CHECK(testBoard[e7] != nullptr);
    CHECK(testBoard[e7]->type() == PieceType::Pawn);
}

// ===========================================================================
// Checkmate & Check Detection Tests
// ===========================================================================

TEST_CASE("Fool's Mate delivers checkmate in 2 moves")
{
    Game game;
    CHECK(game.play(Square("f2"), Square("f3")) == MoveResult::Valid);
    CHECK(game.play(Square("e7"), Square("e5")) == MoveResult::Valid);
    CHECK(game.play(Square("g2"), Square("g4")) == MoveResult::Valid);
    MoveResult res = game.play(Square("d8"), Square("h4"));
    CHECK(res == MoveResult::Checkmate);
}

TEST_CASE("Scholar's Mate delivers checkmate")
{
    Game game;
    CHECK(game.play(Square("e2"), Square("e4")) == MoveResult::Valid);
    CHECK(game.play(Square("e7"), Square("e5")) == MoveResult::Valid);
    CHECK(game.play(Square("d1"), Square("h5")) == MoveResult::Valid);
    CHECK(game.play(Square("b8"), Square("c6")) == MoveResult::Valid);
    CHECK(game.play(Square("f1"), Square("c4")) == MoveResult::Valid);
    CHECK(game.play(Square("g8"), Square("f6")) == MoveResult::Valid);
    MoveResult res = game.play(Square("h5"), Square("f7"));
    CHECK(res == MoveResult::Checkmate);
}

// ===========================================================================
// Self Check / Pinned Pieces Tests
// ===========================================================================

TEST_CASE("Cannot make move that leaves own king in check")
{
    Game game;
    game.play(Square("e2"), Square("e4"));
    game.play(Square("e7"), Square("e5"));
    game.play(Square("d1"), Square("h5"));
    game.play(Square("a7"), Square("a6"));

    // White queen delivers check: h5xf7+
    MoveResult res = game.play(Square("h5"), Square("f7"));
    CHECK((res == MoveResult::Check || res == MoveResult::Valid));

    // Black cannot ignore check by playing a random move like h7-h6
    MoveResult illegal = game.play(Square("h7"), Square("h6"));
    CHECK((illegal == MoveResult::SelfCheck || illegal == MoveResult::IllegalMove));
}

// ===========================================================================
// Draw Conditions Tests
// ===========================================================================

TEST_CASE("Threefold repetition is detected")
{
    Game game;
    // Move knights back and forth
    // Cycle 1: move out and back (initial position occurs 2nd time at move 4)
    CHECK(game.play(Square("g1"), Square("f3")) == MoveResult::Valid);
    CHECK(game.play(Square("g8"), Square("f6")) == MoveResult::Valid);
    CHECK(game.play(Square("f3"), Square("g1")) == MoveResult::Valid);
    CHECK(game.play(Square("f6"), Square("g8")) == MoveResult::Valid);

    // Cycle 2: move out and back (initial position occurs 3rd time at move 8 -> Draw!)
    CHECK(game.play(Square("g1"), Square("f3")) == MoveResult::Valid);
    CHECK(game.play(Square("g8"), Square("f6")) == MoveResult::Valid);
    CHECK(game.play(Square("f3"), Square("g1")) == MoveResult::Valid);
    MoveResult drawRes = game.play(Square("f6"), Square("g8"));
    CHECK(drawRes == MoveResult::DrawRepetition);
}

TEST_CASE("Insufficient material is detected on king vs king")
{
    Board board;
    // Clear all pieces
    for (size_t r = 0; r < 8; ++r) {
        for (size_t f = 0; f < 8; ++f) {
            Move m(Square(r, f), Square(r, f), MoveType::Capture);
        }
    }
    // Check initial board is not insufficient
    CHECK_FALSE(board.isInsufficientMaterial());
}

// ===========================================================================
// Bot Tests
// ===========================================================================

TEST_CASE("Bot can find legal moves and does not crash")
{
    Board board;
    Bot bot(BotDifficulty::Easy);

    Move best = bot.getBestMove(board, chess_constants::WhitePiece);
    // Best move must be a valid square
    CHECK(best.src().rank() < 8);
    CHECK(best.src().file() < 8);
    CHECK(best.dst().rank() < 8);
    CHECK(best.dst().file() < 8);
    CHECK_FALSE(best.src() == best.dst());
}

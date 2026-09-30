#pragma once

#include <array>

#include "Square.h"
#include "Move.h"
#include "Board.h"
#include "ChessConstants.h"


enum class MoveResult
{
	Valid,
	Check,
	InvalidSource,
	OccupiedDest,
	SelfCheck,
	InvalidInput,
	IllegalMove,
	SameSquare,
	Checkmate,
	Promotion,
	Castling,
	EnPassant
};


class Game
{
public:
	MoveResult play(const Square& src, const Square& dst);

	Board& board() { return _board; }
	const Board& board() const { return _board; }
	PieceColor turn() const { return _turn; }

private:
	Board _board;
	PieceColor _turn = chess_constants::WhitePiece;

	static const std::array<Move, 4> _castlingMoves;

	bool possibleCastling(const Square& src, const Square& dst) const;
};

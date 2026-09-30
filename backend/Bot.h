#pragma once

#include "Board.h"
#include "Move.h"
#include "ChessConstants.h"

enum class BotDifficulty {
	Easy = 1,
	Medium = 3,
	Hard = 5
};

class Bot {
public:
	Bot(BotDifficulty difficulty);
	
	// Returns the best legal move for the given color
	Move getBestMove(Board& board, PieceColor color);

private:
	BotDifficulty _difficulty;
	
	int evaluateBoard(const Board& board, PieceColor color) const;
	int minimax(Board& board, int depth, int alpha, int beta, bool maximizingPlayer, PieceColor botColor);
	
	// Get all strictly legal moves for a given color
	MoveList getAllLegalMoves(Board& board, PieceColor color) const;
};

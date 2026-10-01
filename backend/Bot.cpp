#include "Bot.h"
#include <algorithm>
#include <cstdlib>
#include <random>

// Simple material values
const int pieceValues[] = {
	100, // pawn
	300, // knight
	500, // rook
	300, // bishop
	900, // queen
	10000 // king
};

Bot::Bot(BotDifficulty difficulty) : _difficulty(difficulty) {}

MoveList Bot::getAllLegalMoves(Board& board, PieceColor color) const
{
	MoveList legalMoves;

	for (int rank = 0; rank < chess_constants::Ranks; ++rank)
	{
		for (int file = 0; file < chess_constants::Files; ++file)
		{
			Square sq(file, rank);
			const auto& piece = board[sq];

			if (piece && piece->color() == color)
			{
				MoveList moves = board.possibleMoves(sq);

				for (const auto& move : moves)
				{
					if (!board.selfCheck(move))
						legalMoves.push_back(move);
				}
			}
		}
	}

	return legalMoves;
}

int Bot::evaluateBoard(const Board& board, PieceColor color) const
{
	int score = 0;

	for (int rank = 0; rank < chess_constants::Ranks; ++rank)
	{
		for (int file = 0; file < chess_constants::Files; ++file)
		{
			Square sq(file, rank);
			const auto& piece = board[sq];

			if (piece)
			{
				int val = pieceValues[static_cast<int>(piece->type())];

				if (piece->color() == color)
				{
					score += val;
				}
				else
				{
					score -= val;
				}
			}
		}
	}

	return score;
}

int Bot::minimax(Board& board, int depth, int alpha, int beta, bool maximizingPlayer, PieceColor botColor)
{
	PieceColor currentColor = maximizingPlayer ? botColor : !botColor;
	
	if (depth == 0)
		return evaluateBoard(board, botColor);
	
	MoveList legalMoves = getAllLegalMoves(board, currentColor);

	if (legalMoves.empty())
	{
		if (board.check(currentColor)) // Checkmate
			return maximizingPlayer ? -99999 : 99999;

		return 0; // Stalemate
	}
	
	if (maximizingPlayer)
	{
		int maxEval = -999999;

		for (const auto& move : legalMoves)
		{
			board.makeMove(move);
			int eval = minimax(board, depth - 1, alpha, beta, false, botColor);
			board.undoLastMove();
			maxEval = std::max(maxEval, eval);
			alpha = std::max(alpha, eval);
			if (beta <= alpha) break;
		}

		return maxEval;
	}
	else
	{
		int minEval = 999999;

		for (const auto& move : legalMoves)
		{
			board.makeMove(move);
			int eval = minimax(board, depth - 1, alpha, beta, true, botColor);
			board.undoLastMove();
			minEval = std::min(minEval, eval);
			beta = std::min(beta, eval);
			if (beta <= alpha) break;
		}

		return minEval;
	}
}

Move Bot::getBestMove(Board& board, PieceColor color)
{
	MoveList legalMoves = getAllLegalMoves(board, color);
	if (legalMoves.empty()) return Move(Square(0,0), Square(0,0));
	
	int depth = static_cast<int>(_difficulty);
	int bestEval = -999999;
	Move bestMove = legalMoves[0];
	
	// Adding some randomness for equal moves so bot doesn't always play identical games
	std::random_device rd;
	std::mt19937 g(rd());
	std::shuffle(legalMoves.begin(), legalMoves.end(), g);
	
	for (const auto& move : legalMoves)
	{
		board.makeMove(move);
		int eval = minimax(board, depth - 1, -999999, 999999, false, color);
		board.undoLastMove();
		
		if (eval > bestEval)
		{
			bestEval = eval;
			bestMove = move;
		}
	}
	
	return bestMove;
}

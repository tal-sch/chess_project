#pragma once

#include <vector>
#include <array>
#include <stack>
#include <memory>

#include "Square.h"
#include "Move.h"
#include "Piece.h"
#include "ChessConstants.h"

using MoveList = std::vector<Move>;


class Board
{
public:
	Board();

	const std::unique_ptr<Piece>& operator[](const Square& s) const;
	const std::unique_ptr<Piece>& at(const Square& s) const;

	void makeMove(const Move& m);
	void undoLastMove();
	MoveList possibleMoves(const Square& s) const;

	bool check(PieceColor color) const;
	bool checkMate(PieceColor color);
	bool selfCheck(const Move& m);

private:
	using MoveGenerator = MoveList(Board::*)(const Square&) const;
	using SquareGetter = Square(Square::*)() const;

	std::array<std::array<std::unique_ptr<Piece>, chess_constants::Files>, chess_constants::Ranks> _board;

	Square _whiteKing = Square(chess_constants::WhiteKingOrigin);
	Square _blackKing = Square(chess_constants::BlackKingOrigin);

	bool _castlingWhite = false;
	bool _castlingBlack = false;

	std::stack<Move> _moveHistory;
	std::stack<std::unique_ptr<Piece>> _capturedPieces;

	static const std::array<MoveGenerator, 6> _generators;

	std::unique_ptr<Piece>& at(const Square& s);

	bool validMove(const Square& src, const Square& dst) const;
	
	
	MoveList generatePawnMoves(const Square& s) const;
	MoveList generateKnightMoves(const Square& s) const;
	MoveList generateRookMoves(const Square& s) const;
	MoveList generateBishopMoves(const Square& s) const;
	MoveList generateQueenMoves(const Square& s) const;
	MoveList generateKingMoves(const Square& s) const;

	MoveList generateMovesByDirection(const Square& s, SquareGetter pGetSquare) const;
	MoveList generateMovesFromGetters(const Square& s, const std::array<SquareGetter, 8>& getters) const;
	MoveList generateCastlingMoves(PieceColor kingColor) const;

	void handleCastling(const Move& m);
	void undoCastling(const Move& m);
};

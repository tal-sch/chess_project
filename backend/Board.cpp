#include "Board.h"

#include <utility>
#include <algorithm>

#include "Piece.h"
#include "ChessConstants.h"
#include "Square.h"
#include "Move.h"

using namespace chess_constants;


const std::array<Board::MoveGenerator, 6> Board::_generators {
	&Board::generatePawnMoves,
	&Board::generateKnightMoves,
	&Board::generateRookMoves,
	&Board::generateBishopMoves,
	&Board::generateQueenMoves,
	&Board::generateKingMoves
};

Board::Board()
	: _whiteKing(WhiteKingOrigin)
	, _blackKing(BlackKingOrigin)
{	
	for (size_t i = 0; i < _board.size(); ++i)
	{
		_board[WhitePawnStart][i] = std::unique_ptr<Piece>(new Pawn(WhitePiece));
		_board[BlackPawnStart][i] = std::unique_ptr<Piece>(new Pawn(BlackPiece));
	}

	_board[0][0] = std::unique_ptr<Piece>(new Rook(WhitePiece));
	_board[0][7] = std::unique_ptr<Piece>(new Rook(WhitePiece));
	_board[7][0] = std::unique_ptr<Piece>(new Rook(BlackPiece));
	_board[7][7] = std::unique_ptr<Piece>(new Rook(BlackPiece));

	_board[0][1] = std::unique_ptr<Piece>(new Knight(WhitePiece));
	_board[0][6] = std::unique_ptr<Piece>(new Knight(WhitePiece));
	_board[7][1] = std::unique_ptr<Piece>(new Knight(BlackPiece));
	_board[7][6] = std::unique_ptr<Piece>(new Knight(BlackPiece));

	_board[0][2] = std::unique_ptr<Piece>(new Bishop(WhitePiece));
	_board[0][5] = std::unique_ptr<Piece>(new Bishop(WhitePiece));
	_board[7][2] = std::unique_ptr<Piece>(new Bishop(BlackPiece));
	_board[7][5] = std::unique_ptr<Piece>(new Bishop(BlackPiece));

	_board[0][3] = std::unique_ptr<Piece>(new Queen(WhitePiece));
	_board[7][3] = std::unique_ptr<Piece>(new Queen(BlackPiece));
	_board[0][4] = std::unique_ptr<Piece>(new King(WhitePiece));
	_board[7][4] = std::unique_ptr<Piece>(new King(BlackPiece));
}

const std::unique_ptr<Piece>& Board::operator[](const Square& s) const
{
	return at(s);
}

std::unique_ptr<Piece>& Board::at(const Square& s)
{
	return _board[s.rank()][s.file()];
}

const std::unique_ptr<Piece>& Board::at(const Square& s) const
{
	return _board[s.rank()][s.file()];
}

void Board::makeMove(const Move& m)
{
	if (!at(m.src()))
		return;

	_moveHistory.push(m);

	if (m.type() == MoveType::Castling)
	{
		handleCastling(m);
		return;
	}

	Square src = m.src(), dst = m.dst();
	const PieceColor COLOR = at(src)->color();
	const MoveType TYPE = m.type();

	if (TYPE == MoveType::Capture) _capturedPieces.push(std::move(at(dst)));
	at(dst) = std::move(at(src));

	auto& piece = at(dst);

	if (piece->type() == PieceType::King)
	{
		if (COLOR) _whiteKing = dst;
		else _blackKing = dst;
	}
	else if (TYPE == MoveType::Promotion)
	{
		piece = std::unique_ptr<Piece>(new Queen(COLOR));
	}
	else if (TYPE == MoveType::EnPassant)
	{
		_capturedPieces.push(std::move(at(COLOR ? dst.below() : dst.above())));
	}
}

void Board::undoLastMove()
{
	if (_moveHistory.empty())
		return;

	Move m = _moveHistory.top();
	_moveHistory.pop();

	if (m.type() == MoveType::Castling)
	{
		undoCastling(m);
		return;
	}

	const Square& src = m.src(), dst = m.dst();
	const PieceColor COLOR = at(dst)->color();
	const MoveType TYPE = m.type();

	at(src) = std::move(at(dst));

	if (TYPE == MoveType::Capture)
	{
		at(dst) = std::move(_capturedPieces.top());
		_capturedPieces.pop();
	}

	auto& piece = at(src);

	if (piece->type() == PieceType::King)
	{
		if (COLOR) _whiteKing = src;
		else _blackKing = src;
	}
	else if (TYPE == MoveType::Promotion)
	{
		piece = std::unique_ptr<Piece>(new Pawn(COLOR));
	}
	else if (TYPE == MoveType::EnPassant)
	{
		at(COLOR ? dst.below() : dst.above()) = std::move(_capturedPieces.top());
		_capturedPieces.pop();
	}
}

bool Board::validMove(const Square& src, const Square& dst) const
{
	MoveList moves = possibleMoves(src);

	return std::find_if(moves.begin(), moves.end(),
		[&src, &dst](const Move& m) { return m.src() == src && m.dst() == dst; })
		!= moves.end();
}

MoveList Board::possibleMoves(const Square& s) const
{
	return at(s) ? (this->*_generators[(size_t)at(s)->type()])(s) : MoveList();
}

bool Board::check(PieceColor color) const
{
	const Square& king = color ? _whiteKing : _blackKing;
	MoveList moves;

	for (size_t i = 0; i < _board.size(); ++i)
	{
		for (size_t j = 0; j < _board[i].size(); ++j)
		{
			if (_board[i][j] && _board[i][j]->color() != color &&
				validMove(Square(i, j), king))
			{
				return true;
			}
		}
	}

	return false;
}

bool Board::checkMate(PieceColor color)
{
	MoveList allMoves, moves;

	for (size_t i = 0; i < _board.size(); ++i)
	{
		for (size_t j = 0; j < _board[i].size(); ++j)
		{
			if (_board[i][j] && _board[i][j]->color() == color)
			{
				moves = possibleMoves(Square(i, j));
				allMoves.insert(allMoves.end(), moves.begin(), moves.end());
			}
		}
	}

	for (const Move& m : allMoves)
		if (!selfCheck(m)) return false;

	return true;
}

bool Board::selfCheck(const Move& m)
{
	if (!at(m.src())) return false;
	PieceColor color = at(m.src())->color();
	makeMove(m);
	bool is_check = check(color);
	undoLastMove();
	return is_check;
}

MoveList Board::generatePawnMoves(const Square& s) const
{
	const PieceColor COLOR = at(s)->color();
	const size_t START_RANK = (COLOR) ? WhitePawnStart : BlackPawnStart;
	const size_t OPPOSITE_START = (COLOR) ? BlackPawnStart : WhitePawnStart;
	const size_t EN_PASSANT_RANK = (COLOR) ? WhitePawnStart + 3 : BlackPawnStart - 3;

	SquareGetter pGetForward = (COLOR) ? &Square::above : &Square::below;
	SquareGetter pGetLeftCapture = (COLOR) ? &Square::top_left : &Square::bottom_left;
	SquareGetter pGetRightCapture = (COLOR) ? &Square::top_right : &Square::bottom_right;

	Square forward = (s.*pGetForward)();
	if (!forward) return MoveList();

	MoveList moves;

	if (!at(forward))
	{
		moves.push_back(Move(s, forward,
			s.rank() == OPPOSITE_START ? MoveType::Promotion : MoveType::Regular));

		if (s.rank() == START_RANK)
		{
			Square doubleForward = (forward.*pGetForward)();
			if (!at(doubleForward))
				moves.push_back(Move(s, doubleForward, MoveType::PawnDoubleStep));
		}
	}

	Square left = (s.*pGetLeftCapture)();
	Square right = (s.*pGetRightCapture)();

	if (left && at(left) && at(left)->color() != COLOR)
		moves.push_back(Move(s, left, MoveType::Capture));

	if (right && at(right) && at(right)->color() != COLOR)
		moves.push_back(Move(s, right, MoveType::Capture));

	if (s.rank() == EN_PASSANT_RANK)
	{
		const Move& lastMove = _moveHistory.top();

		if (lastMove.type() == MoveType::PawnDoubleStep &&
			lastMove.dst() == s.left() || lastMove.dst() == s.right())
		{
			SquareGetter pGetCapture = lastMove.dst() == s.left() ? pGetLeftCapture : pGetRightCapture;
			Move enPassant(s, (s.*pGetCapture)(), MoveType::EnPassant);
			moves.push_back(enPassant);
		}
	}
	
	return moves;
}

MoveList Board::generateKnightMoves(const Square& s) const
{
	static const std::array<SquareGetter, 8> getters{
		&Square::knight_up_left,
		&Square::knight_up_right,
		&Square::knight_down_left,
		&Square::knight_down_right,
		&Square::knight_left_up,
		&Square::knight_left_down,
		&Square::knight_right_up,
		&Square::knight_right_down
	};

	return generateMovesFromGetters(s, getters);
}

MoveList Board::generateRookMoves(const Square& s) const
{
	MoveList moves = generateMovesByDirection(s, &Square::above);

	MoveList tmp = generateMovesByDirection(s, &Square::below);
	moves.insert(moves.end(), tmp.begin(), tmp.end());

	tmp = generateMovesByDirection(s, &Square::left);
	moves.insert(moves.end(), tmp.begin(), tmp.end());

	tmp = generateMovesByDirection(s, &Square::right);
	moves.insert(moves.end(), tmp.begin(), tmp.end());

	return moves;
}

MoveList Board::generateBishopMoves(const Square& s) const
{
	MoveList moves = generateMovesByDirection(s, &Square::top_left);

	MoveList tmp = generateMovesByDirection(s, &Square::top_right);
	moves.insert(moves.end(), tmp.begin(), tmp.end());

	tmp = generateMovesByDirection(s, &Square::bottom_left);
	moves.insert(moves.end(), tmp.begin(), tmp.end());

	tmp = generateMovesByDirection(s, &Square::bottom_right);
	moves.insert(moves.end(), tmp.begin(), tmp.end());

	return moves;
}

MoveList Board::generateQueenMoves(const Square& s) const
{
	MoveList moves = generateRookMoves(s);
	MoveList bishopMoves = generateBishopMoves(s);
	moves.insert(moves.end(), bishopMoves.begin(), bishopMoves.end());
	return moves;
}

MoveList Board::generateKingMoves(const Square& s) const
{
	const PieceColor COLOR = at(s)->color();

	static const std::array<SquareGetter, 8> getters {
		&Square::above,
		&Square::below,
		&Square::left,
		&Square::right,
		&Square::top_left,
		&Square::top_right,
		&Square::bottom_left,
		&Square::bottom_right
	};

	MoveList moves = generateMovesFromGetters(s, getters);

	if (COLOR && !_castlingWhite && s == Square(WhiteKingOrigin) ||
		!COLOR && !_castlingBlack && s == Square(BlackKingOrigin))
	{
		MoveList castlingMoves = generateCastlingMoves(COLOR);
		moves.insert(moves.end(), castlingMoves.begin(), castlingMoves.end());
	}

	return moves;
}

MoveList Board::generateMovesFromGetters(const Square& s, const std::array<SquareGetter, 8>& getters) const
{
	MoveList moves;
	const PieceColor COLOR = at(s)->color();

	for (auto pGetSquare : getters)
	{
		Square dst = (s.*pGetSquare)();

		if (dst)
		{
			if (!at(dst))
			{
				moves.push_back(Move(s, dst));
			}
			else if (at(dst)->color() != COLOR)
			{
				moves.push_back(Move(s, dst, MoveType::Capture));
			}
		}
	}

	return moves;
}

MoveList Board::generateMovesByDirection(const Square& s, SquareGetter pGetSquare) const
{
	MoveList moves;

	Square curr = (s.*pGetSquare)();

	while (curr && !at(curr))
	{
		moves.push_back(Move(s, curr));
		curr = (curr.*pGetSquare)();
	}

	if (curr && at(curr)->color() != at(s)->color())
		moves.push_back(Move(s, curr, MoveType::Capture));

	return moves;
}

MoveList Board::generateCastlingMoves(PieceColor kingColor) const
{
	MoveList moves;

	Square kingSqr = kingColor ? _whiteKing : _blackKing;
	Square leftRook(kingSqr.rank(), LeftRookFile);
	Square rightRook(kingSqr.rank(), RightRookFile);

	if (at(leftRook) && at(leftRook)->type() == PieceType::Rook)
	{
		Square s1(leftRook.right()), s2(s1.right()), s3(s2.right());

		if (!(at(s1) || at(s2) || at(s3)))
			moves.push_back(Move(kingSqr, leftRook, MoveType::Castling));
	}

	if (at(rightRook) && at(rightRook)->type() == PieceType::Rook)
	{
		Square s1(rightRook.left()), s2(s1.left());

		if (!(at(s1) || at(s2)))
			moves.push_back(Move(kingSqr, rightRook, MoveType::Castling));
	}

	return moves;
}

void Board::handleCastling(const Move& m)
{
	const bool LEFT = m.dst().file() < m.src().file();
	const PieceColor COLOR = at(m.src())->color();

	Square kingSqr = m.src();
	Square rookSqr = Square(kingSqr.rank(), LEFT ? LeftRookFile : RightRookFile);
	Square kingDst = Square(kingSqr.rank(), LEFT ? kingSqr.file() - 2 : kingSqr.file() + 2);
	Square rookDst = LEFT ? kingDst.right() : kingDst.left();

	at(kingDst) = std::move(at(kingSqr));
	at(rookDst) = std::move(at(rookSqr));

	if (COLOR)
	{
		_whiteKing = kingDst;
		_castlingWhite = true;
	}
	else
	{
		_blackKing = kingDst;
		_castlingBlack = true;
	}
}

void Board::undoCastling(const Move& m)
{
	const size_t FILE = m.src().file();
	const size_t RANK = m.src().rank();
	const bool LEFT = m.dst().file() < FILE;
	const PieceColor COLOR = !RANK;
	
	Square kingSqr = Square(RANK, LEFT ? FILE - 2 : FILE + 2);
	Square rookSqr = LEFT ? kingSqr.right() : kingSqr.left();
	Square kingDst = COLOR ? Square(WhiteKingOrigin) : Square(BlackKingOrigin);
	Square rookDst = Square(RANK, LEFT ? LeftRookFile : RightRookFile);

	at(kingDst) = std::move(at(kingSqr));
	at(rookDst) = std::move(at(rookSqr));

	if (COLOR)
	{
		_whiteKing = kingDst;
		_castlingWhite = false;
	}
	else
	{
		_blackKing = kingDst;
		_castlingBlack = false;
	}
}

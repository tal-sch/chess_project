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
	_castlingRightsHistory.push(_castlingRights);

	Square src = m.src(), dst = m.dst();
	const PieceColor COLOR = at(src)->color();
	const MoveType TYPE = m.type();

	// Update castling rights
	if (src == Square("e1")) _castlingRights.whiteKingMoved = true;
	if (src == Square("e8")) _castlingRights.blackKingMoved = true;
	if (src == Square("a1") || dst == Square("a1")) _castlingRights.whiteLeftRookMoved = true;
	if (src == Square("h1") || dst == Square("h1")) _castlingRights.whiteRightRookMoved = true;
	if (src == Square("a8") || dst == Square("a8")) _castlingRights.blackLeftRookMoved = true;
	if (src == Square("h8") || dst == Square("h8")) _castlingRights.blackRightRookMoved = true;

	if (TYPE == MoveType::Castling)
	{
		_captureHistory.push(false);
		handleCastling(m);
		return;
	}

	if (TYPE == MoveType::EnPassant)
	{
		_captureHistory.push(true);
		_capturedPieces.push(std::move(at(COLOR ? dst.below() : dst.above())));
	}
	else if (at(dst))
	{
		_captureHistory.push(true);
		_capturedPieces.push(std::move(at(dst)));
	}
	else
	{
		_captureHistory.push(false);
	}

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
}

void Board::undoLastMove()
{
	if (_moveHistory.empty())
		return;

	Move m = _moveHistory.top();
	_moveHistory.pop();

	_castlingRights = _castlingRightsHistory.top();
	_castlingRightsHistory.pop();

	bool wasCaptured = _captureHistory.top();
	_captureHistory.pop();

	if (m.type() == MoveType::Castling)
	{
		undoCastling(m);
		return;
	}

	const Square& src = m.src(), dst = m.dst();
	const PieceColor COLOR = at(dst)->color();
	const MoveType TYPE = m.type();

	at(src) = std::move(at(dst));

	if (wasCaptured)
	{
		if (TYPE == MoveType::EnPassant)
		{
			at(COLOR ? dst.below() : dst.above()) = std::move(_capturedPieces.top());
		}
		else
		{
			at(dst) = std::move(_capturedPieces.top());
		}
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
	return isAttacked(king, !color);
}

bool Board::isAttacked(const Square& sq, PieceColor byColor) const
{
	for (size_t r = 0; r < _board.size(); ++r)
	{
		for (size_t f = 0; f < _board[r].size(); ++f)
		{
			const auto& piece = _board[r][f];
			if (!piece || piece->color() != byColor)
				continue;

			Square src(r, f);
			if (piece->type() == PieceType::Pawn)
			{
				Square leftDiag = byColor ? src.top_left() : src.bottom_left();
				Square rightDiag = byColor ? src.top_right() : src.bottom_right();
				if ((leftDiag && leftDiag == sq) || (rightDiag && rightDiag == sq))
					return true;
			}
			else if (piece->type() == PieceType::King)
			{
				int dr = std::abs(static_cast<int>(src.rank()) - static_cast<int>(sq.rank()));
				int df = std::abs(static_cast<int>(src.file()) - static_cast<int>(sq.file()));
				if (dr <= 1 && df <= 1 && (dr + df > 0))
					return true;
			}
			else
			{
				if (validMove(src, sq))
					return true;
			}
		}
	}
	return false;
}

bool Board::isInsufficientMaterial() const
{
	int whiteKnights = 0, whiteBishops = 0;
	int blackKnights = 0, blackBishops = 0;
	int whiteBishopSquareColor = -1; // 0 = dark, 1 = light
	int blackBishopSquareColor = -1;

	for (size_t r = 0; r < _board.size(); ++r)
	{
		for (size_t f = 0; f < _board[r].size(); ++f)
		{
			const auto& piece = _board[r][f];
			if (!piece) continue;

			if (piece->type() == PieceType::Pawn ||
				piece->type() == PieceType::Rook ||
				piece->type() == PieceType::Queen)
			{
				return false; // Pawns, rooks, queens can checkmate
			}

			if (piece->type() == PieceType::Knight)
			{
				if (piece->color() == WhitePiece) whiteKnights++;
				else blackKnights++;
			}
			else if (piece->type() == PieceType::Bishop)
			{
				int sqColor = static_cast<int>((r + f) % 2);
				if (piece->color() == WhitePiece)
				{
					whiteBishops++;
					whiteBishopSquareColor = sqColor;
				}
				else
				{
					blackBishops++;
					blackBishopSquareColor = sqColor;
				}
			}
		}
	}

	int whiteMinors = whiteKnights + whiteBishops;
	int blackMinors = blackKnights + blackBishops;

	// King vs King
	if (whiteMinors == 0 && blackMinors == 0) return true;

	// King + Minor vs King
	if ((whiteMinors == 1 && blackMinors == 0) || (whiteMinors == 0 && blackMinors == 1)) return true;

	// King + Bishop vs King + Bishop (same color squares)
	if (whiteKnights == 0 && blackKnights == 0 && whiteBishops == 1 && blackBishops == 1)
	{
		if (whiteBishopSquareColor == blackBishopSquareColor) return true;
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
		moves.push_back(Move(s, left, s.rank() == OPPOSITE_START ? MoveType::Promotion : MoveType::Capture));

	if (right && at(right) && at(right)->color() != COLOR)
		moves.push_back(Move(s, right, s.rank() == OPPOSITE_START ? MoveType::Promotion : MoveType::Capture));

	if (!_moveHistory.empty() && s.rank() == EN_PASSANT_RANK)
	{
		const Move& lastMove = _moveHistory.top();

		if (lastMove.type() == MoveType::PawnDoubleStep &&
			(lastMove.dst() == s.left() || lastMove.dst() == s.right()))
		{
			SquareGetter pGetCapture = (lastMove.dst() == s.left()) ? pGetLeftCapture : pGetRightCapture;
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

	if ((COLOR && s == Square(WhiteKingOrigin)) ||
		(!COLOR && s == Square(BlackKingOrigin)))
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

	// King cannot castle out of check
	if (check(kingColor))
		return moves;

	Square kingSqr = kingColor ? _whiteKing : _blackKing;
	size_t rank = kingSqr.rank();
	PieceColor enemyColor = !kingColor;

	bool kingMoved = kingColor ? _castlingRights.whiteKingMoved : _castlingRights.blackKingMoved;
	bool leftRookMoved = kingColor ? _castlingRights.whiteLeftRookMoved : _castlingRights.blackLeftRookMoved;
	bool rightRookMoved = kingColor ? _castlingRights.whiteRightRookMoved : _castlingRights.blackRightRookMoved;

	// Queenside (left rook)
	if (!kingMoved && !leftRookMoved)
	{
		Square leftRook(rank, LeftRookFile);
		if (at(leftRook) && at(leftRook)->type() == PieceType::Rook && at(leftRook)->color() == kingColor)
		{
			Square b(rank, 1), c(rank, 2), d(rank, 3);
			if (!at(b) && !at(c) && !at(d))
			{
				if (!isAttacked(d, enemyColor) && !isAttacked(c, enemyColor))
				{
					moves.push_back(Move(kingSqr, leftRook, MoveType::Castling));
				}
			}
		}
	}

	// Kingside (right rook)
	if (!kingMoved && !rightRookMoved)
	{
		Square rightRook(rank, RightRookFile);
		if (at(rightRook) && at(rightRook)->type() == PieceType::Rook && at(rightRook)->color() == kingColor)
		{
			Square f(rank, 5), g(rank, 6);
			if (!at(f) && !at(g))
			{
				if (!isAttacked(f, enemyColor) && !isAttacked(g, enemyColor))
				{
					moves.push_back(Move(kingSqr, rightRook, MoveType::Castling));
				}
			}
		}
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
	}
	else
	{
		_blackKing = kingDst;
	}
}

void Board::undoCastling(const Move& m)
{
	const size_t FILE = m.src().file();
	const size_t RANK = m.src().rank();
	const bool LEFT = m.dst().file() < FILE;
	const PieceColor COLOR = (RANK == 0);
	
	Square kingSqr = Square(RANK, LEFT ? FILE - 2 : FILE + 2);
	Square rookSqr = LEFT ? kingSqr.right() : kingSqr.left();
	Square kingDst = COLOR ? Square(WhiteKingOrigin) : Square(BlackKingOrigin);
	Square rookDst = Square(RANK, LEFT ? LeftRookFile : RightRookFile);

	at(kingDst) = std::move(at(kingSqr));
	at(rookDst) = std::move(at(rookSqr));

	if (COLOR)
	{
		_whiteKing = kingDst;
	}
	else
	{
		_blackKing = kingDst;
	}
}

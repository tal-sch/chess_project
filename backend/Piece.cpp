#include "Piece.h"


Piece::Piece(PieceType type, PieceColor color)
    : _type(type), _color(color)
{
}

Pawn::Pawn(PieceColor color) : Piece(PieceType::Pawn, color)
{
}

Knight::Knight(PieceColor color) : Piece(PieceType::Knight, color)
{
}

Rook::Rook(PieceColor color) : Piece(PieceType::Rook, color)
{
}

Bishop::Bishop(PieceColor color) : Piece(PieceType::Bishop, color)
{
}

Queen::Queen(PieceColor color) : Piece(PieceType::Queen, color)
{
}

King::King(PieceColor color) : Piece(PieceType::King, color)
{
}

std::ostream& operator<<(std::ostream& os, const Piece& piece)
{
	os << (piece._color ? "White " : "Black ");

	switch (piece._type)
	{
	case PieceType::Pawn:
		os << "Pawn";
		break;
	case PieceType::Knight:
		os << "Knight";
		break;
	case PieceType::Rook:
		os << "Rook";
		break;
	case PieceType::Bishop:
		os << "Bishop";
		break;
	case PieceType::Queen:
		os << "Queen";
		break;
	case PieceType::King:
		os << "King";
		break;
	}

	return os;
}

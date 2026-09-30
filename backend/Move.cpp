#include "Move.h"


Move::Move(const Square& src, const Square& dst, MoveType type)
	: _src(src), _dst(dst), _type(type)
{
}

bool Move::operator==(const Move& other) const
{
	return _src == other._src && _dst == other._dst;
}

std::ostream& operator<<(std::ostream& os, const Move& m)
{
	os << '[' << m._src << ", " << m._dst << "]";

	switch (m._type)
	{
	case MoveType::Regular:
		break;

	case MoveType::Capture:
		os << " Capture";
		break;

	case MoveType::PawnDoubleStep:
		break;

	case MoveType::Promotion:
		os << " Promotion";
		break;

	case MoveType::Castling:
		os << " Castling";
		break;

	case MoveType::EnPassant:
		os << " En Passant";
		break;

	default:
		break;
	}

	return os;
}
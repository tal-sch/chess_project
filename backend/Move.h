#pragma once

#include <ostream>

#include "Square.h"


enum class MoveType
{
	Regular,
	Capture,
	PawnDoubleStep,
	Promotion,
	Castling,
	EnPassant
};


class Move
{
public:
	Move(const Square& src, const Square& dst, MoveType type = MoveType::Regular);

	bool operator==(const Move& other) const;

	const Square& src() const { return _src; };
	const Square& dst() const { return _dst; };
	MoveType type() const { return _type; };

	friend std::ostream& operator<<(std::ostream& os, const Move& m);

private:
	Square _src;
	Square _dst;
	MoveType _type;
};

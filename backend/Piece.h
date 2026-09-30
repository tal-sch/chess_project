#pragma once

#include <ostream>

using PieceColor = bool;


enum class PieceType
{
	Pawn,
	Knight,
	Rook,
	Bishop,
	Queen,
	King
};


class Piece
{
public:
	explicit Piece(PieceType type, PieceColor color);

	PieceType type() const { return _type; };
	PieceColor color() const { return _color; };

	friend std::ostream& operator<<(std::ostream& os, const Piece& piece);

private:
	PieceType _type;
	PieceColor _color;
};

class Pawn : public Piece
{
public:
	explicit Pawn(PieceColor color);
};

class Knight : public Piece
{
public:
	explicit Knight(PieceColor color);
};

class Rook : public Piece
{
public:
	explicit Rook(PieceColor color);
};

class Bishop : public Piece
{
public:
	explicit Bishop(PieceColor color);
};

class Queen : public Piece
{
public:
	explicit Queen(PieceColor color);
};

class King : public Piece
{
public:
	explicit King(PieceColor color);
};
#include "Square.h"

#include "ChessConstants.h"


Square::Square(const char* s)
    : Square(s[1] - '0' - 1, s[0] - 'a')
{
}

Square::Square(const std::string& s)
    : Square(s.c_str())
{
}

Square::Square(size_t rank, size_t file)
    : _rank(rank), _file(file)
{
}

/* Returns true if the square is within the bounds of the chess board. */
Square::operator bool() const
{
    return _rank < chess_constants::Ranks && _file < chess_constants::Files;
}

bool Square::operator==(const Square& other) const
{
    return _rank == other._rank && _file == other._file;
}

Square Square::above() const
{
    return Square(_rank + 1, _file);
}

Square Square::below() const
{
    return Square(_rank - 1, _file);
}

Square Square::left() const
{
    return Square(_rank, _file - 1);
}

Square Square::right() const
{
    return Square(_rank, _file + 1);
}

Square Square::top_left() const
{
    return Square(_rank + 1, _file - 1);
}

Square Square::top_right() const
{
    return Square(_rank + 1, _file + 1);
}

Square Square::bottom_left() const
{
    return Square(_rank - 1, _file - 1);
}

Square Square::bottom_right() const
{
    return Square(_rank - 1, _file + 1);
}

Square Square::knight_up_left() const
{
    return Square(_rank + 2, _file - 1);
}

Square Square::knight_up_right() const
{
    return Square(_rank + 2, _file + 1);
}

Square Square::knight_down_left() const
{
    return Square(_rank - 2, _file - 1);
}

Square Square::knight_down_right() const
{
    return Square(_rank - 2, _file + 1);
}

Square Square::knight_left_up() const
{
    return Square(_rank + 1, _file - 2);
}

Square Square::knight_left_down() const
{
    return Square(_rank - 1, _file - 2);
}

Square Square::knight_right_up() const
{
    return Square(_rank + 1, _file + 2);
}

Square Square::knight_right_down() const
{
    return Square(_rank - 1, _file + 2);
}

std::ostream& operator<<(std::ostream& os, const Square& s)
{
    os << (char)(s._file + 'a') << (char)(s._rank + '0' + 1);
    return os;
}

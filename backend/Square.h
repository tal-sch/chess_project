#pragma once

#include <ostream>
#include <string>


class Square
{
public:
	explicit Square(const char* s);
	explicit Square(const std::string& s);
	Square(size_t rank, size_t file);

	operator bool() const;
	bool operator==(const Square& other) const;

	size_t rank() const { return _rank; };
	size_t file() const { return _file; };

	Square above() const;
	Square below() const;
	Square left() const;
	Square right() const;
	Square top_left() const;
	Square top_right() const;
	Square bottom_left() const;
	Square bottom_right() const;

	Square knight_up_left() const;
	Square knight_up_right() const;
	Square knight_down_left() const;
	Square knight_down_right() const;
	Square knight_left_up() const;
	Square knight_left_down() const;
	Square knight_right_up() const;
	Square knight_right_down() const;

	friend std::ostream& operator<<(std::ostream& os, const Square& s);

private:
	size_t _rank;
	size_t _file;
};

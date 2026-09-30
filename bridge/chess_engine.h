#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

#include "Game.h"
#include "Square.h"
#include "Board.h"
#include "Piece.h"

#include <sstream>

namespace godot {

class ChessEngine : public Node {
    GDCLASS(ChessEngine, Node)

public:
    ChessEngine() = default;
    ~ChessEngine() override = default;

    int play_move(const String& src_str, const String& dst_str);
    Dictionary play_bot_move(int difficulty);
    void new_game();
    int get_piece_at(const String& square_str);
    PackedStringArray get_legal_moves(const String& square_str);
    int get_side_to_move();

protected:
    static void _bind_methods();

private:
    Game game_;
};

} // namespace godot

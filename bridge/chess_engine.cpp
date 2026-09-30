#include "chess_engine.h"
#include "Bot.h"
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

int ChessEngine::play_move(const String& src_str, const String& dst_str) {
    std::string src_s = src_str.utf8().get_data();
    std::string dst_s = dst_str.utf8().get_data();
    Square src(src_s);
    Square dst(dst_s);
    MoveResult result = game_.play(src, dst);
    return static_cast<int>(result);
}

Dictionary ChessEngine::play_bot_move(int difficulty) {
    Dictionary ret;
    PieceColor color = game_.turn();
    Bot bot(static_cast<BotDifficulty>(difficulty));
    Move bestMove = bot.getBestMove(game_.board(), color);
    
    if (bestMove.src() == Square("a1") && bestMove.dst() == Square("a1")) { // Better check for empty? Let's rely on simple string match.
        // Wait, bestMove is valid if it's an actual move. Let's just convert it.
    }
    
    std::ostringstream src_oss; src_oss << bestMove.src();
    std::ostringstream dst_oss; dst_oss << bestMove.dst();
    
    if (src_oss.str() == dst_oss.str()) {
        ret["result"] = -1;
        return ret;
    }
    
    MoveResult result = game_.play(bestMove.src(), bestMove.dst());
    
    ret["src"] = String(src_oss.str().c_str());
    ret["dst"] = String(dst_oss.str().c_str());
    ret["result"] = static_cast<int>(result);
    return ret;
}

void ChessEngine::new_game() {
    game_ = Game();
}

int ChessEngine::get_piece_at(const String& square_str) {
    std::string s = square_str.utf8().get_data();
    Square sq(s);
    if (!sq) return -1;
    const auto& piece = game_.board()[sq];
    if (!piece) return -1;
    int type = static_cast<int>(piece->type());
    int color = piece->color() ? 1 : 0;
    return type * 2 + color;
}

PackedStringArray ChessEngine::get_legal_moves(const String& square_str) {
    PackedStringArray result;
    std::string s = square_str.utf8().get_data();
    Square sq(s);
    if (!sq) return result;
    const auto& piece = game_.board()[sq];
    if (!piece) return result;
    if (piece->color() != game_.turn()) return result;
    MoveList moves = game_.board().possibleMoves(sq);
    for (const Move& m : moves) {
        if (!game_.board().selfCheck(m)) {
            std::ostringstream oss;
            oss << m.dst();
            result.push_back(String(oss.str().c_str()));
        }
    }
    return result;
}

int ChessEngine::get_side_to_move() {
    return game_.turn() ? 1 : 0;
}

void ChessEngine::_bind_methods() {
    ClassDB::bind_method(D_METHOD("play_move", "src", "dst"), &ChessEngine::play_move);
    ClassDB::bind_method(D_METHOD("play_bot_move", "difficulty"), &ChessEngine::play_bot_move);
    ClassDB::bind_method(D_METHOD("new_game"), &ChessEngine::new_game);
    ClassDB::bind_method(D_METHOD("get_piece_at", "square"), &ChessEngine::get_piece_at);
    ClassDB::bind_method(D_METHOD("get_legal_moves", "square"), &ChessEngine::get_legal_moves);
    ClassDB::bind_method(D_METHOD("get_side_to_move"), &ChessEngine::get_side_to_move);
}

} // namespace godot

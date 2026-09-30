#include "Game.h"

#include <algorithm>


const std::array<Move, 4> Game::_castlingMoves {
    Move(Square("e1"), Square("a1"), MoveType::Castling),
    Move(Square("e1"), Square("h1"), MoveType::Castling),
    Move(Square("e8"), Square("a8"), MoveType::Castling),
    Move(Square("e8"), Square("h8"), MoveType::Castling)
};

MoveResult Game::play(const Square& src, const Square& dst)
{
    if (!src || !dst)
        return MoveResult::InvalidInput;

    if (src == dst)
        return MoveResult::SameSquare;

    if (!_board[src] || _board[src]->color() != _turn)
        return MoveResult::InvalidSource;

    if (_board[dst] && _board[dst]->color() == _turn && !possibleCastling(src, dst))
        return MoveResult::OccupiedDest;

    MoveList moves = _board.possibleMoves(src);

    auto it = std::find_if(moves.begin(), moves.end(),
        [&src, &dst](const Move& m) { return m.src() == src && m.dst() == dst; });

    if (it == moves.end())
        return MoveResult::IllegalMove;

    Move m = *it;
    _board.makeMove(m);
    
    if (_board.check(_turn))
    {
        _board.undoLastMove();
        return MoveResult::SelfCheck;
    }

    _turn = !_turn;

    if (m.type() == MoveType::Promotion)
        return MoveResult::Promotion;

    if (m.type() == MoveType::Castling)
        return MoveResult::Castling;

    if (m.type() == MoveType::EnPassant)
        return MoveResult::EnPassant;

    if (_board.checkMate(_turn))
        return MoveResult::Checkmate;

    if (_board.check(_turn))
        return MoveResult::Check;

    return MoveResult::Valid;
}

bool Game::possibleCastling(const Square& src, const Square& dst) const
{
    return std::find(_castlingMoves.begin(), _castlingMoves.end(), Move(src, dst)) != _castlingMoves.end();
}

#include "Game.h"

#include <algorithm>


const std::array<Move, 4> Game::_castlingMoves {
    Move(Square("e1"), Square("a1"), MoveType::Castling),
    Move(Square("e1"), Square("h1"), MoveType::Castling),
    Move(Square("e8"), Square("a8"), MoveType::Castling),
    Move(Square("e8"), Square("h8"), MoveType::Castling)
};

Game::Game()
{
    _positionHistory.push_back(getBoardSignature());
}

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
    bool isPawnMove = (_board[src] && _board[src]->type() == PieceType::Pawn);
    bool isCapture = (_board[dst] != nullptr) || (m.type() == MoveType::EnPassant);

    _board.makeMove(m);
    
    if (_board.check(_turn))
    {
        _board.undoLastMove();
        return MoveResult::SelfCheck;
    }

    _turn = !_turn;

    // Fifty-move clock
    if (isPawnMove || isCapture)
        _halfMoveClock = 0;
    else
        _halfMoveClock++;

    // Position history for threefold repetition
    std::string sig = getBoardSignature();
    _positionHistory.push_back(sig);
    int repetitionCount = static_cast<int>(std::count(_positionHistory.begin(), _positionHistory.end(), sig));

    // Check game over conditions: Checkmate or Stalemate
    if (_board.checkMate(_turn))
    {
        if (_board.check(_turn))
            return MoveResult::Checkmate;
        else
            return MoveResult::Stalemate;
    }

    if (repetitionCount >= 3)
        return MoveResult::DrawRepetition;

    if (_halfMoveClock >= 100)
        return MoveResult::DrawFiftyMoves;

    if (_board.isInsufficientMaterial())
        return MoveResult::DrawInsufficientMaterial;

    if (_board.check(_turn))
        return MoveResult::Check;

    if (m.type() == MoveType::Promotion)
        return MoveResult::Promotion;

    if (m.type() == MoveType::Castling)
        return MoveResult::Castling;

    if (m.type() == MoveType::EnPassant)
        return MoveResult::EnPassant;

    return MoveResult::Valid;
}

bool Game::possibleCastling(const Square& src, const Square& dst) const
{
    return std::find(_castlingMoves.begin(), _castlingMoves.end(), Move(src, dst)) != _castlingMoves.end();
}

std::string Game::getBoardSignature() const
{
    std::string sig;
    sig.reserve(66);
    for (size_t r = 0; r < 8; ++r)
    {
        for (size_t f = 0; f < 8; ++f)
        {
            const auto& p = _board[Square(r, f)];
            if (!p)
            {
                sig += '.';
            }
            else
            {
                char c = '?';
                switch (p->type())
                {
                case PieceType::Pawn: c = 'p'; break;
                case PieceType::Knight: c = 'n'; break;
                case PieceType::Bishop: c = 'b'; break;
                case PieceType::Rook: c = 'r'; break;
                case PieceType::Queen: c = 'q'; break;
                case PieceType::King: c = 'k'; break;
                }
                sig += (p->color() == chess_constants::WhitePiece) ? static_cast<char>(toupper(c)) : c;
            }
        }
    }
    sig += (_turn == chess_constants::WhitePiece ? 'w' : 'b');
    return sig;
}

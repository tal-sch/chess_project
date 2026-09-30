#pragma once


namespace chess_constants
{
	constexpr bool WhitePiece = true;
	constexpr bool BlackPiece = false;

	constexpr size_t Ranks = 8;
	constexpr size_t Files = 8;

	constexpr size_t WhitePawnStart = 1; // initial rank for white pawns
	constexpr size_t BlackPawnStart = 6; // initial rank for black pawns

	constexpr size_t LeftRookFile = 0; // initial file for left rooks
	constexpr size_t RightRookFile = 7; // initial file for right rooks

	constexpr const char* WhiteKingOrigin = "e1"; // initial square of the white king
	constexpr const char* BlackKingOrigin = "e8"; // initial square of the black king
}

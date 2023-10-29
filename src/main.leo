program chess.aleo {

    struct board_state {
        line0: u64,
        line1: u64,
        line2: u64,
        line3: u64,
        line4: u64,
    }

    struct move {
        game_id: u64,
        player: address,
        x: u64,
        y: u32,
        target_x: u64,
        target_y: u32,
        attack_result: u32
        flag_x: u64,
        flag_y: u32,
        opp_flag_x: u64,
        opp_flag_y: u32,
        game_winner: u32,
    }

    record player_state {
        owner: address,
        gates: u64,
        game_id: u64,
        board: board_state,
        flag_x: u64,
        flag_y: u32,
        game_winner: u32,
        arbiter: address,
        player_index: u32,
    }

    record piece_info {
        owner: address,
        gates: u64,
        game_id: u64,
        player: address,
        piece: u64,
        x: u64,
        y: u32,
        flag_x: u64,
        flag_y: u32,
    }

    inline get_piece(board: board_state, x: u64, y: u32) -> u64 {
        let line: u64 = get_line(board, x);
        return get_piece_from_line(line, y);
    }

    inline get_line(board: board_state, x: u64) -> u64 {
        if x == 0u64 {
            return board.line0;
        } else if x == 1u64 {
            return board.line1;
        } else if x == 2u64 {
            return board.line2;
        } else if x == 3u64 {
            return board.line3;
        } else {
            return board.line4;
        }
    }

    inline get_piece_from_line(x: u64, y: u32) -> u64 {
        let mask: u64 = 15u64;
        let row: u32 = y * 4u32;
        let val: u64 = mask << row;
        return (val & x) >> row;
    }

    transition player_initialize_board(
        line0: u64, line1: u64, line2: u64, line3: u64, line4: u64,
        flag_x: u64, flag_y: u32, public game_id: u64, public player_index: u32, public arbiter: address
    ) -> (player_state, bool) {
        let board: board_state = board_state {
            line0: line0,
            line1: line1,
            line2: line2,
            line3: line3,
            line4: line4,
        };
        let state: player_state = player_state {
            owner: self.caller,
            gates: 0u64,
            game_id: game_id,
            board: board,
            flag_x: flag_x,
            flag_y: flag_y,
            game_winner: 0u32,
            arbiter: arbiter,
            player_index: player_index,
        };
        return (state, true);
    }

    transition move_piece(
        state: player_state,
        public prev_move: move,
        public x: u64,
        public y: u32,
        public target_x: u64,
        public target_y: u32
    ) -> (player_state, piece_info) {
        let board: board_state = board_state {
            line0: state.board.line0,
            line1: state.board.line1,
            line2: state.board.line2,
            line3: state.board.line3,
            line4: state.board.line4,
        };

        if prev_move.x < 5u64 {
            board = empty_square(board, prev_move.x, prev_move.y);
            if prev_move.attack_result == 0u32 || prev_move.attack_result == 1u32 {
                board = place_piece(board, prev_move.target_x, prev_move.target_y, 13u64);
            } else if prev_move.attack_result == 2u32 {
                board = empty_square(board, prev_move.target_x, prev_move.target_y);
            }
        }

        let game_winner: u32 = prev_move.game_winner;
        let new_state: player_state = player_state {
            owner: self.caller,
            gates: 0u64,
            game_id: state.game_id,
            board: board,
            game_winner: game_winner,
            flag_x: state.flag_x,
            flag_y: state.flag_y,
            arbiter: state.arbiter,
            player_index: state.player_index,
        };

        let piece: u64 = game_winner == 0u32 ? get_piece(board, x, y) : 0u64;
        let flag_x: u64 = piece == 12u64 ? state.flag_x : 5u64;
        let flag_y: u32 = piece == 12u64 ? state.flag_y : 0u32;
        return (new_state, piece_info {
            owner: state.arbiter,
            gates: 0u64,
            game_id: state.game_id,
            player: state.owner,
            piece: piece,
            x: x,
            y: y,
            flag_x: flag_x,
            flag_y: flag_y,
        });
    }

    transition whisper_piece(
        state: player_state,
        public prev_move: move,
        public target_x: u64,
        public target_y: u32
    ) -> (player_state, piece_info) {
        let board: board_state = board_state {
            line0: state.board.line0,
            line1: state.board.line1,
            line2: state.board.line2,
            line3: state.board.line3,
            line4: state.board.line4,
        };

        if prev_move.x < 5u64 {
            let piece: u64 = get_piece(board, prev_move.x, prev_move.y);
            board = empty_square(board, prev_move.x, prev_move.y);
            if prev_move.attack_result == 0u32 || prev_move.attack_result == 1u32 {
                board = place_piece(board, prev_move.target_x, prev_move.target_y, piece);
            } else if prev_move.attack_result == 2u32 {
                board = empty_square(board, prev_move.target_x, prev_move.target_y);
            }
        }

        let piece: u64 = get_piece(board, target_x, target_y);
        let flag_x: u64 = piece == 12u64 ? state.flag_x : 5u64;
        let flag_y: u32 = piece == 12u64 ? state.flag_y : 0u32;

        let new_state: player_state = player_state {
            owner: self.caller,
            gates: 0u64,
            game_id: state.game_id,
            board: board,
            game_winner: 0u32,
            flag_x: state.flag_x,
            flag_y: state.flag_y,
            arbiter: state.arbiter,
            player_index: state.player_index,
        };

        return (new_state, piece_info {
            owner: state.arbiter,
            gates: 0u64,
            game_id: state.game_id,
            player: state.owner,
            piece: piece,
            x: target_x,
            y: target_y,
            flag_x: flag_x,
            flag_y: flag_y,
        });
    }

    inline place_piece(board: board_state, x: u64, y: u32, piece: u64) -> board_state {
        let line: u64 = get_line(board, x);
        let shifted_piece: u64 = piece << (y * 4u32);
        let new_line: u64 = line | shifted_piece;
        let new_board: board_state = set_line(board, x, new_line);
        return new_board;
    }

    inline empty_square(board: board_state, x: u64, y: u32) -> board_state {
        let line: u64 = get_line(board, x);
        let mask: u64 = 15u64 << (y * 4u32);
        let new_line: u64 = line & (mask ^ 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFu64);
        let new_board: board_state = set_line(board, x, new_line);
        return new_board;
    }

    inline set_line(board: board_state, x: u64, line: u64) -> board_state {
        if x == 0u64 {
            return board_state {
                line0: line,
                line1: board.line1,
                line2: board.line2,
                line3: board.line3,
                line4: board.line4,
            };
        } else if x == 1u64 {
            return board_state {
                line0: board.line0,
                line1: line,
                line2: board.line2,
                line3: board.line3,
                line4: board.line4,
            };
        } else if x == 2u64 {
            return board_state {
                line0: board.line0,
                line1: board.line1,
                line2: line,
                line3: board.line3,
                line4: board.line4,
            };
        } else if x == 3u64 {
            return board_state {
                line0: board.line0,
                line1: board.line1,
                line2: board.line2,
                line3: line,
                line4: board.line4,
            };
        } else {
            return board_state {
                line0: board.line0,
                line1: board.line1,
                line2: board.line2,
                line3: board.line3,
                line4: line,
            };
        }
    }

    transition transfer(
        to: address,
        value: u64
    ) -> bool {
        let success: bool = signed_call(self.caller, to, value, []);
        if !success {
            return false;
        }
        return true;
    }

    transition withdraw(
        to: address,
        amount: u64
    ) -> bool {
        let success: bool = withdraw_balance(self.caller, to, amount);
        if !success {
            return false;
        }
        return true;
    }
}

import credits.leo;

// The 'Aswap' program.
program aswap.aleo {
    record PrivateToken {
        // The token owner
        owner: address,
        // The token index
        id: u128,
        // The token amount
        amount: u128,
    }

    struct BalanceKey {
        token: u128,
        from: address,
    }

    struct AllowanceKey {
        token: u128,
        from: address,
    }

    struct TokenInfo {
        id: u128,
        decimals: u8,
        total_supply: u128,
    }

    struct BalanceInfo {
        token: u128,
        amount: u128,
    }

    struct AllowanceInfo {
        token: u128,
        spender: address,
        amount: u128,
    }

    struct Pair {
        token_a: u128,
        token_b: u128,
        reserve_a: u128,
        reserve_b: u128,
    }
    
    mapping tokens : u128 => TokenInfo;
    mapping balances: BalanceKey => BalanceInfo;
    mapping allowance: AllowanceKey => AllowanceInfo;
    mapping pairs : u128 => Pair;


    // ========================= Token Operation ========================= // 
    // Create a new token.
    transition create_token(public info: TokenInfo, token_id: u128,) {
        return then finalize(info, token_id);
    }
    finalize create_token(public info: TokenInfo, token_id: u128) {
        Mapping::set(tokens, token_id, info);
    }

    // Transfer public tokens.
    transition transfer(public token_id: u128, public to: address, public amount: u128) {
        return then finalize(token_id, self.caller, to, amount);
    }
    finalize transfer(public token_id: u128, public from: address, public to: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let balance_key_from : BalanceKey = BalanceKey {
            token: token_id,
            from: from,
        };
        let bal_from: BalanceInfo = Mapping::get(balances, balance_key_from);
        let newBalanceInfoFrom : BalanceInfo = BalanceInfo {
            token: token_id,
            amount: bal_from.amount - amount,
        };
        Mapping::set(balances, balance_key_from, newBalanceInfoFrom);

        let balance_key_to : BalanceKey = BalanceKey {
            token: token_id,
            from: to,
        };
        let bal_to: BalanceInfo = Mapping::get(balances, balance_key_to);
        let newBalanceInfoTo : BalanceInfo = BalanceInfo {
            token: token_id,
            amount: bal_to.amount + amount,
        };
        Mapping::set(balances, balance_key_to, newBalanceInfoTo);
    }

    // Authorize other accounts to spend tokens.
    transition approve(public token_info: TokenInfo, public spender: address, public amount: u128) {
        return then finalize(token_info, self.caller, spender, amount);
    }
    finalize approve(public token_info: TokenInfo, public caller: address, public spender: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_info.id));
        let allowanceObj : AllowanceInfo = AllowanceInfo {
            token: token_info.id,
            spender: spender,
            amount: amount,
        };
        Mapping::set(allowance, caller, allowanceObj);
    }

    // Transfer public tokens from other accounts.
    transition transfer_from(
        public token_info: TokenInfo,
        public from: address,
        public to: address,
        public amount: u128
     ) {
        return then finalize(self.caller, token_info, from, to, amount);
    }
    finalize transfer_from(
        public caller: address,
        public token_info: TokenInfo,
        public from: address,
        public to: address,
        public amount: u128
    ) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_info.id));
        let allowance_key_from : AllowanceKey = AllowanceKey {
            token: token_info.id,
            from: from,
        };
        let balance_key_from : BalanceKey = BalanceKey {
            token: token_info.id,
            from: from,
        };
        let new_allowance_sender : AllowanceInfo = AllowanceInfo {
            token: token_info.id,
            spender: from,
            amount: Mapping::get(allowance, allowance_key_from).amount - amount,
        };
        Mapping::set(allowance, allowance_key_from, new_allowance_sender);
        let new_balance_sender : BalanceInfo = BalanceInfo {
            token: token_info.id,
            amount: Mapping::get(balances, balance_key_from).amount - amount,
        }; 
        Mapping::set(balances, balance_key_from, new_balance_sender);

        let balance_key_to : BalanceKey = BalanceKey {
            token: token_info.id,
            from: to,
        };
        let new_balance_receiver : BalanceInfo = BalanceInfo {
            token: token_info.id,
            amount: Mapping::get(balances, balance_key_to).amount + amount,
        };
        Mapping::set(balances, balance_key_to, new_balance_receiver);
    }

    // Transfer and convert public tokens to a new private token record (PrivateToken).
    transition transfer_to_private(public token_id: u128, private to: address, public amount: u128) -> PrivateToken {
        // mint a new private token
        let pt: PrivateToken = PrivateToken {
            owner: to,
            id: token_id,
            amount: amount,
        };
        return pt then finalize(token_id, self.caller, amount);
    }
    finalize transfer_to_private(public token_id: u128, public from: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let balance_key_from : BalanceKey = BalanceKey {
            token: token_id,
            from: from,
        };
        let new_balance_from : BalanceInfo = BalanceInfo {
            token: token_id,
            amount: Mapping::get(balances, balance_key_from).amount - amount,
        };
        Mapping::set(balances, balance_key_from, new_balance_from);
    }

    // Transfer and convert a private token record (`PrivateToken`) to public tokens.
    transition transfer_to_public(private pt_in: PrivateToken, public to: address, public amount: u128) -> PrivateToken {
        let pt_change: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            id: pt_in.id,
            amount: pt_in.amount - amount,
        };
        return pt_change then finalize(pt_in.id, to, amount);
    }
    finalize transfer_to_public(public token_id: u128, public to: address, public amount: u128) {
        // confirm token exists
        assert(Mapping::contains(tokens, token_id));
        let balance_key_to : BalanceKey = BalanceKey {
            token: token_id,
            from: to,
        };
        let new_balance_to : BalanceInfo = BalanceInfo {
            token: token_id,
            amount: Mapping::get(balances, balance_key_to).amount + amount,
        };
        Mapping::set(balances, balance_key_to, new_balance_to);
    }

    // Transfer private tokens (`PrivateToken` records).
    transition transfer_privately(private pt_in: PrivateToken, private to: address, private amount: u128) -> (PrivateToken, PrivateToken) {
        let pt_to: PrivateToken = PrivateToken {
            owner: to,
            id: pt_in.id,
            amount: amount,
        };

        let pt_change: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            id: pt_in.id,
            amount: pt_in.amount - amount,
        };
        return (pt_to, pt_change);
    }

    // Merge two `PrivateToken` records into a new `PrivateToken` record.
    // The two records being joined must have the same owner and the token id.
    transition join(private pt1: PrivateToken, private pt2: PrivateToken) -> PrivateToken {
        assert_eq(pt1.id, pt2.id);
        assert_eq(pt1.owner, pt2.owner);
        assert_eq(pt1.owner, self.caller);
        return PrivateToken {
            owner: pt1.owner,
            id: pt1.id,
            amount: pt1.amount + pt2.amount,
        };
    }

    // ========================= Create Pair ========================= //
    transition create_pair(
        public token_a: u128,
        public token_b: u128,
        public amount_a: u128,
        public amount_b: u128,
        public pid: u128
     ) {
        assert(token_a < token_b);
        assert(amount_a > 0u128);
        assert(amount_b > 0u128);
        return then finalize(self.caller, token_a, token_b, amount_a, amount_b, pid);
    }
    finalize create_pair(
        public caller: address,
        public token_a: u128,
        public token_b: u128,
        public amount_a: u128,
        public amount_b: u128,
        public pid: u128
    ) {
        let liquidity: u128 = sqrt_u128(amount_a * amount_b);
        assert(liquidity > 0u128);
        let balance_key_a : BalanceKey = BalanceKey {
            token: token_a,
            from: caller,
        };
        let balance_key_b : BalanceKey = BalanceKey {
            token: token_b,
            from: caller,
        };
        assert(Mapping::get(balances, balance_key_a).amount > amount_a);
        assert(Mapping::get(balances, balance_key_b).amount > amount_b);
        assert(!Mapping::contains(pairs, pid));

        let token_pair: Pair = Pair {
            token_a: token_a,
            token_b: token_b,
            reserve_a: amount_a,
            reserve_b: amount_b,
        };

        Mapping::set(pairs, pid, token_pair);

        // update balances
        let new_balance_info_a : BalanceInfo = BalanceInfo {
            token: token_a,
            amount: Mapping::get(balances, balance_key_a).amount - amount_a,
        };
        let new_balance_info_b : BalanceInfo = BalanceInfo {
            token: token_b,
            amount: Mapping::get(balances, balance_key_b).amount - amount_b,
        };
        Mapping::set(balances, balance_key_a, new_balance_info_a);
        Mapping::set(balances, balance_key_b,new_balance_info_b);

        // update pair
        Mapping::set(pairs, pid, Pair {
            token_a: token_a,
            token_b: token_b,
            reserve_a: token_pair.reserve_a + amount_a,
            reserve_b: token_pair.reserve_b + amount_b,
        });
    }

    // // Create a new pair and add initial liquidity privately.
    // transition create_pair_privately(
    //     private pt_a: PrivateToken,
    //     private pt_b: PrivateToken,
    //     public amount_a: u128,
    //     public amount_b: u128,
    //     private to: address,
    //     public liquidity: u128,
    //  ) -> (PrivateToken, PrivateToken, PrivateToken) {
    //     let token_a: field = pt_a.token;
    //     let token_b: field = pt_b.token;
    //     assert(token_a < token_b);
    //     assert(amount_a > 0u128);
    //     assert(amount_b > 0u128);
    //     assert(liquidity > 0u128);
    //     let change_a: PrivateToken = PrivateToken {
    //         owner: pt_a.owner,
    //         token: token_a,
    //         amount: pt_a.amount - amount_a,
    //     };
    //     let change_b: PrivateToken = PrivateToken {
    //         owner: pt_b.owner,
    //         token: token_b,
    //         amount: pt_b.amount - amount_b,
    //     };

    //     let pt_lp: PrivateToken = PrivateToken {
    //         owner: to,
    //         token: pid,
    //         amount: liquidity,
    //     };
    //     return (pt_lp, change_a, change_b) then finalize(token_a, token_b, amount_a, amount_b, pid, liquidity);
    // }
    // finalize create_pair_privately(
    //     public token_a: field,
    //     public token_b: field,
    //     public amount_a: u128,
    //     public amount_b: u128,
    //     public pid: field,
    //     public liquidity_in: u128,
    // ) {
    //     let liquidity: u128 = sqrt_u128(amount_a * amount_b);
    //     assert(liquidity_in == liquidity);

    //     let ti_pair: TokenInfo = Mapping::get_or_use(tokens, pid, TokenInfo {
    //         name: 5183377571718029925300968712562field, // AleoSwap-Pair
    //         symbol: 4281168field, // ASP
    //         decimals: 6u8,
    //         total_supply: 0u128,
    //         admin: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
    //     });
    //     assert_eq(ti_pair.total_supply, 0u128);

    //     let pair: Pair = Mapping::get_or_use(pairs, pid, Pair {
    //         reserve_a: 0u128,
    //         reserve_b: 0u128,
    //     });

    //     // mint liquidity
    //     Mapping::set(tokens, pid, TokenInfo {
    //         name: ti_pair.name,
    //         symbol: ti_pair.symbol,
    //         decimals: ti_pair.decimals,
    //         total_supply: ti_pair.total_supply + liquidity,
    //         admin: ti_pair.admin,
    //     });

    //     // update pair
    //     Mapping::set(pairs, pid, Pair {
    //         reserve_a: pair.reserve_a + amount_a,
    //         reserve_b: pair.reserve_b + amount_b,
    //     });
    // }


    // ========================= Add Liquidity ========================= //
    // Add liquidity to a pair.
    // The caller's `token_a` and `token_b` will be transferred to the program, and LP tokens will be minted to the `to` address.
    transition add_liquidity(
        public token_a: u128,
        public token_b: u128,
        public amount_a: u128,
        public amount_b: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address
     ) {
        assert(token_a < token_b);
        assert(amount_a > 0u128 && amount_a >= min_a);
        assert(amount_b > 0u128 && amount_b >= min_b);
        return then finalize(self.caller, token_a, token_b, amount_a, amount_b, min_a, min_b, to);
    }
    finalize add_liquidity(
        public caller: address,
        public token_a: field,
        public token_b: field,
        public amount_a: u128,
        public amount_b: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address
    ) {
        let pair: Pair = Mapping::get(pairs, pid);
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let liq_a: u128 = amount_a * ti_pair.total_supply / pair.reserve_a;
        let liq_b: u128 = amount_b * ti_pair.total_supply / pair.reserve_b;
        let liquidity: u128 = liq_a <= liq_b ? liq_a : liq_b;
        amount_a = liq_a <= liquidity
                ? amount_a
                : (liquidity * pair.reserve_a + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        amount_b = liq_b <= liquidity
                ? amount_b
                : (liquidity * pair.reserve_b + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        assert(liquidity > 0u128);
        assert(amount_a >= min_a);
        assert(amount_b >= min_b);

        // update balances
        Mapping::set(balances, bid_a, Mapping::get(balances, bid_a) - amount_a);
        Mapping::set(balances, bid_b, Mapping::get(balances, bid_b) - amount_b);

        // mint liquidity
        Mapping::set(balances, bid_p, Mapping::get_or_use(balances, bid_p, 0u128) + liquidity);
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply + liquidity,
            admin: ti_pair.admin,
        });

        // update pair
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a + amount_a,
            reserve_b: pair.reserve_b + amount_b,
        });
    }

    // Add liquidity to a pair privately.
    transition add_liquidity_privately(
        private pt_a: PrivateToken,
        private pt_b: PrivateToken,
        public amount_a: u128,
        public amount_b: u128,
        public min_a: u128,
        public min_b: u128,
        public min_liquidity: u128,
        private to: address,
        public refund_to: address,
     ) -> (PrivateToken, PrivateToken, PrivateToken) {
        let token_a: field = pt_a.token;
        let token_b: field = pt_b.token;
        assert(token_a < token_b);
        assert(amount_a > 0u128 && amount_a >= min_a);
        assert(amount_b > 0u128 && amount_b >= min_b);
        assert(min_liquidity > 0u128);

        // change
        let change_a: PrivateToken = PrivateToken {
            owner: pt_a.owner,
            token: token_a,
            amount: pt_a.amount - amount_a,
        };
        let change_b: PrivateToken = PrivateToken {
            owner: pt_b.owner,
            token: token_b,
            amount: pt_b.amount - amount_b,
        };

        // mint lp token
        let pt_lp: PrivateToken = PrivateToken {
            owner: to,
            token: pid,
            amount: min_liquidity,
        };

        return (pt_lp, change_a, change_b) then finalize(token_a, token_b, pid, amount_a, amount_b, min_a, min_b, min_liquidity, refund_to);
    }

    finalize add_liquidity_privately(
        public token_a: field,
        public token_b: field,
        public pid: field,
        public amount_a: u128,
        public amount_b: u128,
        public min_a: u128,
        public min_b: u128,
        public min_liquidity: u128,
        public refund_to: address,
    ) {
        let pair: Pair = Mapping::get(pairs, pid);
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let liq_a: u128 = amount_a * ti_pair.total_supply / pair.reserve_a;
        let liq_b: u128 = amount_b * ti_pair.total_supply / pair.reserve_b;
        let liquidity: u128 = liq_a <= liq_b ? liq_a : liq_b;
        let amount_a_used: u128 = liq_a <= liquidity
                ? amount_a
                : (liquidity * pair.reserve_a + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        let amount_b_used: u128 = liq_b <= liquidity
                ? amount_b
                : (liquidity * pair.reserve_b + ti_pair.total_supply - 1u128) / ti_pair.total_supply;
        assert(liquidity >= min_liquidity);
        assert(amount_a >= amount_a_used && amount_a_used >= min_a);
        assert(amount_b >= amount_b_used && amount_b_used >= min_b);

        // refund tokens
        Mapping::set(balances, bid_a, Mapping::get_or_use(balances, bid_a, 0u128) + amount_a - amount_a_used);
        Mapping::set(balances, bid_b, Mapping::get_or_use(balances, bid_b, 0u128) + amount_b - amount_b_used);

        // refund liquidity
        Mapping::set(balances, bid_p, Mapping::get_or_use(balances, bid_p, 0u128) + liquidity - min_liquidity);

        // set liquidity supply
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply + liquidity,
            admin: ti_pair.admin,
        });

        // update pair
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a + amount_a_used,
            reserve_b: pair.reserve_b + amount_b_used,
        });
    }

    // ========================= Remove Liquidity ========================= //
    // Remove liquidity from a pair.
    // The caller's LP tokens will be burned, `token_a` and `token_b` will be transferred to the `to` address.
    transition remove_liquidity(
        public token_a: field,
        public token_b: field,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address,
     ) {
        assert(token_a < token_b);
        assert(liquidity > 0u128);
        return then finalize(self.caller, token_a, token_b, liquidity, min_a, min_b, to);
    }

    finalize remove_liquidity(
        public caller: address,
        public token_a: field,
        public token_b: field,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        public to: address,
    ) {
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate token amounts
        let amount_a: u128 = liquidity * pair.reserve_a / ti_pair.total_supply;
        let amount_b: u128 = liquidity * pair.reserve_b / ti_pair.total_supply;
        assert(amount_a >= min_a && amount_b >= min_b);
        assert(amount_a > 0u128 || amount_b > 0u128);

        // burn liquidity
        Mapping::set(balances, bid_p, Mapping::get(balances, bid_p) - liquidity);
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply - liquidity,
            admin: ti_pair.admin,
        });

        // update pair
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a - amount_a,
            reserve_b: pair.reserve_b - amount_b,
        });

        // send tokens
        Mapping::set(balances, bid_a, Mapping::get_or_use(balances, bid_a, 0u128) + amount_a);
        Mapping::set(balances, bid_b, Mapping::get_or_use(balances, bid_b, 0u128) + amount_b);
    }

    // Remove liquidity from a pair.
    transition remove_liquidity_privately(
        public token_a: field,
        public token_b: field,
        private pt_lp: PrivateToken,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        private to: address,
        public refund_to: address,
     ) -> (PrivateToken, PrivateToken, PrivateToken) {
        assert(token_a < token_b);
        assert(liquidity > 0u128);
        // check pair id and lp token
        assert_eq(pid, pt_lp.token);

        // mint tokens
        let pt_a: PrivateToken = PrivateToken {
            owner: to,
            token: token_a,
            amount: min_a,
        };
        let pt_b: PrivateToken = PrivateToken {
            owner: to,
            token: token_b,
            amount: min_b,
        };

        // change
        let change_lp: PrivateToken = PrivateToken {
            owner: pt_lp.owner,
            token: pid,
            amount: pt_lp.amount - liquidity,
        };

        return (pt_a, pt_b, change_lp) then finalize(token_a, token_b, pid, liquidity, min_a, min_b, refund_to);
    }

    finalize remove_liquidity_privately(
        public token_a: field,
        public token_b: field,
        public pid: field,
        public liquidity: u128,
        public min_a: u128,
        public min_b: u128,
        public refund_to: address,
    ) {
        let ti_pair: TokenInfo = Mapping::get(tokens, pid);
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate token amounts
        let amount_a: u128 = liquidity * pair.reserve_a / ti_pair.total_supply;
        let amount_b: u128 = liquidity * pair.reserve_b / ti_pair.total_supply;
        assert(amount_a >= min_a && amount_b >= min_b);
        assert(amount_a > 0u128 || amount_b > 0u128);

        // liquidity has been burned privately

        // update pair
        Mapping::set(tokens, pid, TokenInfo {
            name: ti_pair.name,
            symbol: ti_pair.symbol,
            decimals: ti_pair.decimals,
            total_supply: ti_pair.total_supply - liquidity,
            admin: ti_pair.admin,
        });
        Mapping::set(pairs, pid, Pair {
            reserve_a: pair.reserve_a - amount_a,
            reserve_b: pair.reserve_b - amount_b,
        });

        // refund tokens
     
        Mapping::set(balances, bid_a, Mapping::get_or_use(balances, bid_a, 0u128) + amount_a - min_a);
        Mapping::set(balances, bid_b, Mapping::get_or_use(balances, bid_b, 0u128) + amount_b - min_b);
    }

    // ========================= swap exact ========================= //
    // Exchange a fixed amount of public input tokens for a variable amount of public output tokens.
    transition swap_exact_tokens_for_tokens(
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
     ) {
        assert(token_in != token_out);
        assert(amount_in > 0u128);
        return then finalize(self.caller, token_in, token_out, amount_in, amount_out_min, to);
    }

    finalize swap_exact_tokens_for_tokens(
        public caller: address,
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate output amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in_with_fee: u128 = amount_in * 997u128;
        let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 1000u128 + amount_in_with_fee);
        assert(amount_out >= amount_out_min);
        assert(amount_out > 0u128);

        // transfer input token
        Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out);
    }

    // Exchange a fixed amount of private input tokens for a variable amount of public output tokens.
    transition swap_exact_private_for_public(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
     ) -> (PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_in > 0u128);

        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in,
        };
        return change_in then finalize(token_in, token_out, amount_in, amount_out_min, to);
    }

    finalize swap_exact_private_for_public(
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate output amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in_with_fee: u128 = amount_in * 997u128;
        let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 1000u128 + amount_in_with_fee);
        assert(amount_out >= amount_out_min);
        assert(amount_out > 0u128);

        // input token has been transferred privately

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out);
    }

    // Exchange a fixed amount of private input tokens for a variable amount of private output tokens.
    transition swap_exact_private_for_private(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        private to_pri: address,
        public to_pub: address,
     ) -> (PrivateToken, PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_in > 0u128);
        let pt_out: PrivateToken = PrivateToken {
            owner: to_pri,
            token: token_out,
            amount: amount_out_min,
        };
        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in,
        };
        return (pt_out, change_in) then finalize(token_in, token_out, amount_in, amount_out_min, to_pub);
    }

    finalize swap_exact_private_for_private(
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate output amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in_with_fee: u128 = amount_in * 997u128;
        let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 1000u128 + amount_in_with_fee);
        assert(amount_out >= amount_out_min);
        assert(amount_out > 0u128);

        // input token has been transferred privately

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token (minus the private part)
        let amount_out_diff: u128 = amount_out - amount_out_min;
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out_diff);
    }

    // // Exchange a fixed amount of public input tokens for a variable amount of private output tokens.
    // transition swap_exact_public_for_private(
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in: u128,
    //     public amount_out_min: u128,
    //     private to_pri: address,
    //     public to_pub: address,
    //  ) -> (PrivateToken) {
    //     assert(token_in != token_out);
    //     assert(amount_in > 0u128);

    //     let pt_out: PrivateToken = PrivateToken {
    //         owner: to_pri,
    //         token: token_out,
    //         amount: amount_out_min,
    //     };
    //     return pt_out then finalize(self.caller, token_in, token_out, amount_in, amount_out_min, to_pub);
    // }

    // finalize swap_exact_public_for_private(
    //     public caller: address,
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in: u128,
    //     public amount_out_min: u128,
    //     public to_pub: address,
    // ) {
    //     let token_a: field = token_in < token_out ? token_in : token_out;
    //     let token_b: field = token_in < token_out ? token_out : token_in;
    //     let pair: Pair = Mapping::get(pairs, pid);

    //     // calculate output amount
    //     let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
    //     let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
    //     let amount_in_with_fee: u128 = amount_in * 997u128;
    //     let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 1000u128 + amount_in_with_fee);
    //     assert(amount_out >= amount_out_min);
    //     assert(amount_out > 0u128);

    //     // transfer input token
    //     Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

    //     // update pair
    //     let reserve_in_new: u128 = reserve_in + amount_in;
    //     let reserve_out_new: u128 = reserve_out - amount_out;
    //     Mapping::set(pairs, pid, Pair {
    //         reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
    //         reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
    //     });

    //     // transfer output token(minus the private part)
    //     let amount_out_diff: u128 = amount_out - amount_out_min;
    //     Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out_diff);
    // }

    // ========================= swap for exact ========================= //
    transition swap_tokens_for_exact_tokens(
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
     ) {
        assert(token_in != token_out);
        assert(amount_out > 0u128);
        return then finalize(self.caller, token_in, token_out, amount_in_max, amount_out, to);
    }

    finalize swap_tokens_for_exact_tokens(
        public caller: address,
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate input amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in: u128 = reserve_in * amount_out * 1000u128 / ((reserve_out - amount_out) * 997u128) + 1u128;
        assert(amount_in <= amount_in_max);
        assert(amount_in > 0u128);

        // transfer input token
        Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out);
    }

    // Exchange a variable amount of private input tokens for a fixed amount of public output tokens.
    transition swap_private_for_exact_public(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
        public refund_to: address,
     ) -> (PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_out > 0u128);

        // All amount_in_max is transferred, any excess will be returned in public
        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in_max,
        };

        return change_in then finalize(token_in, token_out, amount_in_max, amount_out, to, refund_to);
    }

    finalize swap_private_for_exact_public(
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
        public refund_to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate input amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in: u128 = reserve_in * amount_out * 1000u128 / ((reserve_out - amount_out) * 997u128) + 1u128;
        assert(amount_in <= amount_in_max);
        assert(amount_in > 0u128);

        // refund input token
        let refund_amount: u128 = amount_in_max - amount_in;
        Mapping::set(balances, bid_refund, Mapping::get_or_use(balances, bid_refund, 0u128) + refund_amount);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        Mapping::set(balances, bid_out, Mapping::get_or_use(balances, bid_out, 0u128) + amount_out);
    }

    // Exchange a variable amount of private input tokens for a fixed amount of private output tokens.
    transition swap_private_for_exact_private(
        private pt_in: PrivateToken,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        private to_pri: address,
        public refund_to: address,
     ) -> (PrivateToken, PrivateToken) {
        let token_in: field = pt_in.token;
        assert(token_in != token_out);
        assert(amount_out > 0u128);
        let pt_out: PrivateToken = PrivateToken {
            owner: to_pri,
            token: token_out,
            amount: amount_out,
        };
        // All amount_in_max is transferred, any excess will be returned in public
        let change_in: PrivateToken = PrivateToken {
            owner: pt_in.owner,
            token: token_in,
            amount: pt_in.amount - amount_in_max,
        };
        return (pt_out, change_in) then finalize(token_in, token_out, amount_in_max, amount_out, refund_to);
    }

    finalize swap_private_for_exact_private(
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public refund_to: address,
    ) {
        let token_a: field = token_in < token_out ? token_in : token_out;
        let token_b: field = token_in < token_out ? token_out : token_in;
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate input amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in: u128 = reserve_in * amount_out * 1000u128 / ((reserve_out - amount_out) * 997u128) + 1u128;
        assert(amount_in <= amount_in_max);
        assert(amount_in > 0u128);

        // refund input token
        let refund_amount: u128 = amount_in_max - amount_in;
        Mapping::set(balances, bid_refund, Mapping::get_or_use(balances, bid_refund, 0u128) + refund_amount);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // output token has been transferred privately
    }

    // // Exchange a variable amount of public input tokens for a fixed amount of private output tokens.
    // transition swap_public_for_exact_private(
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in_max: u128,
    //     public amount_out: u128,
    //     private to_pri: address,
    //  ) -> (PrivateToken) {
    //     assert(token_in != token_out);
    //     assert(amount_out > 0u128);
    //     let pt_out: PrivateToken = PrivateToken {
    //         owner: to_pri,
    //         token: token_out,
    //         amount: amount_out,
    //     };
    //     return pt_out then finalize(self.caller, token_in, token_out, amount_in_max, amount_out);
    // }

    // finalize swap_public_for_exact_private(
    //     public caller: address,
    //     public token_in: field,
    //     public token_out: field,
    //     public amount_in_max: u128,
    //     public amount_out: u128,
    // ) {
    //     let token_a: field = token_in < token_out ? token_in : token_out;
    //     let token_b: field = token_in < token_out ? token_out : token_in;
    //     let pair: Pair = Mapping::get(pairs, pid);

    //     // calculate input amount
    //     let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
    //     let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
    //     let amount_in: u128 = reserve_in * amount_out * 1000u128 / ((reserve_out - amount_out) * 997u128) + 1u128;
    //     assert(amount_in <= amount_in_max);
    //     assert(amount_in > 0u128);

    //     // transfer input token
    //     Mapping::set(balances, bid_in, Mapping::get(balances, bid_in) - amount_in);

    //     // update pair
    //     let reserve_in_new: u128 = reserve_in + amount_in;
    //     let reserve_out_new: u128 = reserve_out - amount_out;
    //     Mapping::set(pairs, pid, Pair {
    //         reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
    //         reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
    //     });

    //     // output token has been transferred privately
    // }


    // ========================= Inline functions ========================= //
    // sqrt for u128
    inline sqrt_u128(a: u128) -> u128 {
        if (a == 0u128) {
            return 0u128;
        }
        let result: u128 = 1u128.shl(log2(a) / 2u32);

        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        return min_u128(result, a / result);
    }

    // log2 for u128
    inline log2(value: u128) -> u32 {
        let result: u32 = 0u32;
        // if value >> 128u32 > 0u128 {
        //     value >>= 128u32;
        //     result += 12832;
        // }
        if value >> 64u32 > 0u32 {
            value >>= 64u32;
            result += 64u32;
        }
        if value >> 32u32 > 0u32 {
            value >>= 32u32;
            result += 32u32;
        }
        if value >> 16u32 > 0u32 {
            value >>= 16u32;
            result += 16u32;
        }
        if value >> 8u32 > 0u32 {
            value >>= 8u32;
            result += 8u32;
        }
        if value >> 4u32 > 0u32 {
            value >>= 4u32;
            result += 4u32;
        }
        if value >> 2u32 > 0u32 {
            value >>= 2u32;
            result += 2u32;
        }
        if value >> 1u32 > 0u128 {
            result += 1u32;
        }
        return result;
    }

    // min for u128
    inline min_u128(a: u128, b: u128) -> u128 {
        return a < b ? a : b;
    }
}
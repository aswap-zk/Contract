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

    struct LiquidityKey {
        pair: Pair,
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

    struct LiquidityInfo {
        token_a_amount: u128,
        token_b_amount: u128,
    }
    
    mapping tokens : u128 => TokenInfo;
    mapping balances: BalanceKey => BalanceInfo;
    mapping allowance: AllowanceKey => AllowanceInfo;
    mapping pairs : u128 => Pair;
    mapping liquidity_info: LiquidityKey => LiquidityInfo;


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
        let allowance_key : AllowanceKey = AllowanceKey {
            token: token_info.id,
            from: caller,
        };
        let allowanceObj : AllowanceInfo = AllowanceInfo {
            token: token_info.id,
            spender: spender,
            amount: amount,
        };
        Mapping::set(allowance, allowance_key, allowanceObj);
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

    // ========================= Add Liquidity ========================= //
    // Add liquidity to a pair.
    // The caller's `token_a` and `token_b` will be transferred to the program, and LP tokens will be minted to the `to` address.
    transition add_liquidity_pair(
        public token_a: u128,
        public token_b: u128,
        public amount_a: u128,
        public amount_b: u128,
        public min_b: u128,
        public pid: u128,
     ) {
        assert(token_a < token_b);
        assert(amount_a > 0u128);
        assert(amount_b > 0u128 && amount_b >= min_b);
        return then finalize(self.caller, token_a, token_b, amount_a, amount_b, min_b, pid);
    }
    finalize add_liquidity_pair(
        public caller: address,
        public token_a: u128,
        public token_b: u128,
        public amount_a: u128,
        public amount_b: u128,
        public min_b: u128,
        public pid: u128,
    ) {
        let pair: Pair = Mapping::get(pairs, pid);
        // check if tokens are properly given
        assert(pair.token_a == token_a && pair.token_b == token_b);
        let liq_a: u128 = pair.reserve_a;
        let liq_b: u128 = pair.reserve_b;
        amount_b = amount_a * liq_b / liq_a;

        // update balances
        let balance_key_a : BalanceKey = BalanceKey {
            token: token_a,
            from: caller,
        };
        let balance_key_b : BalanceKey = BalanceKey {
            token: token_b,
            from: caller,
        };
        let new_balance_info_a : BalanceInfo = BalanceInfo {
            token: token_a,
            amount: Mapping::get(balances, balance_key_a).amount - amount_a,
        };
        let new_balance_info_b : BalanceInfo = BalanceInfo {
            token: token_b,
            amount: Mapping::get(balances, balance_key_b).amount - amount_b,
        };
        Mapping::set(balances, balance_key_a, new_balance_info_a);
        Mapping::set(balances, balance_key_b, new_balance_info_b);

        // update pair
        Mapping::set(pairs, pid, Pair {
            token_a: token_a,
            token_b: token_b,
            reserve_a: pair.reserve_a + amount_a,
            reserve_b: pair.reserve_b + amount_b,
        });

        // update liquidity info
        let liquidity_key : LiquidityKey = LiquidityKey {
            pair: pair,
            from: caller,
        };

        Mapping::set(liquidity_info, liquidity_key, LiquidityInfo {
            token_a_amount: amount_a,
            token_b_amount: amount_b,
        }); 
    }

    // ========================= Remove Liquidity ========================= //
    // Remove liquidity from a pair.
    // The caller's LP tokens will be burned, `token_a` and `token_b` will be transferred to the `to` address.
    transition remove_liquidity_pair(
        public token_a: u128,
        public token_b: u128,
        public liquidity: u128,
        public min_b: u128,
        public pid: u128,
     ) {
        assert(token_a < token_b);
        assert(liquidity > 0u128);
        return then finalize(self.caller, token_a, token_b, liquidity, min_b, pid);
    }
    finalize remove_liquidity_pair(
        public caller: address,
        public token_a: u128,
        public token_b: u128,
        public liquidity: u128,
        public min_b: u128,
        public pid: u128
    ) {
        let pair: Pair = Mapping::get(pairs, pid);

        // // calculate token amounts
        // let amount_a: u128 = liquidity * pair.reserve_a / ti_pair.total_supply;
        // let amount_b: u128 = liquidity * pair.reserve_b / ti_pair.total_supply;
        // assert(amount_a >= min_a && amount_b >= min_b);
        // assert(amount_a > 0u128 || amount_b > 0u128);

        // // burn liquidity
        // Mapping::set(balances, bid_p, Mapping::get(balances, bid_p) - liquidity);
        // Mapping::set(tokens, pid, TokenInfo {
        //     name: ti_pair.name,
        //     symbol: ti_pair.symbol,
        //     decimals: ti_pair.decimals,
        //     total_supply: ti_pair.total_supply - liquidity,
        //     admin: ti_pair.admin,
        // });

        // // update pair
        // Mapping::set(pairs, pid, Pair {
        //     reserve_a: pair.reserve_a - amount_a,
        //     reserve_b: pair.reserve_b - amount_b,
        // });

        // // send tokens
        // Mapping::set(balances, bid_a, Mapping::get_or_use(balances, bid_a, 0u128) + amount_a);
        // Mapping::set(balances, bid_b, Mapping::get_or_use(balances, bid_b, 0u128) + amount_b);
    }

    // ========================= swap exact ========================= //
    // Exchange a fixed amount of public input tokens for a variable amount of public output tokens.
    transition swap_exact_tokens_for_tokens(
        public token_in: u128,
        public token_out: u128,
        public amount_in: u128,
        public amount_out_min: u128,
        public pid: u128,
     ) {
        assert(token_in != token_out);
        assert(amount_in > 0u128);
        return then finalize(self.caller, token_in, token_out, amount_in, amount_out_min, pid);
    }
    finalize swap_exact_tokens_for_tokens(
        public caller: address,
        public token_in: u128,
        public token_out: u128,
        public amount_in: u128,
        public amount_out_min: u128,
        public pid: u128,
    ) {
        let token_a: u128 = token_in < token_out ? token_in : token_out;
        let token_b: u128 = token_in < token_out ? token_out : token_in;
        let pair: Pair = Mapping::get(pairs, pid);

        // calculate output amount
        let reserve_in: u128 = token_a == token_in ? pair.reserve_a : pair.reserve_b;
        let reserve_out: u128 = token_a == token_out ? pair.reserve_a : pair.reserve_b;
        let amount_in_with_fee: u128 = amount_in * 997u128;
        let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 1000u128 + amount_in_with_fee);
        assert(amount_out >= amount_out_min);
        assert(amount_out > 0u128);

        // transfer input token
        let balance_key_in : BalanceKey = BalanceKey {
            token: token_in,
            from: caller,
        };
        let new_balance_info_in : BalanceInfo = BalanceInfo {
            token: token_in,
            amount: Mapping::get(balances, balance_key_in).amount - amount_in,
        };
        Mapping::set(balances, balance_key_in, new_balance_info_in);

        // update pair
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pairs, pid, Pair {
            token_a: token_a,
            token_b: token_b,
            reserve_a: token_a == token_in ? reserve_in_new : reserve_out_new,
            reserve_b: token_b == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        let balance_key_out : BalanceKey = BalanceKey {
            token: token_out,
            from: caller,
        };
        let new_balance_info_out : BalanceInfo = BalanceInfo {
            token: token_out,
            amount: Mapping::get(balances, balance_key_out).amount + amount_out,
        };

        Mapping::set(balances, balance_key_out, new_balance_info_out);
    }


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
        if value >> 128u32 > 0u128 {
            value >>= 128u128;
            result += 128u32;
        }
        if value >> 64u32 > 0u32 {
            value >>= 64u128;
            result += 64u32;
        }
        if value >> 32u32 > 0u32 {
            value >>= 32u128;
            result += 32u32;
        }
        if value >> 16u32 > 0u32 {
            value >>= 16u128;
            result += 16u32;
        }
        if value >> 8u32 > 0u32 {
            value >>= 8u128;
            result += 8u32;
        }
        if value >> 4u32 > 0u32 {
            value >>= 4u128;
            result += 4u32;
        }
        if value >> 2u32 > 0u32 {
            value >>= 2u128;
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
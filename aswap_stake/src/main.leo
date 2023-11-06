// The 'aswap_stake' program.
program aswap_stake.aleo {
    // Stake Aleo
    transition stakeAleo(public stakeAmount: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }
    finalize stakeToken(public a: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }   

    // Stake Token
    transition stakeToken(public stakeAmount: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }
    finalize stakeToken(public a: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }

    // Unstake Aleo
    transition unstakeAleo(public unstakeAmount: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }
    finalize unstakeAleo(public a: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }

    // Unstake Token
    transition unstakeToken(public unstakeAmount: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }
    finalize unstakeToken(public a: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }

    // Split reward to Stakers
    transition splitReward() => u32 {
        return 0;
    }
    finalize splitReward() => u32 {
        return 0;
    }

    // Stakers receive their reward
    transition receiveReward() => u32 {
        return 0;
    }
    finalize receiveReward() => u32 {
        return 0;
    }
}

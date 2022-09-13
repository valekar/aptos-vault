module example::reserve{

    use vault::reserve;

    // example coin
    struct WBTC has copy, drop, store {}

    // example deposit 
    public entry fun deposit<WBTC>(sender : &signer, amount : u64) {
        reserve::deposit_liquidity<WBTC>(sender, amount);
    }
    

    // example withdraw 
    public entry fun withdraw<WBTC>(sender : &signer, amount : u64) {
        reserve::withdraw_liquidity<WBTC>(sender, amount);
    }
    


}
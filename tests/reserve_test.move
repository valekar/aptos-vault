#[test_only]
module vault::reserve_test {

    use vault::mock_coin;
    use vault::reserve::{
        init_reserve,
        deposit_liquidity,
        withdraw_liquidity
        
    };
    use aptos_framework::coin;
    use std::signer;
    use vault::reserve;
    


    #[test(source = @vault, end_user = @0x3)]
    public fun test_init_reserve(source : &signer, end_user : &signer) {
        init_for_testing(source, end_user);

        let balance = coin::balance<mock_coin::WETH>(signer::address_of(end_user));

        assert!(balance == 50, 0);
        assert!(coin::is_account_registered<mock_coin::WETH>(signer::address_of(end_user)), 0);
    }

   
    #[test_only]
    public entry fun init_for_testing(source : &signer , end_user : &signer) {
        mock_coin::initialize<mock_coin::WETH>(source, 8);
        mock_coin::faucet_mint_to_script<mock_coin::WETH>(end_user, 50); // +50 
        init_reserve<mock_coin::WETH>(source, 8);

    }

   
    #[test(source = @vault ,end_user = @0x4 )]
    public entry fun deposit_liquidity_test(source : &signer , end_user : &signer){
       init_for_testing(source, end_user);
       deposit_liquidity<mock_coin::WETH>(end_user , 6); 
    }


    #[test(source = @vault , end_user = @0x4 )]
    public entry fun withdraw_liquidity_test(source : &signer , end_user : &signer){
        init_for_testing(source, end_user);
        deposit_liquidity<mock_coin::WETH>(end_user , 6);  // -6 
        
        let lp_balance = coin::balance<reserve::RToken<mock_coin::WETH>>(signer::address_of(end_user));
        assert!(lp_balance == 6, 0);

        withdraw_liquidity<mock_coin::WETH>(end_user, 3); // +3

        let balance = coin::balance<mock_coin::WETH>(signer::address_of(end_user));
        assert!(balance == 50 - 6 + 3, 0);


    }


}
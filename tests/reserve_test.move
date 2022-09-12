

#[test_only]
module vault::reserve_test {

    use vault::mock_coin;
    use vault::reserve::{
        init_reserve,
        deposit_liquidity,
        withdraw_liquidity,
        pause_reserve,
        unpause_reserve
        
    };
    use aptos_framework::coin;
    use std::signer;
    use vault::reserve;
    
    // Init the module for testing
    // This method is common and is used in the rest of the code
    #[test_only]
    public entry fun init_for_testing(source : &signer , end_user : &signer) {
        mock_coin::initialize<mock_coin::WETH>(source, 8);
        mock_coin::faucet_mint_to_script<mock_coin::WETH>(end_user, 50); // +50 
        init_reserve<mock_coin::WETH>(source, 8);
    }


    // Initialize multiple tokens
    #[test_only]
    public entry fun init_multiple_tokens(source : &signer) {
        mock_coin::initialize<mock_coin::WETH>(source, 8);
        mock_coin::initialize<mock_coin::WBTC>(source, 8);
        init_reserve<mock_coin::WETH>(source, 8);
        init_reserve<mock_coin::WBTC>(source, 8);

    }

    // Test Init reserve 
    #[test(source = @vault, end_user = @0x3)]
    public fun init_reserve_test(source : &signer, end_user : &signer) {
        init_for_testing(source, end_user);
        let balance = coin::balance<mock_coin::WETH>(signer::address_of(end_user));
        assert!(balance == 50, 0);
        assert!(coin::is_account_registered<mock_coin::WETH>(signer::address_of(end_user)), 0);
    }

      
    // Test deposit liquidity 
    #[test(source = @vault ,end_user = @0x4 )]
    public entry fun deposit_liquidity_test(source : &signer , end_user : &signer){
       init_for_testing(source, end_user);
       deposit_liquidity<mock_coin::WETH>(end_user , 6); 
       let receive_tokens_balance = coin::balance<reserve::RToken<mock_coin::WETH>>(signer::address_of(end_user));
        assert!(receive_tokens_balance == 6, 0);
    }


    // Test withdraw liquidity 
    #[test(source = @vault , end_user = @0x4 )]
    public entry fun withdraw_liquidity_test(source : &signer , end_user : &signer){
        init_for_testing(source, end_user);
        deposit_liquidity<mock_coin::WETH>(end_user , 6);  // -6 
        
        let receive_tokens_balance = coin::balance<reserve::RToken<mock_coin::WETH>>(signer::address_of(end_user));
        assert!(receive_tokens_balance == 6, 0);

        withdraw_liquidity<mock_coin::WETH>(end_user, 3); // +3

        let balance = coin::balance<mock_coin::WETH>(signer::address_of(end_user));
        assert!(balance == 50 - 6 + 3, 0);
    }

    // Test pausing of reserve,
    // It fails if someone tries to deposit after pausing
    #[test(source = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329687)] //// abort code is = 327680 + 2007(EFROZEN)
    public entry fun pause_reserve_deposit_test(source : &signer, end_user : &signer) {
        init_for_testing(source,end_user);
        pause_reserve<mock_coin::WETH>(source);
        deposit_liquidity<mock_coin::WETH>(end_user , 6);
    }

    // Test unpausing of reserve,
    // We pause anf then unpause to test both deposit and withdraw
    #[test(source = @vault,end_user = @0x4 )]
    public entry fun unpause_reserve_deposit_and_withdraw_test(source : &signer, end_user : &signer) {
        init_for_testing(source,end_user);
        pause_reserve<mock_coin::WETH>(source);
        unpause_reserve<mock_coin::WETH>(source);
        deposit_liquidity<mock_coin::WETH>(end_user , 6); // -6
        withdraw_liquidity<mock_coin::WETH>(end_user, 3); // +3
       
    }

    // Test pausing of reserve,
    // It fails if someone tries to withdraw after pausing
    #[test(source = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329687)] // abort code is = 327680 + 2007(EFROZEN)
    public entry fun pause_reserve_withdraw_test(source : &signer, end_user : &signer) {
        init_for_testing(source,end_user);
        deposit_liquidity<mock_coin::WETH>(end_user , 6);
        pause_reserve<mock_coin::WETH>(source);
        withdraw_liquidity<mock_coin::WETH>(end_user, 3);
    }


    // Only admins can pause the reserve
    #[test(source = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329686)] // abort code is = 327680 + 2006(EUNAUTHORISED)
    public entry fun only_admins_pause_reserve_test(source : &signer, end_user : &signer) {
        init_for_testing(source,end_user);
        pause_reserve<mock_coin::WETH>(end_user);
    }

    // only admins can unpause the reserve
    #[test(source = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329686)] // abort code is = 327680 + 2006(EUNAUTHORISED)
    public entry fun only_admins_unpause_reserve_test(source : &signer, end_user : &signer) {
        init_for_testing(source,end_user);
        unpause_reserve<mock_coin::WETH>(end_user);
    }


}
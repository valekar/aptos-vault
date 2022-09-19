

#[test_only]
module vault::vault_test {

    use vault::mock_coin;
    use vault::vault::{
        deposit_into_vault,
        withdraw_from_vault,
        initialize_vault_config,
        pause_vault,
        unpause_vault
    };

    use aptos_framework::coin;
    use std::signer;
    
    // Init the module for testing
    // This method is common and is used in the rest of the code
    #[test_only]
    public entry fun init_for_testing(source : &signer , end_user : &signer) {
        mock_coin::initialize<mock_coin::WETH>(source, 8);
        mock_coin::faucet_mint_to_script<mock_coin::WETH>(end_user, 50); // +50 
        initialize_vault_config<mock_coin::WETH>(source);
    }

    /********************START of  Test cases for DEPOSIT to Vault COIN TYPE ********************************/

      
    // Test deposit liquidity 
    #[test(source = @vault ,end_user = @0x4 )]
    public entry fun deposit_into_vault_test(source : &signer , end_user : &signer){
       init_for_testing(source, end_user);
       deposit_into_vault<mock_coin::WETH>(end_user , 6); 
    }

    /********************END  of  Test cases for DEPOSIT to Vault COIN TYPE ********************************/



    /********************START of  Test cases for Withdraw to Vault COIN TYPE ********************************/


    // Test withdraw from vault 
    #[test(source = @vault , end_user = @0x4 )]
    public entry fun withdraw_from_vault_test(source : &signer , end_user : &signer){
        init_for_testing(source, end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);  // -6 
        withdraw_from_vault<mock_coin::WETH>(end_user, 3); // +3

        let balance = coin::balance<mock_coin::WETH>(signer::address_of(end_user));
        assert!(balance == 50 - 6 + 3, 0);
    }


    // Test withdraw from vault 
    #[test(source = @vault , end_user = @0x4 )]
    //#[expected_failure(abort_code = 2008)] 
    public entry fun withdraw_more_from_vault_test(source : &signer , end_user : &signer){
        init_for_testing(source, end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);  // -6 
        withdraw_from_vault<mock_coin::WETH>(end_user, 7);  // should error out here

        let balance = coin::balance<mock_coin::WETH>(signer::address_of(end_user));
        assert!(balance == 50 - 6, 0);
    }

    /******************** END of  Test cases for Withdraw to Vault COIN TYPE ********************************/



    /********************START of  Test cases for PAUSE/UNPAUSE for an COIN TYPE ********************************/

    // Test pausing of vault for Coin Type,
    // It fails if someone tries to deposit after pausing
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure] 
    public entry fun pause_vault_deposit_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(admin);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
    }
    

    // Test unpausing of vault for Coin Type,
    // We pause and then unpause to test both deposit and withdraw
    #[test(admin = @vault,end_user = @0x4 )]
    public entry fun unpause_vault_deposit_and_withdraw_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(admin);
        unpause_vault<mock_coin::WETH>(admin);
        deposit_into_vault<mock_coin::WETH>(end_user , 6); // -6
        withdraw_from_vault<mock_coin::WETH>(end_user, 3); // +3
    }


    // Test pausing of vault for an account,
    // It fails if someone tries to withdraw after pausing
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure] 
    public entry fun pause_vault_withdraw_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(admin);
        withdraw_from_vault<mock_coin::WETH>(end_user, 3); // +3
    }


    // Only admins can pause the vault for an account
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure] 
    public entry fun only_admins_pause_vault_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(end_user);
    }

    // only admins can unpause the vault for an account
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329686)] // abort code is = 327680 + 2006(EUNAUTHORISED)
    public entry fun only_admins_unpause_vault_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        unpause_vault<mock_coin::WETH>(end_user);
    }

    /********************END of  Test cases for PAUSE/UNPAUSE for an COIN TYPE ********************************/


}
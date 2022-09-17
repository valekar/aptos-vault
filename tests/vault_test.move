

#[test_only]
module vault::vault_test {

    use vault::mock_coin;
    use vault::vault::{
        deposit_into_vault,
        withdraw_from_vault,
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
    }

      
    // Test deposit liquidity 
    #[test(source = @vault ,end_user = @0x4 )]
    public entry fun deposit_into_vault_test(source : &signer , end_user : &signer){
       init_for_testing(source, end_user);
       deposit_into_vault<mock_coin::WETH>(end_user , 6); 
    }


    // Test withdraw liquidity 
    #[test(source = @vault , end_user = @0x4 )]
    public entry fun withdraw_from_vault_test(source : &signer , end_user : &signer){
        init_for_testing(source, end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);  // -6 
        

        withdraw_from_vault<mock_coin::WETH>(end_user, 3); // +3

        let balance = coin::balance<mock_coin::WETH>(signer::address_of(end_user));
        assert!(balance == 50 - 6 + 3, 0);
    }

    // Test pausing of vault,
    // It fails if someone tries to deposit after pausing
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329687)] //// abort code is = 327680 + 2007(EFROZEN)
    public entry fun pause_vault_deposit_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(admin, signer::address_of(end_user));
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
    }

    // Test unpausing of vault,
    // We pause anf then unpause to test both deposit and withdraw
    #[test(admin = @vault,end_user = @0x4 )]
    public entry fun unpause_vault_deposit_and_withdraw_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(admin, signer::address_of(end_user));
        unpause_vault<mock_coin::WETH>(admin, signer::address_of(end_user));
        deposit_into_vault<mock_coin::WETH>(end_user , 6); // -6
        withdraw_from_vault<mock_coin::WETH>(end_user, 3); // +3
    }

    // Test pausing of vault,
    // It fails if someone tries to withdraw after pausing
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329687)] // abort code is = 327680 + 2007(EFROZEN)
    public entry fun pause_vault_withdraw_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(admin, signer::address_of(end_user));
        withdraw_from_vault<mock_coin::WETH>(end_user, 3); // +3
    }


    // Only admins can pause the vault
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329686)] // abort code is = 327680 + 2006(EUNAUTHORISED)
    public entry fun only_admins_pause_vault_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        pause_vault<mock_coin::WETH>(end_user, signer::address_of(end_user));
    }

    // only admins can unpause the vault
    #[test(admin = @vault,end_user = @0x4 )]
    #[expected_failure(abort_code = 329686)] // abort code is = 327680 + 2006(EUNAUTHORISED)
    public entry fun only_admins_unpause_vault_test(admin : &signer, end_user : &signer) {
        init_for_testing(admin,end_user);
        deposit_into_vault<mock_coin::WETH>(end_user , 6);
        unpause_vault<mock_coin::WETH>(end_user, signer::address_of(end_user));
    }


}
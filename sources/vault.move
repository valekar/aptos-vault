module vault::vault {

    use aptos_framework::coin::{Self,Coin};
    use std::signer;
    use vault::config;
    use std::error;

    const ERROR_NO_AMOUNT:u64 = 2001; 
    const ERROR_NOT_INITIALIZED: u64 = 2005;
    const EUNAUTHORISED :u64 =  2006; 

     /// vault is frozen. Coins cannot be deposited or withdrawn
    const EFROZEN: u64 = 2007;


    /// vault for storing the deposit of the CoinType
    struct Vault<phantom CoinType> has key {
        frozen : bool,
        deposit : Coin<CoinType>,
    }

    struct VaultConfig<phantom CoinType> has key {
        frozen : bool,
    }

    /// private function to initialize vault config for the CoinType 
    fun initialize_vault_config_<CoinType>(sender : &signer) {

        let admin_addr = config::ADMIN_ADDRESS();
        assert!(admin_addr == signer::address_of(sender), EUNAUTHORISED);
        config::create_account_if_not_existing(signer::address_of(sender));

        let vault_config = VaultConfig<CoinType> {
            frozen : false,
        };
        move_to<VaultConfig<CoinType>>(sender, vault_config);

    }

    /// Initialize vault config for the CoinType
    public entry fun initialize_vault_config<CoinType>(sender : &signer) {
        initialize_vault_config_<CoinType>(sender);
    }

    /// private to Pause the vault for the coin type 
    fun pause_vault_<CoinType>(sender : &signer) acquires VaultConfig {
        assert_vault_configered<CoinType>();

        let addr = signer::address_of(sender);
        assert_is_admin(addr);
        let vault_config = borrow_global_mut<VaultConfig<CoinType>>(addr);

        vault_config.frozen = true;
    }

    /// Pause the vault for the coin type
    public entry fun pause_vault<CoinType>(sender : &signer) acquires VaultConfig {
        pause_vault_<CoinType>(sender);
    } 

    /// private function to unpause the vault for the coinType    
    fun unpause_vault_<CoinType>(sender : &signer) acquires VaultConfig {
        assert_vault_configered<CoinType>();

        let addr = signer::address_of(sender);
        assert_is_admin(addr);
        let vault_config = borrow_global_mut<VaultConfig<CoinType>>(addr);

        vault_config.frozen = false;
    }

    /// function to unpause the vault for the coinType
    public entry fun unpause_vault<CoinType>(sender : &signer) acquires VaultConfig {
        unpause_vault_<CoinType>(sender);
    } 

    /// private function
    /// Assert if the vault is configured for the coin type
    fun assert_vault_configered<CoinType>() {
        let admin_addr = config::ADMIN_ADDRESS();
        assert!(exists<VaultConfig<CoinType>>(admin_addr), ERROR_NOT_INITIALIZED);
    }

    /// private function 
    /// Assert if address is an admin
    fun assert_is_admin(addr : address) {
        let admin_addr = config::ADMIN_ADDRESS();
        assert!(addr == admin_addr, error::permission_denied(EUNAUTHORISED));

    }

    /// private function
    /// assert if vault is not frozen
    fun assert_vault_not_frozen<CoinType>() acquires VaultConfig{
        assert_vault_configered<CoinType>();
        let admin_addr = config::ADMIN_ADDRESS();
        let vault_config = borrow_global<VaultConfig<CoinType>>(admin_addr);
        assert!(vault_config.frozen == false, EFROZEN);
    }

    /// private function 
    /// Create vault for storing the deposit of the CoinType
    fun  create_vault_<CoinType>(sender : &signer) {
        config::create_account_if_not_existing(signer::address_of(sender));
        let vault = Vault<CoinType> {
            frozen : false,
            deposit : coin::zero<CoinType>(),
        };

        move_to<Vault<CoinType>>(sender, vault); 
    }


    /// private function for depositing coins
    fun deposit_into_vault_<CoinType>(sender : &signer, amount : u64) acquires Vault, VaultConfig {
        // assert vault not frozen for coin type 
        assert_vault_not_frozen<CoinType>();

        assert!(amount > 0 , ERROR_NO_AMOUNT);
        let addr = signer::address_of(sender);

        // create the vault if not existing for deposit
        if(!exists<Vault<CoinType>>(addr)) {
            create_vault_<CoinType>(sender);
        };

        let vault = borrow_global_mut<Vault<CoinType>>(addr);
        // check if vault is frozen by admin 
        assert!(
            !vault.frozen,
            error::permission_denied(EFROZEN),
        );

        let deposit_coins = &mut vault.deposit;
        let coins = coin::withdraw<CoinType>(sender, amount);
        coin::merge<CoinType>(deposit_coins, coins);

    
    } 


    /// Deposit to the vault 
    public entry fun deposit_into_vault<CoinType>(sender : &signer , amount : u64) acquires Vault, VaultConfig {
        deposit_into_vault_<CoinType>(sender, amount);  
    }


    /// private function to withdraw deposit
    fun withdraw_from_vault_<CoinType>(sender : &signer, amount : u64) acquires Vault, VaultConfig {
        // assert vault not frozen for coin type 
        assert_vault_not_frozen<CoinType>();
        
        let addr = signer::address_of(sender);

        assert!(amount > 0 , ERROR_NO_AMOUNT);
        assert!(exists<Vault<CoinType>>(addr) ,ERROR_NOT_INITIALIZED);

        let vault = borrow_global_mut<Vault<CoinType>>(addr);
        // check if vault is frozen by admin 
        assert!(
            !vault.frozen,
            error::permission_denied(EFROZEN),
        );

        let depositor = signer::address_of(sender);
        let vault_coins = &mut vault.deposit;

        let user_available_balance = coin::value(vault_coins);
        // check if amount specified is correct, return amount if balance is more otherwise return available balance
        amount = if(user_available_balance > amount) {
            amount
        } else {
            user_available_balance
        };
   
        let extracted_coins = coin::extract<CoinType>(vault_coins, amount);
        
        if(!coin::is_account_registered<CoinType>(depositor)) {
            coin::register<CoinType>(sender);
        };
        coin::deposit<CoinType>(depositor, extracted_coins);
       
    }
  
    /// withdraw the deposited coins back from vault. 
    public entry fun withdraw_from_vault<CoinType>(sender: &signer, amount : u64) acquires Vault, VaultConfig {
        withdraw_from_vault_<CoinType>(sender, amount);
    }

    /// private function to pausing the vault deposits
    fun pause_vault_for_account_<CoinType>(sender : &signer, pause_account : address) acquires Vault{
        assert!(exists<Vault<CoinType>>(pause_account) ,ERROR_NOT_INITIALIZED);

        let addr = signer::address_of(sender);
        assert_is_admin(addr);

        let vault = borrow_global_mut<Vault<CoinType>>(pause_account);
        vault.frozen = true;
    }

    /// public function to pause the vaults deposit/ withdraw for an account
    /// Should pass the account to be paused
    public entry fun pause_vault_for_account<CoinType>(sender : &signer,pause_account : address) acquires Vault{
        pause_vault_for_account_<CoinType>(sender, pause_account);
    } 

    /// private function to unpausing the vault deposits
    fun unpause_vault_for_account_<CoinType>(sender : &signer, unpause_account : address) acquires Vault{
        
        assert!(exists<Vault<CoinType>>(unpause_account) ,ERROR_NOT_INITIALIZED);

        let addr = signer::address_of(sender);
        assert_is_admin(addr);

        let vault = borrow_global_mut<Vault<CoinType>>(unpause_account);
        vault.frozen = false;
    }


    /// public function to pause the vaults deposit/ withdraw for an account
    /// Should pass the account to be unpaused
    public entry fun unpause_vault_for_account<CoinType>(sender : &signer, unpause_account : address) acquires Vault{
        unpause_vault_for_account_<CoinType>(sender,unpause_account);
    } 
 
}



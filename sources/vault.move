module vault::vault {

    use aptos_framework::coin::{Self,Coin};
    use std::signer;
    use vault::config;
    use std::error;
    use aptos_std::event::{Self,EventHandle};
    use aptos_framework::account;
    use aptos_framework::string::{Self, String};
    use std::option;


    const ERROR_NO_AMOUNT:u64 = 2001; 
    const ERROR_NOT_INITIALIZED: u64 = 2005;
    const EUNAUTHORISED :u64 =  2006; 
    const EINSUFFICIENT_BALANCE : u64 = 2008;

     ///Vault is frozen. Coins cannot be deposited or withdrawn
    const EFROZEN: u64 = 2007;


    ///Vault for storing the deposit of the CoinType
    struct Vault<phantom CoinType> has key {
        deposit : Coin<CoinType>,
    }

    struct VaultConfig<phantom CoinType> has key {
        frozen : bool,
        vault_event : EventHandle<VaultEvent>
    }

    /// Event emitted when some amount of a coinType is deposited or withdrawn into an account.
    struct VaultEvent has drop, store {
        msg : String,
        amount : option::Option<u64>

    }


    /// Private function 
    /// Initialize vault config for the CoinType 
    fun initialize_vault_config_<CoinType>(sender : &signer) {

        let admin_addr = config::ADMIN_ADDRESS();
        assert!(admin_addr == signer::address_of(sender), EUNAUTHORISED);
        config::create_account_if_not_existing(signer::address_of(sender));

        let vault_config = VaultConfig<CoinType> {
            frozen : false,
            vault_event :  account::new_event_handle(sender)
        };
        move_to<VaultConfig<CoinType>>(sender, vault_config);

    }

    /// Initialize vault config for the CoinType
    public entry fun initialize_vault_config<CoinType>(sender : &signer) {
        initialize_vault_config_<CoinType>(sender);
    }

    /// Private function 
    /// Pause the vault for the coin type 
    fun pause_vault_<CoinType>(sender : &signer) acquires VaultConfig {
        assert_vault_configered<CoinType>();

        let addr = signer::address_of(sender);
        assert_is_admin(addr);
        let vault_config = borrow_global_mut<VaultConfig<CoinType>>(addr);

        vault_config.frozen = true;

        // emit paused event
        let event_handler = &mut vault_config.vault_event;
        event::emit_event<VaultEvent>(event_handler, VaultEvent {
            msg :  string::utf8(b"Success : Paused Vault"),
            amount : option::none()
        });
    }

    /// Pause the vault for the coin type
    public entry fun pause_vault<CoinType>(sender : &signer) acquires VaultConfig {
        pause_vault_<CoinType>(sender);
    } 

    /// Private Function
    /// Unpause the vault for the coinType    
    fun unpause_vault_<CoinType>(sender : &signer) acquires VaultConfig {
        assert_vault_configered<CoinType>();

        let addr = signer::address_of(sender);
        assert_is_admin(addr);
        let vault_config = borrow_global_mut<VaultConfig<CoinType>>(addr);

        vault_config.frozen = false;

        // emit unpaused event
        let event_handler = &mut vault_config.vault_event;
        event::emit_event<VaultEvent>(event_handler, VaultEvent {
            msg :  string::utf8(b"Success : Unpaused Vault"),
            amount : option::none()
        });

    }

    /// function to unpause the vault for the coinType
    public entry fun unpause_vault<CoinType>(sender : &signer) acquires VaultConfig {
        unpause_vault_<CoinType>(sender);
    } 

    /// Private function
    /// Assert if the vault is configured for the coinType
    fun assert_vault_configered<CoinType>() {
        let admin_addr = config::ADMIN_ADDRESS();
        assert!(exists<VaultConfig<CoinType>>(admin_addr), ERROR_NOT_INITIALIZED);
    }

    /// Private function 
    /// Assert if address is an admin
    fun assert_is_admin(addr : address) {
        let admin_addr = config::ADMIN_ADDRESS();
        assert!(addr == admin_addr, error::permission_denied(EUNAUTHORISED));

    }

    /// Private function
    /// Assert if vault is not frozen
    fun assert_vault_not_frozen<CoinType>() acquires VaultConfig{
        assert_vault_configered<CoinType>();
        let admin_addr = config::ADMIN_ADDRESS();
        let vault_config = borrow_global<VaultConfig<CoinType>>(admin_addr);
        assert!(vault_config.frozen == false, EFROZEN);
    }

    /// Private function 
    /// Create vault for storing the deposit of the CoinType
    fun  create_vault_<CoinType>(sender : &signer) {
        config::create_account_if_not_existing(signer::address_of(sender));
        let vault = Vault<CoinType> {
            deposit : coin::zero<CoinType>(),
        };

        move_to<Vault<CoinType>>(sender, vault); 
    }

    /// Private Function
    /// Deposit coins into the Vault
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

        let deposit_coins = &mut vault.deposit;
        let coins = coin::withdraw<CoinType>(sender, amount);
        coin::merge<CoinType>(deposit_coins, coins);

        let admin_addr = config::ADMIN_ADDRESS();
        let vault_config = borrow_global_mut<VaultConfig<CoinType>>(admin_addr);
        let event_handler = &mut vault_config.vault_event;
        // emit deposit event
        event::emit_event<VaultEvent>(event_handler, VaultEvent {
            msg :  string::utf8(b"Success : Deposited into the Vault"),
            amount : option::some(amount)
        });
    
    } 


    /// Deposit to coin of the coinType into the vault 
    public entry fun deposit_into_vault<CoinType>(sender : &signer , amount : u64) acquires Vault, VaultConfig {
        deposit_into_vault_<CoinType>(sender, amount);  
    }

    /// Private function
    /// Withdraw deposit from the user's Vault
    fun withdraw_from_vault_<CoinType>(sender : &signer, amount : u64) acquires Vault, VaultConfig {
        // assert vault not frozen for coin type 
        assert_vault_not_frozen<CoinType>();
        
        let addr = signer::address_of(sender);

        assert!(amount > 0 , ERROR_NO_AMOUNT);
        assert!(exists<Vault<CoinType>>(addr) ,ERROR_NOT_INITIALIZED);

        let vault = borrow_global_mut<Vault<CoinType>>(addr);

        let depositor = signer::address_of(sender);
        let vault_coins = &mut vault.deposit;

        let user_available_balance = coin::value(vault_coins);

        let admin_addr = config::ADMIN_ADDRESS();
        let vault_config = borrow_global_mut<VaultConfig<CoinType>>(admin_addr);
        let event_handler = &mut vault_config.vault_event;

        if(user_available_balance < amount) {
            event::emit_event<VaultEvent>(event_handler, VaultEvent {
                msg :  string::utf8(b"Failure : Unable to withdraw from the Vault"),
                amount : option::some(amount)
            });  
            //assert!(user_available_balance > amount, EINSUFFICIENT_BALANCE);
        } 
        else {
            let extracted_coins = coin::extract<CoinType>(vault_coins, amount);
            
            if(!coin::is_account_registered<CoinType>(depositor)) {
                coin::register<CoinType>(sender);
            };
            coin::deposit<CoinType>(depositor, extracted_coins); 

            // emit succeful withdraw event
            event::emit_event<VaultEvent>(event_handler, VaultEvent {
                msg :  string::utf8(b"Success : Withdraw from the Vault"),
                amount : option::some(amount)
            }); 
        }    
    }
  
    /// Withdraw the deposited coins back from vault. 
    public entry fun withdraw_from_vault<CoinType>(sender: &signer, amount : u64) acquires Vault, VaultConfig {
        withdraw_from_vault_<CoinType>(sender, amount);
    }

 
}



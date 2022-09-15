module vault::reserve {

    use aptos_framework::coin::{Self,Coin,MintCapability,BurnCapability,FreezeCapability};
    use aptos_framework::type_info;
    use std::signer;
    use aptos_framework::string::{Self};
    use vault::config;
    //use aptos_framework::coins;
    use std::error;

    const ERROR_NO_AMOUNT:u64 = 2001; 
    const ERROR_NOT_INITIALIZED: u64 = 2005;
    const EUNAUTHORISED :u64 =  2006; 

     /// Reserve is frozen. Tokens cannot be deposited or withdrawn
    const EFROZEN: u64 = 2007;


    /// Reserve for storing the liquidity of the TokenType and issue receipt token for storing liquidity
    struct Reserve<phantom TokenType> has key {
        name : vector<u8>,
        version : u8,
        frozen : bool,
        liquidity : Liquidity<TokenType>,
        receipt : Receipt<TokenType>

    }

    /// Receipt token for this Reserve
    struct RToken<phantom TokenType> has key ,store, drop { }


    
     ///Liquidity resource storing 
    struct Liquidity<phantom TokenType> has  store{
        liquidity_tokens : Coin<TokenType>,
    }

    /// Receipt storing and creation
    struct Receipt<phantom TokenType> has store {
        receipt_coin : Coin<RToken<TokenType>>,
        capabilities : RTokenCapabalities<TokenType>
    }

    ///capabilities belonging to Receipt 
    struct RTokenCapabalities<phantom TokenType> has store {
        burn_cap: BurnCapability<RToken<TokenType>>,
        freeze_cap : FreezeCapability<RToken<TokenType>>,
        mint_cap: MintCapability<RToken<TokenType>>,

    }


    /// Initialize the receipt tokens for giving back to users if deposited with 
    /// Returns the Receipt token capabilities
    /// Let the symbol and name of the receipt token be the struct name of RToken<TokenType>
    fun init_receipt_token<TokenType>(sender : &signer, decimals : u8, supply_monitor : bool) : RTokenCapabalities<TokenType> {
        let name = string::utf8(type_info::struct_name(&type_info::type_of<RToken<TokenType>>())); 
        let symbol = name;        

        let (burn_cap,freeze_cap ,mint_cap) = coin::initialize<RToken<TokenType>>(sender, name , symbol, decimals, supply_monitor);

        if(!coin::is_account_registered<RToken<TokenType>>(signer::address_of(sender))){
            coin::register<RToken<TokenType>>(sender);
        };

        let receive_token_capablities = RTokenCapabalities<TokenType> {
            mint_cap : mint_cap,
            burn_cap : burn_cap,
            freeze_cap : freeze_cap
        };

        receive_token_capablities
    }

    /// Create reserve for storing the liquidity of the TokenType
    /// Let the name of the reserve be struct name of <TokenType>
    fun  create_reserve<TokenType>(admin : &signer, receive_token_decimals:u8) {
        config::create_account_if_not_existing(signer::address_of(admin));

        let name = type_info::struct_name(&type_info::type_of<TokenType>()); 
        let version = 0;

        let receive_token_capablities = init_receipt_token<TokenType>(admin, receive_token_decimals, true);

        let receipt = Receipt {
            receipt_coin : coin::zero<RToken<TokenType>>(),
            capabilities : receive_token_capablities
        };
        

        let reserve = Reserve<TokenType> {
            name : name,
            version : version,
            frozen : false,
            liquidity : Liquidity {
                            liquidity_tokens : coin::zero<TokenType>()
                        },

            receipt : receipt
        };

        move_to<Reserve<TokenType>>(admin, reserve); 
    }


     /// Initialize the reserve, user who creates this reseve owns it 
    public entry fun init_reserve<TokenType>(admin : &signer, receive_token_decimals : u8) {
        create_reserve<TokenType>(admin, receive_token_decimals);
    }

    /// private function for depositing tokens
    fun deposit_liquidity_<TokenType>(resource_addr : address, sender : &signer, amount : u64) acquires Reserve {

        assert!(amount > 0 , ERROR_NO_AMOUNT);
        assert!(coin::is_account_registered<TokenType>(resource_addr), error::not_found(ERROR_NOT_INITIALIZED));
        assert!(exists<Reserve<TokenType>>(resource_addr) ,ERROR_NOT_INITIALIZED);

        let reserve = borrow_global_mut<Reserve<TokenType>>(resource_addr);
        // check if reserve is frozen by admin 
        assert!(
            !reserve.frozen,
            error::permission_denied(EFROZEN),
        );

        let liquidity_tokens = &mut reserve.liquidity.liquidity_tokens;
        let tokens = coin::withdraw<TokenType>(sender, amount);
        coin::merge<TokenType>(liquidity_tokens, tokens);

        let receive_token_cap = &reserve.receipt.capabilities;
        let receive_tokens = coin::mint<RToken<TokenType>>(amount, &receive_token_cap.mint_cap);
        let depositor = signer::address_of(sender);

        if(!coin::is_account_registered<RToken<TokenType>>(depositor)) {
            coin::register<RToken<TokenType>>(sender);
        };

        config::create_account_if_not_existing(depositor);
        coin::deposit<RToken<TokenType>>(depositor, receive_tokens);
    
    } 


    /// Deposit the liquidity to the reserve and mint and deposit the receipt tokens back to the user
    public entry fun deposit_liquidity<TokenType>(sender : &signer , amount : u64) acquires Reserve {
        let admin_addr = config::ADMIN_ADDRESS();
        deposit_liquidity_<TokenType>(admin_addr, sender, amount);  
    }


    /// private function to withdraw liquidity
    fun withdraw_liquidity_<TokenType>(resource_addr: address, sender : &signer, amount : u64) acquires Reserve {

        assert!(amount > 0 , ERROR_NO_AMOUNT);
        assert!(coin::is_account_registered<RToken<TokenType>>(resource_addr), error::not_found(ERROR_NOT_INITIALIZED));
        assert!(exists<Reserve<TokenType>>(resource_addr) ,ERROR_NOT_INITIALIZED);

        let reserve = borrow_global_mut<Reserve<TokenType>>(resource_addr);
        // check if reserve is frozen by admin 
        assert!(
            !reserve.frozen,
            error::permission_denied(EFROZEN),
        );

        let depositor = signer::address_of(sender);
        let user_available_balance = coin::balance<RToken<TokenType>>(depositor);
        // check if amount specified is correct, return amount if balance is more otherwise return available balance
        amount = if(user_available_balance > amount) {
            amount
        } else {
            user_available_balance
        };
   
        let receive_token_cap = &reserve.receipt.capabilities;
        coin::burn_from<RToken<TokenType>>(depositor, amount, &receive_token_cap.burn_cap);

        let liquidity_tokens = &mut reserve.liquidity.liquidity_tokens;
        let extracted_tokens = coin::extract<TokenType>(liquidity_tokens, amount);
        if(!coin::is_account_registered<TokenType>(depositor)) {
            coin::register<TokenType>(sender);
        };

        coin::deposit<TokenType>(depositor, extracted_tokens);
       
    }
  
    /// withdraw the deposited tokens back from reserve. The user should give back the lp tokens
    public entry fun withdraw_liquidity<TokenType>(sender: &signer, amount : u64) acquires Reserve {
        let admin_addr = config::ADMIN_ADDRESS();
        withdraw_liquidity_<TokenType>(admin_addr, sender, amount);
    }

    /// private function to pausing the reserve deposits
    fun pause_reseve_<TokenType>(sender : &signer) acquires Reserve{
        let addr = signer::address_of(sender);
        let admin_addr = config::ADMIN_ADDRESS();

        assert!(addr == admin_addr, error::permission_denied(EUNAUTHORISED));

        let reserve = borrow_global_mut<Reserve<TokenType>>(admin_addr);
        reserve.frozen = true;
    }


    /// public function to pause the reserves deposit/ withdraw
    public entry fun pause_reserve<TokenType>(sender : &signer) acquires Reserve{
        pause_reseve_<TokenType>(sender);
    } 


    /// private function to unpausing the reserve deposits
    fun unpause_reseve_<TokenType>(sender : &signer) acquires Reserve{
        let addr = signer::address_of(sender);
        let admin_addr = config::ADMIN_ADDRESS();

        assert!(addr == admin_addr, error::permission_denied(EUNAUTHORISED));

        let reserve = borrow_global_mut<Reserve<TokenType>>(admin_addr);
        reserve.frozen = false;
    }


    /// public function to pause the reserves deposit/ withdraw
    public entry fun unpause_reserve<TokenType>(sender : &signer) acquires Reserve{
        unpause_reseve_<TokenType>(sender);
    } 

    
}



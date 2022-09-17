# Aptos Vault Module
This is a move module compatible with Aptos blockchain

## Purpose 
Vault module accepts any token types passed and stores in the liquidity separately. Motivation behind this module is to easily accept and store any tokens. 

Any tokens types could be stored.

## How to use vault module ?

Vault module could be directly installed in your module by specifying the address in `Move.toml` file.

**Note: The [example](/example) folder contains an example implementation of `Vault`  module.** 

Your can add in module dependency as shown below 

```toml
    [dependencies.Vault]
    git = 'https://github.com/valekar/aptos-vault.git'
    rev = 'main'
```

With that you should be able to access the module instructions in your code.


## How to deploy vault module? 

1. It is recommended to install `aptos-cli` in your system. To install please follow this [link](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli)

2. Clone this module by running below command
```bash
    git clone https://github.com/valekar/aptos-vault.git
```

3. Change directory to the `aptos-vault` module that you cloned.
```bash
    cd aptos-vault
```


4. First check if you `.aptos` folder in the module. If not, run the following to instantiate in the module folder an account. 
```bash
    aptos init
```

5. This will create `config.yaml` file in `.aptos` folder. 


6. For instance take a look at `.aptos.example` folder in this module. The example `config.yaml` contains the `account` as `0x65a78e4b038409443bdcee8af4d3fdc886e8bb8418c4c83f4a09291d2e06a498`  **Note for the security purpose do not share your .aptos folder contents to the public** 
   
7. Now add `account` address as the account address for `vault` in `Move.toml`. Below is an example toml configuration
```toml
    [addresses]
    vault = "0x65a78e4b038409443bdcee8af4d3fdc886e8bb8418c4c83f4a09291d2e06a498"
```

8.  First compile and test if everything is working fine 
```bash
    aptos move test && aptos move compile
```
9. Fund your aptos wallet account by running the following command
```bash
    aptos account fund-with-faucet --account 0x65a78e4b038409443bdcee8af4d3fdc886e8bb8418c4c83f4a09291d2e06a498
```


10. Run the publish command to deploy to aptos `devnet`
```bash
    aptos move publish 
```

## Technical Details 
In this section we will go through the technical details of using `aptos-vault` module. 

### Overview

The `Vault` module is a liquidity provider where users can deposit any `tokens` and receive `Receipt tokens` in return. 

To withdraw deposited tokens, users must hold the issued `Receipt Tokens`. 

The below image shows an overview of the architecture.

<img src="/docs/vault.png" alt="Vault architecture" style="height: 650px; width:750px;"/>

### Resources and Structs

There are totally 5 struct we define for `Vault`.   

```rust 
    struct Reserve<phantom TokenType> has key {
        name : vector<u8>, // ---> 1
        version : u8, // ---> 2
        frozen : bool, // ---> 3
        liquidity : Liquidity<TokenType>, // ---> 4
        receipt : Receipt<TokenType> // ---> 5

    }
```

Let us see what each field means in the above `struct` (resource)

1. `name` stores the reserve name
2. `version` stores the reserve version
3. `frozen` functionality is used by admins to pause/unpause the deposition of tokens into the reserve
4. `liquidity` stores all users tokens into a pool. This pool is isolated and only 1 type of token (`TokenType`) can be stored
5. `receipt` is a custom token type given to users who deposit their tokens into the liquidity


The `Receipt` resource is used to mint receipt tokens

```rust
    struct Receipt<phantom TokenType> has store {
        receipt_coin : Coin<RToken<TokenType>>, // ---> 1
        capabilities : RTokenCapabalities<TokenType> ---> 2
    }
```

1. `receipt_coin` is used for storing receipt tokens of the type `RToken<TokenType>` 
2. `capabilities` field is used for minting/burning of `RToken<TokenType>` type tokens. The capabilities are stored in the struct itself so that it will be easier to burn/mint tokens 


```rust 
    struct RTokenCapabalities<phantom TokenType> has store {
        burn_cap: BurnCapability<RToken<TokenType>>, ---> 1
        freeze_cap : FreezeCapability<RToken<TokenType>>, ---> 2
        mint_cap: MintCapability<RToken<TokenType>>, ---> 3

    }
```

The capabilites are stored in `RTokenCapabalities`
1. `burn_cap` capability is for burning `RToken<TokenType>`
2. `freeze_cap` capability is for freezing `RToken<TokenType>`
3. `mint_cap` capability is for minting `RToken<TokenType>`


 
   
```rust
    struct RToken<phantom TokenType> has key ,store, drop { }
```

The above `struct` is a Receipt token that is created and issued to user in exchange for depositing the token of type `TokenType`


```rust
    struct Liquidity<phantom TokenType> has  store{
        liquidity_tokens : Coin<TokenType>,
    }
```
The above `struct`(resource) is used to store the deposited tokens. 
 

### Instructions
Let us look at instructions available in `Vault` module.

#### Initialize Reserve

Anyone can initialize a token reserve. However, once initialized, it cannot be re-initialized again to the same account address.

```rust 
     /// Initialize the reserve, user who creates this reseve owns it 
    public entry fun init_reserve<TokenType>(admin : &signer, receive_token_decimals : u8) {
        create_reserve<TokenType>(admin, receive_token_decimals);
    }
```

The instruction accepts 
1. `signer` - who wants to initialize this reserve
2. `u8` - integer used for creating `RToken<TokenType>` . It is used for denote number of decimals for the created receipt token


#### Deposit Tokens

To deposit tokens to a reserve of a `TokenType`, it needs to be initialized first. This initialization is usually done by admins.

The below instruction is used for depositing to a reserve

```rust 
    /// Deposit the liquidity to the reserve and mint and deposit the receipt tokens back to the user
    public entry fun deposit_liquidity<TokenType>(sender : &signer , amount : u64) acquires Reserve {
        let admin_addr = config::ADMIN_ADDRESS();
        deposit_liquidity_<TokenType>(admin_addr, sender, amount);  
    }
```

It accepts

1. `signer` who wants to deposit
2. `amount` to mention how needs to be deposited.

When user deposits tokens, an equal amount of `Receipt Tokens` are issued to the user as a proof that the user has deposited into the vault


#### Withdraw tokens

To withdraw tokens, the following instruction is used

```rust
    /// withdraw the deposited tokens back from reserve. The user should give back the lp tokens
    public entry fun withdraw_liquidity<TokenType>(sender: &signer, amount : u64) acquires Reserve {
        let admin_addr = config::ADMIN_ADDRESS();
        withdraw_liquidity_<TokenType>(admin_addr, sender, amount);
    }
```

It accepts

1. `signer` who wants to withdraw deposited tokens
2. `amount` to withdraw from reserve. 

Note: If the amount mentioned is less the `Receipt Tokens` held by user, then amount equal to `Receipt Tokens` are issued back to user.


#### Pause the reserve

Only admins(one who instantiated reserve) can pause deposits/withdrawals of tokens

The below instruction is used to pause deposit/withdaw tokens

```rust
   /// public function to pause the reserves deposit/ withdraw
    public entry fun pause_reserve<TokenType>(sender : &signer) acquires Reserve{
        pause_reseve_<TokenType>(sender);
    } 
```

#### Unpause the reserve

This is used by admins to unpause a reserve of `TokenType`. 

```rust
    /// public function to pause the reserves deposit/ withdraw
    public entry fun unpause_reserve<TokenType>(sender : &signer) acquires Reserve{
        unpause_reseve_<TokenType>(sender);
    }
```


### Test cases

To understand how to use the instructions of the `Vault` module. It is recommended to go through the `reserve_test.move`


### Config

There is a `config.move` file separately defined for configuration purpose. 



## Terms and conditions

This code is free to use to use under GPL-3 license. Please refer the license file


## Contributions

If you plan to contribute to this repo, please open a PR.


## Further improvements

Idea 1 : We need to manually track all the initialized token reserves. It would be better if this can be saved in a table for easy tracking purpose

Idea 2 : The Initialized reserves could be stored in their own accounts. Meaning we could use `resource_accounts` and make the token reserve to manage itself so that end users don't have to manage them.  



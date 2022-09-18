# Aptos Vault Module
This is a move module compatible with Aptos blockchain

## Purpose 
Vault module accepts any token types passed and stores it into the vault. Motivation behind this module is to easily accept and store any coins. 

Any coins types could be stored.

## How to use vault module ?

Vault module could be directly installed in your module by specifying the address in `Move.toml` file.

**Note: The [example](/example) folder contains an example implementation of `Vault`  module.** 

Your can add in module dependency as shown below 

```toml
    [dependencies.Vault]
    git = 'https://github.com/valekar/aptos-vault.git'
    rev = 'develop'
```

With that, you should be able to access the module instructions in your code.


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


4. First check if you `.aptos` folder in the module. If not, run the following to instantiate an account in the module folder . 
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
9. (Optional)Fund your aptos wallet account by running the following command
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

The `Vault` module is for users to deposit any `coins`. 

To withdraw deposited coins, users must specify an amount to withdraw 

The below image shows an overview of the architecture.

<img src="/docs/vault.png" alt="Vault architecture" style="height: 650px; width:750px;"/>

### Resources and Structs

#### Struct Vault.   

`Vault` struct stores users coin of an initialized coin type

```rust 
    struct Vault<phantom CoinType> has key {
        frozen : bool, // ---> 1
        deposit : Coin<CoinType>, // ---> 2
 

    }
```

Let us see what each field means in the above `struct` (resource)

1. `frozen` functionality is used by admins to pause/unpause the deposition of coins into the vault
2. `deposit` stores all users coins into this field type. It only stores the `CoinType` provided 



#### Struct VaultConfig. 
We define another struct `VaultConfig` for pausing/unpausing vault for depositing/withdrawing from Vaults of Coin type

```rust
    struct VaultConfig<phantom CoinType> has key {
        frozen : bool,
    }
```

If the field `frozen` is set to `true`, then the depositing/withdrawals are  paused for a Vault of CoinType


### Instructions
Let us look at instructions available in `Vault` module.


#### Initialize Vault Config

Before depostion or withdrawal of any coins, `VaultConfig`  needs to be initialized. To initialize use,

```rust
    /// Initialize vault config for the CoinType
    public entry fun initialize_vault_config<CoinType>(sender : &signer) {
        initialize_vault_config_<CoinType>(sender);
    }
```

#### Deposit Coins 

To deposit coins to a vault of a `CoinType`, it needs to be initialized first. This initialization is done automatically

The below instruction is used for depositing to a vault

```rust 
    /// Deposit to the vault 
    public entry fun deposit_into_vault<CoinType>(sender : &signer , amount : u64) acquires Vault,VaultConfig {
        deposit_into_vault_<CoinType>(sender, amount);  
    }
```

It accepts

1. `signer` who wants to deposit
2. `amount` to mention how needs to be deposited.


#### Withdraw coins

To withdraw coins, the following instruction is used

```rust
    /// withdraw the deposited coins back from vault. 
    public entry fun withdraw_from_vault<CoinType>(sender: &signer, amount : u64) acquires Vault, VaultConfig {
        withdraw_from_vault_<CoinType>(sender, amount);
    }
```

It accepts

1. `signer` who wants to withdraw deposited coins
2. `amount` to withdraw from vault. 

Note: If the amount mentioned is less the `deposited coins` held by user, then amount equal to `deposited coins` are issued back to user.


#### Pause the vault

Only admins can pause deposits/withdrawals of coins

The below instruction is used to pause deposit/withdaw coins

```rust
    /// Pause the vault for the coin type
    public entry fun pause_vault<CoinType>(sender : &signer) acquires VaultConfig {
        pause_vault_<CoinType>(sender);
    } 
```

It accepts these params `signer` (admin) who wants pause an 


#### Unpause the vault

This is used by admins to unpause a vault of `CoinType`. 

```rust
    /// function to unpause the vault for the coinType
    public entry fun unpause_vault<CoinType>(sender : &signer) acquires VaultConfig {
        unpause_vault_<CoinType>(sender);
    }
```

It accepts these params `signer` (admin) who wants pause an 


### Test cases

To understand how to use the instructions of the `Vault` module. It is recommended to go through the `vault_test.move`

#### Run the test cases

To run the test cases, run the following command

```bash
aptos move test
```


### Config

There is a `config.move` file separately defined for configuration purpose. 



## Terms and conditions

This code is free to use to use under GPL-3 license. Please refer the license file


## Contributions

If you plan to contribute to this repo, please open a PR.


## Further improvements

Idea 1 : We need to manually track all the initialized token vaults. It would be better if this can be saved in a table for easy tracking purpose

Idea 2 : The Initialized vaults could be stored in their own accounts. Meaning we could use `resource_accounts` and make the token vault to manage itself so that end users don't have to manage them.  



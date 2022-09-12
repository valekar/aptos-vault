# Aptos Vault Module
This is a move module compatible with Aptos blockchain

## Purpose 
Vault module accepts any token types passed and stores in the liquidity separately. Motivation behind this module is to easily accept and store any tokens. 

Any tokens types could be stored.

## How to use vault module ?

Vault module could be directly installed in your module by specifying the address in `Move.toml` file.

**Note: The [example](https://github.com/valekar/aptos-vault/example) folder contains an example implementation of `Vault`  module.** 

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


6. For instance take a look at `.aptos.example` folder in this module. The example `config.yaml` contains the `account` as `4e6e0e7dd96db4f2d4f4ee40772d6938b202a65fd584a3bbc78e6d03a196b06c`  **Note for the security purpose do not share your .aptos folder contents to the public** 
   
7. Now add `account` address as the account address for `vault` in `Move.toml`. Below is an example toml configuration
```toml
    [addresses]
    vault = "0x4e6e0e7dd96db4f2d4f4ee40772d6938b202a65fd584a3bbc78e6d03a196b06c"
```

8.  First compile and test if everything is working fine 
```bash
    aptos move test && aptos move compile
```

9. Run the publish command to deploy to aptos `devnet`
```bash
    aptos move publish 
```

## Technical Details 
In this section we will go through the technical details of using `aptos-vault` module



 





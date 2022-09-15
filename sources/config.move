module vault::config {

    const ADMIN : address = @vault;

    use aptos_framework::aptos_account::{Self};
    use aptos_framework::account::{Self};


    public fun ADMIN_ADDRESS() : address {
        ADMIN
    }

    // create account if not existing so that resource created move to this account
    public fun create_account_if_not_existing(sender_addr: address) {
        if(!account::exists_at(sender_addr)){
            aptos_account::create_account(sender_addr);
        };
    }
}


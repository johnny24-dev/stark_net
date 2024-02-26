use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IPool<TContractState> {
    fn decimals(self: @TContractState) -> u8;
    fn balance_of(self: @TContractState, user: ContractAddress) -> u256;
    fn deposit(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
    fn withdraw_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256
    );
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256
    ) -> bool;
    fn set_exchange_address(ref self: TContractState, _exchange_addr: ContractAddress);
    fn upgrage(ref self: TContractState, _new_class_hash: ClassHash);
}


#[starknet::interface]
trait IERC20<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;

    // for eth starknet
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
}

#[starknet::contract]
mod pool {
    use core::starknet::SyscallResultTrait;
use core::option::OptionTrait;
    use starknet::{
        get_caller_address, get_contract_address, ContractAddress,
        contract_address_try_from_felt252, ClassHash
    };

    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        admin: ContractAddress,
        exchange: ContractAddress,
        _balances: LegacyMap<ContractAddress, u256>
    }

    #[constructor]
    fn constructor(ref self: ContractState, _admin: felt252) {
        let admin_addr = contract_address_try_from_felt252(_admin).unwrap();
        self.admin.write(admin_addr);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Upgraded:Upgraded
    }

    #[derive(Drop, starknet::Event)]
    struct Upgraded {
        implementation: ClassHash
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        value: u256
    }

    #[abi(embed_v0)]
    impl PoolIml of super::IPool<ContractState> {
        fn upgrage(ref self: ContractState, _new_class_hash: ClassHash) {
            let caller = get_caller_address();
            let admin_addr = self.admin.read();
            assert(caller == admin_addr, 'Invalid Admin');

            assert(!_new_class_hash.is_zero(), 'Class hash cannot be zero');
            starknet::replace_class_syscall(_new_class_hash).unwrap_syscall();
            self.emit(Event::Upgraded(Upgraded { implementation: _new_class_hash }))
        }

        fn set_exchange_address(ref self: ContractState, _exchange_addr: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Invalid admin!');

            self.exchange.write(_exchange_addr);
        }

        fn decimals(self: @ContractState) -> u8 {
            18
        }
        fn balance_of(self: @ContractState, user: ContractAddress) -> u256 {
            self._balances.read(user)
        }
        fn deposit(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            let strk_contract: ContractAddress = contract_address_try_from_felt252(
                0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            )
                .unwrap();
            let allowance = IERC20Dispatcher { contract_address: strk_contract }
                .allowance(caller, this_contract);
            assert(allowance >= amount, 'approve at least amount!');
            let res = IERC20Dispatcher { contract_address: strk_contract }
                .transferFrom(caller, this_contract, amount);
            assert(res, 'Deposit fail!');
            let balance = self._balances.read(caller);
            self._balances.write(caller, (balance + amount));
            self.emit(Transfer { from: Zeroable::zero(), to: caller, value: amount });
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            // let this_contract = get_contract_address();
            let balance = self._balances.read(caller);
            let strk_contract: ContractAddress = contract_address_try_from_felt252(
                0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            )
                .unwrap();
            assert(balance >= amount, 'Insufficient funds');
            self._balances.write(caller, (balance - amount));
            let res = IERC20Dispatcher { contract_address: strk_contract }.transfer(caller, amount);
            assert(res, 'withdraw fail!');
            self.emit(Transfer { from: caller, to: Zeroable::zero(), value: amount });
        }

        fn withdraw_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) {
            let caller = get_caller_address();
            let exchange = self.exchange.read();
            assert(caller == exchange, 'Unauthorized');
            let strk_contract: ContractAddress = contract_address_try_from_felt252(
                0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
            )
                .unwrap();

            let balance = self._balances.read(from);
            assert(balance >= amount, 'Insufficient balance');
            self._balances.write(from, (balance - amount));
            let res = IERC20Dispatcher { contract_address: strk_contract }.transfer(to, amount);
            assert(res, 'withdraw fail!');
            self.emit(Transfer { from, to, value: amount });
        }


        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) -> bool {
            let caller = get_caller_address();
            let exchange = self.exchange.read();
            assert(caller == exchange, 'Unauthorized');

            assert(to != Zeroable::zero(), 'Cannot transfer to 0 address');
            let balance = self._balances.read(from);
            assert(balance >= amount, 'Insufficient balance');
            self._balances.write(from, (balance - amount));
            let to_balance = self._balances.read(to);
            self._balances.write(to, to_balance + amount);

            self.emit(Transfer { from, to, value: amount });

            return true;
        }
    }
}

use core::traits::Into;
// for interface
use starknet::ContractAddress;
use array::ArrayTrait;
use bigcairo_launchpad::Phase;


#[starknet::interface]
trait ILaunchpad<TState> {
    fn mint_native(ref self: TState, group_name: felt252, proof: Array<felt252>);
    fn add_phase(
        ref self: TState,
        group_name: felt252,
        start_time: u64,
        expired_time: u64,
        total_nft: u64,
        nft_per_user: u64,
        price_per_item: u256,
        merkle_root: felt252,
        is_wl_pool: bool
    );

    fn get_phase(self: @TState, group_name: felt252) -> Phase;
    // fn check_wl(
    //     self: @TState, address: ContractAddress, group_name: felt252, proof: Array<felt252>
    // );
    fn get_minted_by_user(self: @TState, address: ContractAddress) -> u64;
    fn get_mint_info(self: @TState, token_id: u256) -> ContractAddress;
    fn get_admin(self: @TState) -> ContractAddress;
}

#[starknet::interface]
trait IMerkle<TContractState> {
    fn verify(
        self: @TContractState, merkle_root: felt252, leaf: felt252, proof: Array<felt252>
    ) -> bool;
}


#[starknet::interface]
trait IERC20<TState> {
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
}


// contract

#[starknet::contract]
mod bigcairo_launchpad {
    use openzeppelin::token::erc721::interface::IERC721Metadata;
use openzeppelin::token::erc721::interface::IERC721;
use core::clone::Clone;
    use launchpad::launchpad::ILaunchpad;
    use starknet::ContractAddress;
    use starknet::get_contract_address;
    use starknet::contract_address_try_from_felt252;
    use starknet::get_block_timestamp;
    use starknet::get_caller_address;
    use starknet::{contract_address_to_felt252};

    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

   // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    use core::array::ArrayTrait;
    use zeroable::Zeroable;
    use option::OptionTrait;
    use traits::TryInto;
    use traits::Into;


    use super::{IERC20DispatcherTrait, IERC20Dispatcher, IMerkleDispatcher, IMerkleDispatcherTrait};

    use alexandria_merkle_tree::merkle_tree::{
        Hasher, MerkleTree, pedersen::PedersenHasherImpl, poseidon::PoseidonHasherImpl,
        MerkleTreeTrait, MerkleTreeImpl
    };

    #[storage]
    struct Storage {
       #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,

        admin: ContractAddress,
        collection_name: felt252,
        collection_symbol: felt252,
        collection_supply: u256,
        phases: LegacyMap<felt252, Phase>,
        minter: LegacyMap<ContractAddress, u64>,
        mint_info: LegacyMap<u256, ContractAddress>,
        current_id: u256,
        fund_address: ContractAddress
    }


    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Phase {
        name: felt252,
        start_time: u64,
        expired_time: u64,
        total_nft: u64,
        nft_per_user: u64,
        price_per_item: u256,
        merkle_root: felt252,
        is_wl_pool: bool
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
       #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        MintEvent: MintEvent,
    }

    #[derive(Drop, starknet::Event)]
    struct MintEvent {
        #[key]
        minter: ContractAddress,
        collection: ContractAddress,
        token_id: u256
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252, supply: u256) {
        // init oz er721

         // Initialize the ERC721 storage
             self.erc721.initializer(name, symbol);
            

        let admin_address = contract_address_try_from_felt252(
            0x0187623be1669117F3bd4DE38E86B01E2493a28ccBa1f669Ff0D7a9d9D6Ca571
        )
            .unwrap();

        let fund_address = contract_address_try_from_felt252(
            0x0187623be1669117F3bd4DE38E86B01E2493a28ccBa1f669Ff0D7a9d9D6Ca571
        )
            .unwrap();

        // store data
        self.admin.write(admin_address);
        self.collection_name.write(name);
        self.collection_symbol.write(symbol);
        self.collection_supply.write(supply);
        self.current_id.write(1);
        self.fund_address.write(fund_address);
    }
    #[external(v0)]
    impl BluemoveLaunchpadImpl of super::ILaunchpad<ContractState> {
        // admin function
        fn add_phase(
            ref self: ContractState,
            group_name: felt252,
            start_time: u64,
            expired_time: u64,
            total_nft: u64,
            nft_per_user: u64,
            price_per_item: u256,
            merkle_root: felt252,
            is_wl_pool: bool
        ) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(admin == caller, 'InvalidAdmin');
            let phase = Phase {
                name: group_name,
                start_time: start_time,
                expired_time: expired_time,
                total_nft: total_nft,
                nft_per_user: nft_per_user,
                price_per_item: price_per_item,
                merkle_root: merkle_root,
                is_wl_pool: is_wl_pool
            };
            self.phases.write(group_name, phase);
        }

        // ---------------------------------------------------------//

        fn mint_native(ref self: ContractState, group_name: felt252, proof: Array<felt252>) {
            let caller = get_caller_address();
            let fund_address = self.fund_address.read();
            let eth_address: ContractAddress = contract_address_try_from_felt252(
                0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
            )
                .unwrap();

            let phase = self.phases.read(group_name);
            let user_minted = self.minter.read(caller);
            assert(user_minted <= phase.nft_per_user, 'Full Slot');

            let must_pay = phase.price_per_item;
            // check allowance
            let this_contract = get_contract_address();
            let allowance = IERC20Dispatcher { contract_address: eth_address }
                .allowance(caller, this_contract);
            assert(allowance >= must_pay, 'approve not enough');
            // // verify caller is on WL
            let merkle_root = phase.merkle_root;
            if (phase.is_wl_pool) {
                let leaf = contract_address_to_felt252(caller);
                let result = self.verify(merkle_root, leaf, proof);
                assert(result, 'Not on WL');
            }

            let current_id = self.current_id.read();
            let supply = self.collection_supply.read();

            assert(current_id < supply, 'Sold out');

            let current_time: u64 = get_block_timestamp() * 1000;
            assert(
                current_time >= phase.start_time && current_time <= phase.expired_time,
                'Not time to mint'
            );

            // mint
            self.erc721._mint(caller,current_id);
            // erc721::ERC721::InternalImpl::_set_token_uri(ref unsafe_state, token_id, token_uri);

            //update mint_info
            self.mint_info.write(current_id, caller);

            // transfer eth
            IERC20Dispatcher { contract_address: eth_address }
                .transferFrom(caller, fund_address, phase.price_per_item);

            // emit event
            self
                .emit(
                    Event::MintEvent(
                        MintEvent {
                            minter: caller, collection: get_contract_address(), token_id: current_id
                        }
                    )
                );

            // update state
            self.current_id.write(current_id + 1);
            self.minter.write(caller, user_minted + 1);
        }

        fn get_phase(self: @ContractState, group_name: felt252) -> Phase {
            self.phases.read(group_name)
        }

        fn get_minted_by_user(self: @ContractState, address: ContractAddress) -> u64 {
            self.minter.read(address)
        }
        fn get_mint_info(self: @ContractState, token_id: u256) -> ContractAddress {
            self.mint_info.read(token_id)
        }
        fn get_admin(self: @ContractState) -> ContractAddress {
            self.admin.read()
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn verify(
            self: @ContractState, merkle_root: felt252, leaf: felt252, proof: Array<felt252>
        ) -> bool {
            let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeImpl::<
                _, PedersenHasherImpl
            >::new();
            // Verify a valid proof.
            let result = MerkleTreeImpl::<
                _, PedersenHasherImpl
            >::verify(ref merkle_tree, merkle_root, leaf, proof.span());
            result
        }
    }
}

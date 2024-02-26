import { Account, CallData, cairo } from "starknet";
import { AssetType, CreateCollectionOfferInput, CreateOrderInput, OrderType, TakeOrderInput } from "../eip712/types";
import { createCollectionOfferAndSignMessage, createOrderAndSignMessage } from "../eip712/orderHash";
import { generateRandomSalt } from "../utils";
import { CONTRACT_ADDR, POOL_ADDR, provider } from "../eip712/constanst";


const market_addr = CONTRACT_ADDR;

const takeAsk = async () => {
    //
    const privateKey = "";
    const accountAddress = "0x01EB945a1b881A2D8f8D8EA5eaDa7Ec42C999ab5e5ED225af7b62F00865BAfBd";

    const privatekey2 = "";
    const accountAddr2 = "0x07d17C0fF6190301bc7d17607D34dA5E5178e045736B5aC759992C3aC08ca566";

    const account = new Account(
        provider,
        accountAddress,
        privateKey,
        '1'
    )

    const account2 = new Account(
        provider,
        accountAddr2,
        privatekey2,
        '1'
    )


    const inputs: CreateOrderInput[] = [
        {
            trader: account.address,
            collection: "0x06b2b86d2a5ca267e60da476957d9939e7f7452c6c24a96f99ad8fbdc40a7867",
            token_id: 1,
            amount: 1,
            price: '1000000000000000',
            asset_type: AssetType.ERC721, // 0 is erc721, 1 is erc1155
            salt: undefined,
            order_type: OrderType.ASK
        }
    ]

    const order_response = await createOrderAndSignMessage(account, inputs);
    console.log("🚀 ~ file: index.ts:33 ~ takeAsk ~ order_response:", order_response);
    // approve nft for market_contract


    const approve_tx = await account.execute([{
        contractAddress: `0x06b2b86d2a5ca267e60da476957d9939e7f7452c6c24a96f99ad8fbdc40a7867`, //collection_addr
        entrypoint: 'approve',
        calldata: CallData.compile({
            to: market_addr,
            token_id: cairo.uint256(1)
        })
    }])
    console.log("🚀 ~ takeAsk ~ approve_tx:", await provider.waitForTransaction(approve_tx.transaction_hash))

    const multi_take_asks = order_response.map((res) => (
        {
            contractAddress: market_addr, // strk_addr
            entrypoint: 'take_ask',
            calldata: CallData.compile({
                trader: cairo.felt(res.trader ?? account.address),
                collection: cairo.felt(res.collection),
                num_of_listing: cairo.felt(res.num_of_listing),
                token_id: cairo.felt(res.token_id),
                amount: cairo.felt(res.amount),
                price: cairo.felt(res.price),
                asset_type: cairo.felt(res.asset_type),
                salt: cairo.felt(res.salt ?? BigInt(generateRandomSalt()).toString()),
                order_type: cairo.felt(res.order_type),
                signature: res.signature
            })
        }
    ))

    multi_take_asks.unshift({
        contractAddress: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`, // strk_addr
        entrypoint: 'approve',
        calldata: CallData.compile({
            spender: market_addr,
            amount: cairo.uint256(`1000000000000000`)
        })
    })


    const multi_tx_take_asks = await account2.execute(multi_take_asks);

    const res_tx = await provider.waitForTransaction(multi_tx_take_asks.transaction_hash);
    console.log("🚀 ~ file: index.ts:86 ~ takeAsk ~ res_tx:", res_tx)

}




const takeBid = async () => {
    const privateKey = "";
    const accountAddress = "0x01EB945a1b881A2D8f8D8EA5eaDa7Ec42C999ab5e5ED225af7b62F00865BAfBd";

    const privatekey2 = "";
    const accountAddr2 = "0x07d17C0fF6190301bc7d17607D34dA5E5178e045736B5aC759992C3aC08ca566";

    const account = new Account(
        provider,
        accountAddress,
        privateKey,
        '1'
    )

    const account2 = new Account(
        provider,
        accountAddr2,
        privatekey2,
        '1'
    )


    const inputs: CreateOrderInput[] = [
        {
            trader: account2.address,
            collection: "0x04de8833cc986e37f140ed1ff52d12929152b2db8f5078e6d757f200910ea7a2",
            token_id: 5,
            amount: 1,
            price: '100000000',
            asset_type: AssetType.ERC721, // 0 is erc721, 1 is erc1155
            salt: undefined,
            order_type: OrderType.BID
        }
    ]

    const order_response = await createOrderAndSignMessage(account2, inputs);
    console.log("🚀 ~ file: index.ts:33 ~ takeAsk ~ order_response:", order_response);


    const multi_take_bids = order_response.map((res) => (
        {
            contractAddress: market_addr,
            entrypoint: 'take_bid',
            calldata: CallData.compile({
                trader: cairo.felt(res.trader ?? account2.address),
                collection: cairo.felt(res.collection),
                num_of_listing: cairo.felt(res.num_of_listing),
                token_id: cairo.felt(res.token_id),
                amount: cairo.felt(res.amount),
                price: cairo.felt(res.price),
                asset_type: cairo.felt(res.asset_type),
                salt: cairo.felt(res.salt ?? BigInt(generateRandomSalt()).toString()),
                order_type: cairo.felt(res.order_type),
                signature: res.signature
            })
        }
    ))
    const multi_tx_take_bids = await account.execute(multi_take_bids);

    const res_tx = await provider.waitForTransaction(multi_tx_take_bids.transaction_hash);
    console.log("🚀 ~ file: index.ts:86 ~ takeAsk ~ res_tx:", res_tx)
}

const takeCollectionOffer = async () => {
    const privateKey = "";
    const accountAddress = "0x01EB945a1b881A2D8f8D8EA5eaDa7Ec42C999ab5e5ED225af7b62F00865BAfBd";

    const privatekey2 = "";
    const accountAddr2 = "0x07d17C0fF6190301bc7d17607D34dA5E5178e045736B5aC759992C3aC08ca566";

    const account = new Account(
        provider,
        accountAddress,
        privateKey,
        '1'
    )

    const account2 = new Account(
        provider,
        accountAddr2,
        privatekey2,
        '1'
    )

    // trader: BigNumberish,
    // collection: BigNumberish,
    // num_of_listing: number,
    // price_per_item: BigNumberish,
    // asset_type: number, // 0 is erc721, 1 is erc1155
    // salt?: BigNumberish

    const inputs: CreateCollectionOfferInput =
    {
        trader: account.address,
        collection: "0x06b2b86d2a5ca267e60da476957d9939e7f7452c6c24a96f99ad8fbdc40a7867",
        num_of_listing: 1,
        price_per_item: '1000000000000000',
        asset_type: AssetType.ERC721, // 0 is erc721, 1 is erc1155
        salt: undefined
    }


    const collection_offer_response = await createCollectionOfferAndSignMessage(account, inputs);
    console.log("🚀 ~ file: index.ts:200 ~ takeCollectionOffer ~ collection_offer_response:", collection_offer_response)


    // trader: BigNumberish,
    // collection: BigNumberish,
    // num_of_listing: number,
    // price_per_item: BigNumberish,
    // asset_type: number, // 0 is erc721, 1 is erc1155
    // salt: BigNumberish
    // token_id: number,
    // amount: number,
    // signature: string[]

    const multi_call: any[] = [];

    multi_call.push({
        contractAddress: collection_offer_response.collection,
        entrypoint: 'approve',
        calldata: CallData.compile({
            approved: CONTRACT_ADDR,
            token_id: cairo.uint256(1) // example for token_id = 3
        })
    })

    const take_collection_offers =
    {
        contractAddress: market_addr,
        entrypoint: 'take_collection_offer',
        calldata: CallData.compile({
            trader: cairo.felt(collection_offer_response.trader ?? account.address),
            collection: cairo.felt(collection_offer_response.collection),
            num_of_listing: cairo.felt(collection_offer_response.num_of_listing),
            price_per_item: cairo.felt(collection_offer_response.price_per_item),
            asset_type: cairo.felt(collection_offer_response.asset_type),
            salt: cairo.felt(collection_offer_response.salt ?? ''),
            token_id: cairo.felt(1),
            amount: cairo.felt(1),
            signature: collection_offer_response.signature
        })
    }
    multi_call.push(take_collection_offers)
    const multi_tx_take_collection_offers = await account2.execute(multi_call);

    const res_tx = await provider.waitForTransaction(multi_tx_take_collection_offers.transaction_hash);
    console.log("🚀 ~ file: index.ts:86 ~ takeAsk ~ res_tx:", res_tx)
}

const test_call_data = async () => {



    const test_addr = CONTRACT_ADDR

    const res = await provider.callContract({
        contractAddress: test_addr,
        entrypoint: 'get_user_nonce',
        calldata: CallData.compile({
            user_address: cairo.felt("0x07d17C0fF6190301bc7d17607D34dA5E5178e045736B5aC759992C3aC08ca566")
        })
    }) // check approve token
    console.log("🚀 ~ file: index.ts:246 ~ consttest_call_data= ~ res:", res.result)

}

// test_call_data()

takeCollectionOffer()

// takeAsk()

// takeBid()

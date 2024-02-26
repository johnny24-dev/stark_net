
import { RpcProvider, constants, shortString } from "starknet";

export const CONTRACT_NAME = "BIGCAIRO_EXCHANGE";
export const CONTRACT_VERSION = "1.0";
export const CONTRACT_ADDR = "0x00e4843b2852f3e26413f61fe292fb6a970c5bbb33ee05b33567a9288fc4899e";
export const POOL_ADDR = `0x010c31893007fe46b29cf6a2c38ec56902cb1f0045a18b975a4045f1fef1818a`

export const provider = new RpcProvider({nodeUrl: constants.RPC_GOERLI_NODES[0]});

export const DOMAIN = {
    name: CONTRACT_NAME,
    version: CONTRACT_VERSION,
    chainId: shortString.encodeShortString(constants.NetworkName.SN_GOERLI), // for testnet
}

export const EIP_712_ORDER_TYPES = {
    StarkNetDomain: [
        { name: "name", type: "felt" },
        { name: "version", type: "felt" },
        { name: "chainId", type: "felt" },
    ],
    //Order(trader:felt,collection:felt,num_of_listing:felt,token_id:felt,amount:felt,price:felt,asset_type:felt,salt:felt,order_type:felt,nonce:felt)
    Order: [
        { name: "trader", type: "felt" },
        { name: "collection", type: "felt" },
        { name: "num_of_listing", type: "felt" },
        { name: "token_id", type: "felt" },
        { name: "amount", type: "felt" },
        { name: "price", type: "felt" },
        { name: "asset_type", type: "felt" },
        { name: "salt", type: "felt" },
        { name: "order_type", type: "felt" },
        { name: "nonce", type: "felt" }
    ]
}

export const EIP_712_COLLECTION_OFFER_TYPES = {
    StarkNetDomain: [
        { name: "name", type: "felt" },
        { name: "version", type: "felt" },
        { name: "chainId", type: "felt" },
    ],
    //CollectionOffer(trader:felt,collection:felt,num_of_listing:felt,price_per_item:felt,asset_type:felt,salt:felt,order_type:felt,nonce:felt)
    CollectionOffer: [
        { name: "trader", type: "felt" },
        { name: "collection", type: "felt" },
        { name: "num_of_listing", type: "felt" },
        { name: "price_per_item", type: "felt" },
        { name: "asset_type", type: "felt" },
        { name: "salt", type: "felt" },
        { name: "order_type", type: "felt" },
        { name: "nonce", type: "felt" }
    ]
}

export enum PRIMARY_TYPES {
    Order = "Order",
    CollectionOffer = "CollectionOffer"
}


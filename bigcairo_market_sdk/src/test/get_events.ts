import { hash, num, RpcProvider, shortString } from "starknet";

const providerRPC = new RpcProvider({ nodeUrl: 'https://starknet-goerli.g.alchemy.com/v2/9es8spuTkibm3LVc4twxv2Oirnql4rdY' }); // for an Infura node on Testnet

const get_event_inscriptions = async () => {
    const keyFilter = [num.toHex(hash.starknetKeccak("InscriptionsEvent")), "0x8"]
    let block = await providerRPC.getBlock('latest');
    console.log("bloc #", block.block_number);

    let continuationToken: string | undefined = "0";
    let chunkNum: number = 1;
    while (continuationToken) {
        const eventsRes = await providerRPC.getEvents({
            from_block: {
                block_number: block.block_number - 100
            },
            to_block: {
                block_number: block.block_number
            },
            address: `0x0562f781ffadaedde8f289de149260964d9213396a04c8d2d279a97a5dcb278a`,
            keys: [[]],
            chunk_size: 5
        });
        const nbEvents = eventsRes.events.length;
        continuationToken = eventsRes.continuation_token;
        console.log("chunk nb =", chunkNum, ".", nbEvents, "events recovered.");
        console.log("continuation_token =", continuationToken);
        for (let i = 0; i < nbEvents; i++) {
            const event = eventsRes.events[i];
            console.log("event #", i, "data length =", event.data.length, "key length =", event.keys.length, ":");
            console.log("\nkeys =", event.keys, "data =", event.data)
            
        }
        chunkNum++;
    }
}

get_event_inscriptions()
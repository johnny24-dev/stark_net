import {merkle} from 'starknet';

import WL from './wl.json';


const generate_root = (leaves:string[]): string => {
    const tree = new merkle.MerkleTree(leaves);
    return tree.root
}

const generate_proof = (leaf:string):string[] => {
    const tree = new merkle.MerkleTree(WL);
    const root = tree.root;
    const proof = tree.getProof(leaf);
    return proof
}

const verify = () => {
    const tree = new merkle.MerkleTree(WL);

    const root = tree.root;
    console.log("🚀 ~ file: index.ts:22 ~ verify ~ root:", root)
    const leaf = WL[0];

    const proof = tree.getProof(leaf);
    console.log("🚀 ~ file: index.ts:26 ~ verify ~ proof:", proof)

    const res = merkle.proofMerklePath(root,leaf,proof)
    console.log("🚀 ~ file: index.ts:20 ~ verify ~ res:", res)
}

verify()
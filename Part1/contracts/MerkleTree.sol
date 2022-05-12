//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol"; //to print logs in the console

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    uint256 private constant ZERO_VALUE = 0;
    uint256 private constant LEVELS = 3;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        uint n = LEVELS; //levels
        for (uint256 i = 0; i < 2**n; i++) {
            hashes.push(ZERO_VALUE);
        }

        uint total = 2**(n+1);
        for (uint256 level=n; level>0; level--) {
            uint nodes = 2**level/2;
            for (uint256 i = 0; i < nodes; i++) {
                uint before = total - 2**(level+1) ;
                uint left = 2*i + before;
                uint right = 2*i + 1 + before;
                hashes.push(PoseidonT3.poseidon([hashes[left],hashes[right]]));
                console.log("left: " , left , " right: " , right);
            }
        }
        root = hashes[total-2];
        
        console.log("---- initial tree -----");
        for(uint256 i = 0; i < 15; i++) {
            console.log(i,":", hashes[i]);
        }
        console.log("-----------------------");
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        uint n = LEVELS;
        require(index < 2**n, "MerkleTree is full");
        hashes[index] = hashedLeaf;
        uint position = index; 
        for (uint i = 0; i < n; i++) { 
            uint odd = position % 2;
            uint left = position - odd;
            uint right = position + 1 - odd;
            position = 2**n + (position - odd) / 2;
            hashes[position]=PoseidonT3.poseidon([hashes[left],hashes[right]]);
            console.log("index", position);
            console.log("left: " , left , " right: " , right);
        }
        root = hashes[2**(n+1)-2];
        index++;
        return index-1;
    }

    function printTree() public view{
        // [assignment] print the Merkle tree
        for(uint256 i = 0; i < 15; i++) {
            console.log(i,":", hashes[i]);
        }
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        console.log("root input:", input[0]);
        console.log("root generated:",root);
        return input[0] == root && this.verifyProof(a, b, c, input);
    }
}

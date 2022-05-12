pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
  
    //Initialize the hash nodes: total is 2**n - 1 ( #leaves - 1) (exclude leaves)
    component hashNodes[ 2**n - 1];
 
    // constraint hashes for leaft hashes nodes: total is 2**n/2  ( #leaves/2 )
    var  i = 0;
    for (i=0; i < 2**n/2; i++) {
        hashNodes[i] = Poseidon(2);
        hashNodes[i].inputs[0] = leaves[2*i];
        hashNodes[i].inputs[1] = leaves[2*i+1];
    }

    // constraint intermediate hashes: total is 2**n - 2 ( #hashers - 1) (exclude leaves hashers)
    for(i=i; i < 2**n - 2; i++) {
        var j= (i-2**n/2)*2;
        hashNodes[i] = Poseidon(2);
        hashNodes[i].inputs[0] = hashNodes[j].out;
        hashNodes[i].inputs[1] = hashNodes[j+1].out;
    }

    // constraint root: last hasher node result (2**n - 1) -1 (#hashers -1) 
    root <== hashNodes[2**n - 2].out;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    signal results[n+1]; // to store the results hashes of the path

    //constraint for all n levels
    component mux1[n][2];
    component hash[n];
    results[0] <== leaf;
    for (var i = 0; i < n; i++) {
        mux1[i][0] = Mux1();
        mux1[i][0].c[0] <== results[i];
        mux1[i][0].c[1] <== path_elements[i];
        mux1[i][0].s <== path_index[i];
        mux1[i][1] = Mux1();
        mux1[i][1].c[0] <== path_elements[i];
        mux1[i][1].c[1] <== results[i];
        mux1[i][1].s <== path_index[i];

        hash[i] = Poseidon(2);
        hash[i].inputs[0] <== mux1[i][0].out; 
        hash[i].inputs[1] <== mux1[i][1].out;

        results[i + 1] <== hash[i].out;
    }

    // constraint for root
    root <== results[n];
}
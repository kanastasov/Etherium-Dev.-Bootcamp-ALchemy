//secp.utils.randomPrivateKey was not founding, saw in the comments other people were having the same propblem.
//const secp = require('ethereum-cryptography/secp256k1');
const {secp256k1} = require("ethereum-cryptography/secp256k1");

const crypto = require('crypto');
const { toHex } = require("ethereum-cryptography/utils");

//const privateKey = secp256k1.util.randomPrivateKey(); // 32 bytes is the size of a secp256k1 private key
//const privateKey = secp.utils.randomPrivateKey();

const privateKey = secp256k1.utils.randomPrivateKey();//
//const privateKey = crypto.randomBytes(256); 
console.log('privateKey:', toHex(privateKey));

const publicKey = secp256k1.getPublicKey(privateKey);
console.log('publicKey:', toHex(publicKey));

const secp = require("ethereum-cryptography/secp256k1");
const hashMessage = require("./hashMessage");

async function recoverKey(message, signature, recoveryBit) {
  const hashedMessage = hashMessage(message);
  const publicKey = secp.recoverPublicKey(hashedMessage, signature, recoveryBit);
  return publicKey;
}

module.exports = recoverKey;
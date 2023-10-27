const { keccak256 } = require("ethereum-cryptography/keccak");
const { toHex, utf8ToBytes } = require("ethereum-cryptography/utils");

function firstTopic() {
    const eventSignature = "Transfer(address,address,uint256)"; 
    const bytes = utf8ToBytes(eventSignature);
    const digest = keccak256(bytes);
    return toHex(digest); 
}

function secondTopic() {
    const address = "28c6c06298d514db089934071355e5743bf21d60";
    return "0".repeat(24) + address;
}

module.exports = { firstTopic, secondTopic }


require("dotenv").config();
const { Alchemy, Network } = require("alchemy-sdk");
const { firstTopic, secondTopic } = require('./topics');
// prefix both the topics with 0x
const topics = [firstTopic(), secondTopic()].map((x) => '0x' + x);

const config = {
    apiKey: process.env.API_KEY,
    network: Network.ETH_MAINNET,
};

const alchemy = new Alchemy(config);

async function totalDaiTransferred(fromBlock, toBlock) {
    const logs = await alchemy.core.getLogs({
        address: "0x6b175474e89094c44da98b954eedeac495271d0f",
        fromBlock,
        toBlock,
        topics 
    });

    return logs
        .map((x) => BigInt(x.data))
        .reduce((p, c) => p + c);
}

module.exports = totalDaiTransferred;

require("dotenv").config();
const { Alchemy, Network } = require("alchemy-sdk");

const config = {
    apiKey: process.env.API_KEY,
    network: Network.ETH_MAINNET,
};

const alchemy = new Alchemy(config);

async function totalErc20Transfers(fromBlock, toBlock) {
    const res = await alchemy.core.getAssetTransfers({
        fromBlock,
        toBlock,
        fromAddress: "0x28c6c06298d514db089934071355e5743bf21d60",
        category: ["erc20"]
    });

    return res.transfers.length;
}

module.exports = totalErc20Transfers;

const { assert } = require('chai');
const totalErc20Transfers = require('../');

describe('totalErc20Transfers', () => {
    it('should work for a block interval containing 184 ERC20 transfers', async () => {
        const total = await totalErc20Transfers("0xff2db0", "0xff2eb0");
        assert.equal(total, 184);
    });

    it('should work for a block interval containing 572 transfers', async () => {
        const total = await totalErc20Transfers("0xff2ab0", "0xff2eb0");
        assert.equal(total, 572);
    });
});
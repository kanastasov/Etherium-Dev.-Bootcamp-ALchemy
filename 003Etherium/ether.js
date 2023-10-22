const ethers = require('ethers');
const { Wallet } = ethers;

// create a wallet with a private key
const wallet1 = new Wallet("0xf2f48ee19680706196e2e339e5da3491186e0c4c5030670656b0e0164837257d");

// create a wallet from mnemonic
const wallet2 = Wallet.fromMnemonic("plate lawn minor crouch bubble evidence palace fringe bamboo laptop dutch ice");

module.exports = {
    wallet1,
    wallet2,
}


const { assert } = require('chai');
const { wallet1, wallet2 } = require('../wallets');
const { Wallet } = require('ethers');

describe('wallets', () => {
    describe('wallet 1', () => {
        it('should be an instance of wallet', () => {
            assert(wallet1 instanceof Wallet);
        });

        it('should unlock the expected address', () => {
            assert.equal(wallet1.address, "0x5409ED021D9299bf6814279A6A1411A7e866A631");
        });
    });
    describe('wallet 2', () => {
        it('should be an instance of wallet', () => {
            assert(wallet2 instanceof Wallet);
        });

        it('should unlock the expected address', () => {
            assert.equal(wallet2.address, "0x88E9DD325BA8329dDD9825c1d24e8470b25575C1");
        });
    });
});

const ethers = require('ethers');
const { Wallet, utils } = ethers;
const { wallet1 } = require('./wallets');

// sign the transaction using our wallet's private key
const signaturePromise = wallet1.signTransaction({
    value: utils.parseEther("1.0"), 
    to: "0xdD0DC6FB59E100ee4fA9900c2088053bBe14DE92",
    gasLimit: 0x5208,
});

module.exports = signaturePromise;

const { assert } = require('chai');
const signaturePromise = require('../sign');
const { utils } = require('ethers');

describe('signaturePromise', () => {
    it('should be an instance of Promise', () => {
        assert(signaturePromise instanceof Promise);
    });

    it('should resolve with a hexadecimal representation of the transaction', async () => {
        const hex = await signaturePromise;
        const matches = /^0x[0-9A-Fa-f]*$/.test(hex);
        if(!matches) console.log(hex);
        assert(matches, 'did not match the expect hash output');
    });

    describe('parsed properties', () => {
        let parsed;
        before(async () => {
            const hex = await signaturePromise;
            parsed = utils.parseTransaction(hex);
        });

        it('should contain the to address', () => {
            assert.equal(parsed.to, "0xdD0DC6FB59E100ee4fA9900c2088053bBe14DE92");
        });

        it('should contain the value', () => {
            assert.equal(parsed.value.toString(), "1000000000000000000");
        });

        it('should have the appropriate gas limit for transfers', () => {
            assert(parsed.gasLimit.eq(21000), "The gas limit should be 21000");
        });

        it('should derive the from address', () => {
            assert.equal(parsed.from, "0x5409ED021D9299bf6814279A6A1411A7e866A631");
        });
		
    });
});

const { Wallet, utils, providers } = require('ethers');
const { ganacheProvider, PRIVATE_KEY } = require('./config');

const provider = new providers.Web3Provider(ganacheProvider);

const wallet = new Wallet(PRIVATE_KEY, provider);

async function sendEther({ value, to }) {
   const rawTx = await wallet.sendTransaction ({ 
        value, to, 
        gasLimit: 0x5208,
        gasPrice: 0x3b9aca00 
    });
  return rawTx;
  //return provider.sendTransaction(rawTx);
}

module.exports = sendEther;

const { assert } = require('chai');
const sendEther = require('../sendEther');
const ethers = require('ethers');
const { ganacheProvider } = require('../config');

const provider = new ethers.providers.Web3Provider(ganacheProvider);
let tx;
describe('sendEther', () => {
    before(async () => {
        tx = await sendEther({
            value: ethers.utils.parseEther("1.0"),
            to: "0xdD0DC6FB59E100ee4fA9900c2088053bBe14DE92",
        });
    })
    it('should resolve with a transaction', async () => {
        assert(tx, "The function did not resolve with a transaction. Did you return the transaction promise?")
        assert.equal(tx.to, "0xdD0DC6FB59E100ee4fA9900c2088053bBe14DE92");
        assert.equal(tx.from, "0x5409ED021D9299bf6814279A6A1411A7e866A631");
        assert(tx.hash);
    });
    it('should get mined', async () => {
        const receipt = await provider.waitForTransaction(tx.hash);
        assert(receipt);
        assert.equal(receipt.blockNumber, 1);
    });
});

const { Wallet, providers } = require('ethers');
const { ganacheProvider } = require('./config');

const provider = new providers.Web3Provider(ganacheProvider);

function findMyBalance(privateKey) {
    const wallet = new Wallet(privateKey, provider);
    return wallet.getBalance();
}

module.exports = findMyBalance;

const { assert } = require('chai');
const findMyBalance = require('../findMyBalance')
const { PRIVATE_KEY, INITIAL_BALANCE } = require('../config');

describe('findMyBalance', () => {
    it('should return an instance of Promise', () => {
        assert(findMyBalance(PRIVATE_KEY) instanceof Promise);
    });
    it('should resolve with the initial balance', async () => {
        const balance = await findMyBalance(PRIVATE_KEY);
        assert(INITIAL_BALANCE.eq(balance));
    });
});

const { utils, providers, Wallet } = require('ethers');
const { ganacheProvider } = require('./config');

const provider = new providers.Web3Provider(ganacheProvider);

async function donate(privateKey, charities) {
    const oneEther = utils.parseEther("1.0");
    const wallet = new Wallet(privateKey, provider);
    for(let i = 0; i < charities.length; i++) {
        const charity = charities[i];
        await wallet.sendTransaction({
            value: oneEther,
            to: charity
        });
    } 
}

module.exports = donate;

const { assert } = require('chai');
const donate = require('../donate');
const { PRIVATE_KEY, ganacheProvider } = require('../config');

const ethers = require('ethers');
const provider = new ethers.providers.Web3Provider(ganacheProvider);

const charities = [
    '0xBfB25955691D8751727102A59aA49226C401F8D4',
    '0xd364d1F83827780821697C787A53674DC368eC73',
    '0x0df612209f74E8Aa37432c14F88cb8CD2980edb3',
]

const donationPromise = donate(PRIVATE_KEY, charities);
describe('donate', () => {
    it('should return an instance of Promise', () => {
        assert(donationPromise instanceof Promise);
    });
    it('should increase the balance of each charity', async () => {
        await donationPromise;
        for(let i = 0; i < charities.length; i++) {
            const charity = charities[i];
            const balance = await provider.getBalance(charities[i]);
            assert.isAtLeast(+balance, +ethers.utils.parseEther("1.0"));
        }
    });
});

const { providers } = require('ethers');
const { ganacheProvider } = require('./config');

const provider = new providers.Web3Provider(ganacheProvider);

async function findEther(address) {
    const addresses = [];
    const blockNumber = await provider.getBlockNumber();
    for (let i = 0; i <= blockNumber; i++) {
        const block = await provider.getBlockWithTransactions(i);
        block.transactions.forEach((tx) => {
            if(tx.from === address) {
                addresses.push(tx.to);
            }
        });
    }
    return addresses;
}

module.exports = findEther;

const { utils } = require('ethers');
const Ganache = require("ganache-core");
const PRIVATE_KEY = "0xf2f48ee19680706196e2e339e5da3491186e0c4c5030670656b0e0164837257d";
const INITIAL_BALANCE = utils.parseEther('10');

// create our test account from the private key, initialize it with 10 ether
const accounts = [].concat([{
    balance: INITIAL_BALANCE.toHexString(),
    secretKey: PRIVATE_KEY,
}]);

const ganacheProvider = Ganache.provider({ accounts });

module.exports = {
    INITIAL_BALANCE,
    PRIVATE_KEY,
    ganacheProvider,
}


const { assert } = require('chai');
const { PRIVATE_KEY, ganacheProvider } = require('../config');
const { utils, Wallet, providers } = require('ethers');
const findEther = require('../findEther');

const FROM_ADDRESS = "0x5409ED021D9299bf6814279A6A1411A7e866A631";
const provider = new providers.Web3Provider(ganacheProvider);
const wallet = new Wallet(PRIVATE_KEY, provider);

function rpc(method) {
    return new Promise((resolve, reject) => {
        ganacheProvider.send({ id: 1, jsonrpc: "2.0", method }, () => {
            resolve();
        });
    });
}

const stopMiner = () => rpc('miner_stop');
const mineBlock = () => rpc('evm_mine');

describe('findEther', () => {
    const expected = [];

    const sendEther = async (i) => {
        const address = Wallet.createRandom().address;
        await wallet.sendTransaction({
            value: utils.parseEther(".5"),
            to: address,
            nonce: i,
        });
        expected.push(address);
    }

    before(async () => {
        stopMiner();
        let i = 0; 
        // block 1
        for (; i < 3; i++) await sendEther(i);
        await mineBlock();
        // block 2
        for (; i < 7; i++) await sendEther(i);
        await mineBlock();
        // block 3
        for (; i < 10; i++) await sendEther(i);
        await mineBlock();
    });

    it('should find all the addresses', async () => {
        const actual = await findEther(FROM_ADDRESS);
        const err = `Sent ether to ${expected.length} addresses, you returned ${actual.length}`;
        assert.equal(actual.length, expected.length, err);
        assert.sameMembers(actual, expected);
    });
});
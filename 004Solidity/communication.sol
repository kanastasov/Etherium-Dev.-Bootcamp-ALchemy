/**
 * Find the `value` stored in the contract
 *
 * @param {ethers.Contract} contract - ethers.js contract instance
 * @return {promise} a promise which resolves with the `value`
 */
function getValue(contract) {
    const number = contract.value();
    return number;
}

module.exports = getValue;

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract Contract {
	uint public value;

	constructor(uint _value) {
		value = _value;
	}
}


const { assert } = require('chai');
const getValue = require('../index');

describe('Contract', function () {
    const random = Math.floor(Math.random() * 1000);
    let contract;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy(random);
        await contract.deployed();
    });

    it('should get the value', async () => {
        const value = await getValue(contract);
        assert.equal(value, random);
    });
});


/**
 * Modify the `value` stored in the contract
 *
 * @param {ethers.Contract} contract - ethers.js contract instance
 * @return {promise} a promise of transaction
 */
function setValue(contract) {
    contract.modify(10);
}

module.exports = setValue;

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract Contract {
	uint public value;

	function modify(uint _value) external {
		value = _value;
	}
}

const { assert } = require('chai');
const setValue = require('../index');

describe('Contract', function () {
    let contract;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();
    });

    it('should set the value', async () => {
        await setValue(contract);
        const value = await contract.value();
        assert(value.gt(0), "Expecting value to be modified. Still set at 0!");
    });
});


/**
 * Transfer funds on the contract from the current signer 
 * to the friends address
 *
 * @param {ethers.Contract} contract - ethers.js contract instance
 * @param {string} friend - a string containing a hexadecimal ethereum address
 * @return {promise} a promise of the transfer transaction
 */
function transfer(contract, friend) {
    return contract.transfer(friend, 100)
}

module.exports = transfer;

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract Token {
    mapping(address => uint) public balances;

    constructor() {
        balances[msg.sender] = 1000;
    }

    function transfer(address beneficiary, uint amount) external {
        require(balances[msg.sender] >= amount, "Balance too low!");
        balances[beneficiary] += amount;
        balances[msg.sender] -= amount;
    }
}


const { assert } = require('chai');
const transfer = require('../index');

describe('Token', function () {
    let contract;
    let owner;
    let friend;
    before(async () => {
        const accounts = await ethers.provider.listAccounts();
        owner = accounts[1];
        friend = accounts[2];
        
        const Contract = await ethers.getContractFactory("Token");
        contract = await Contract.deploy();
        await contract.deployed();
    });

    describe('after transfer', () => {
        before(async () => {
            await transfer(contract, friend);
        });

        it('should decrease the owner balance', async () => {
            const balance = await contract.balances(owner);
            assert(balance.lt(1000));
        });

        it('should increase the friend balance', async () => {
            const balance = await contract.balances(friend);
            assert(balance.gt(0));
        });
    });
});


function setMessage(contract, signer) {
    return contract.connect(signer).modify("Hello World!");
}

module.exports = setMessage;

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract Contract {
    address owner;
    string public message;

    constructor() {
        owner = msg.sender;
    }

    function modify(string calldata _message) external {
        require(msg.sender != owner, "Owner cannot modify the message!");
        message = _message;
    }
}

const { assert } = require('chai');
const setMessage = require('../index');

describe('Contract', function () {
    let contract;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();
    });

    it('should set the value', async () => {
        await setMessage(contract, ethers.provider.getSigner(1));
        const message = await contract.message();
        assert.notEqual(message, "", "Expecting message to be modified. Still set to an empty string!");
    });
});


const ethers = require('ethers');

function deposit(contract) {
    return contract.deposit({ value: ethers.utils.parseEther("1") });
}

module.exports = deposit;
// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract Contract {
    function deposit() payable external { }
}

const { assert } = require('chai');
const deposit = require('../index');

describe('Contract', function () {
    let contract;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();
    });

    it('should deposit at least 1 ether', async () => {
        await deposit(contract);
        const balance = await ethers.provider.getBalance(contract.address);
        assert(balance.gte(ethers.utils.parseEther("1")));
    });
});

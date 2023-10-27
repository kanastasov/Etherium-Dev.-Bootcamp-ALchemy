// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {
    address[] public owners;
    uint public transactionCount;
    uint public required;

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
        bytes data;
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;

    receive() payable external {
        
    }

    function executeTransaction(uint transactionId) public {
        require(isConfirmed(transactionId));
        Transaction storage _tx = transactions[transactionId];
        (bool success, ) = _tx.destination.call{ value: _tx.value }(_tx.data);
        require(success, "Failed to execute transaction");
        _tx.executed = true;
    }

    function isConfirmed(uint transactionId) public view returns(bool) {
        return getConfirmationsCount(transactionId) >= required;
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint) {
        uint count;
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function isOwner(address addr) private view returns(bool) {
        for(uint i = 0; i < owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address payable dest, uint value, bytes memory data) external {
        uint id = addTransaction(dest, value, data);
        confirmTransaction(id);
    }

    function confirmTransaction(uint transactionId) public {
        require(isOwner(msg.sender));
        confirmations[transactionId][msg.sender] = true;
        if(isConfirmed(transactionId)) {
            executeTransaction(transactionId);
        }
    }

    function addTransaction(address payable destination, uint value, bytes memory data) public returns(uint) {
        transactions[transactionCount] = Transaction(destination, value, false, data);
        transactionCount += 1;
        return transactionCount - 1;
    }

    constructor(address[] memory _owners, uint _confirmations) {
        require(_owners.length > 0);
        require(_confirmations > 0);
        require(_confirmations <= _owners.length);
        owners = _owners;
        required = _confirmations;
    }
}


const { assert } = require('chai');
describe('MultiSig', function () {
    let contract;
    let accounts;
    beforeEach(async () => {
        accounts = await ethers.provider.listAccounts();
        const MultiSig = await ethers.getContractFactory("MultiSig");
        contract = await MultiSig.deploy(accounts.slice(0, 3), 1);
        await contract.deployed();
    });

    describe('storing ERC20 tokens', function () {
        const initialBalance = 10000;
        let token;

        beforeEach(async () => {
            const EIP20 = await ethers.getContractFactory("EIP20");
            token = await EIP20.deploy(initialBalance, 'My Token', 1, 'MT');
            await token.deployed();
            await token.transfer(contract.address, initialBalance);
        });

        it('should store the balance', async () => {
            const balance = await token.balanceOf(contract.address);
            assert.equal(balance.toNumber(), initialBalance);
        });

        describe('executing an ERC20 transaction', function () {
            beforeEach(async () => {
                const data = token.interface.encodeFunctionData("transfer", [accounts[2], initialBalance]);
                await contract.submitTransaction(token.address, 0, data);
            });

            it('should have removed the contract balance', async () => {
                const balance = await token.balanceOf(contract.address);
                assert.equal(balance.toNumber(), 0);
            });

            it('should have moved the balance to the destination', async () => {
                const balance = await token.balanceOf(accounts[2]);
                assert.equal(balance.toNumber(), initialBalance);
            });
        });
    });

    describe('storing ether', function () {
        const oneEther = ethers.utils.parseEther("1");
        beforeEach(async () => {
            await ethers.provider.getSigner(0).sendTransaction({ to: contract.address, value: oneEther });
        });

        it('should store the balance', async () => {
            const balance = await ethers.provider.getBalance(contract.address);
            assert.equal(balance.toString(), oneEther.toString());
        });

        describe('executing the ether transaction', function () {
            let balanceBefore;

            beforeEach(async () => {
                balanceBefore = await ethers.provider.getBalance(accounts[1]);
                await contract.submitTransaction(accounts[1], oneEther, "0x");
            });

            it('should have removed the contract balance', async () => {
                const balance = await ethers.provider.getBalance(contract.address);
                assert.equal(balance, 0);
            });

            it('should have moved the balance to the destination', async () => {
                const balance = await ethers.provider.getBalance(accounts[1]);
                assert.equal(balance.sub(balanceBefore).toString(), oneEther.toString());
            });
        });
    });
});

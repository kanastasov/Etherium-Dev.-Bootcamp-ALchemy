// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Token {
    uint public totalSupply;

    string public name = "name";
    string public symbol = "sym";
    uint8 public decimals = 18;

    mapping (address => uint256) public balances;

 	event Transfer(address indexed from, address indexed to, uint256 tokens);

    constructor(){
        totalSupply = 1000000000000000000000;
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address add) external view returns(uint){
        return balances[add];
    }

    function transfer(address recipient, uint amount) public returns(bool){
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[recipient]+=amount;

        emit Transfer(msg.sender,recipient,amount);
        return true;
    }
}

const { assert } = require('chai');
describe("Token", () => {
    const totalSupply = ethers.utils.parseEther("1000");
    let token;
    let owner, ownerSigner, a1, s1;

    beforeEach(async () => {
        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy();
        await token.deployed();

        const accounts = await ethers.provider.listAccounts();
        owner = accounts[0];
        ownerSigner = ethers.provider.getSigner(owner);
        a1 = accounts[1];
        s1 = ethers.provider.getSigner(a1);
    });

    describe('ERC20 Standard', () => {
        context('transfer', () => {
            describe('the owner transfers a value of 1 to the recipient', () => {
                let receipt;
                beforeEach(async () => {
                    const tx = await token.connect(ownerSigner).transfer(a1, "1");
                    receipt = await tx.wait();
                });

                it('should emit the event', () => {
                    const transferEvent = receipt.events.find(x => x.event === "Transfer");
                    assert(transferEvent, "Expect an event named Transfer to be emitted!");
                    const sender = transferEvent.args[0];
                    const recipient = transferEvent.args[1];
                    const amount = transferEvent.args[2];
                    assert.equal(sender, owner, "Expected the sender address to be the first argument in Transfer");
                    assert.equal(recipient, a1, "Expected the recipient address to be the second argument in Transfer");
                    assert.equal(amount.toString(), "1", "Expected the transfer amount to be the third argument in Transfer");
                });

                it('should decrease the owner\'s balance by 1', async () => {
                    const balance = await token.callStatic.balanceOf(owner);
                    assert.equal(
                        balance.toString(),
                        totalSupply.sub("1").toString()
                    );
                });

                it('should increase the recipient\'s balance to 1', async () => {
                    const balance = await token.callStatic.balanceOf(a1)
                    assert.equal(balance.toString(), '1')
                });

                describe('second transfer', async () => {
                    let receipt;
                    beforeEach(async () => {
                        const tx = await token.connect(ownerSigner).transfer(a1, "1");
                        receipt = await tx.wait();
                    });

                    it('should emit the event', () => {
                        const transferEvent = receipt.events.find(x => x.event === "Transfer");
                        assert(transferEvent, "Expect an event named Transfer to be emitted!");
                        const sender = transferEvent.args[0];
                        const recipient = transferEvent.args[1];
                        const amount = transferEvent.args[2];
                        assert.equal(sender, owner, "Expected the sender address to be the first argument in Transfer");
                        assert.equal(recipient, a1, "Expected the recipient address to be the second argument in Transfer");
                        assert.equal(amount.toString(), "1", "Expected the transfer amount to be the third argument in Transfer");
                    });

                    it('should decrease the owner\'s balance by 1', async () => {
                        const balance = await token.callStatic.balanceOf(owner)
                        assert.equal(
                            balance.toString(),
                            totalSupply.sub("2").toString()
                        );
                    });

                    it('should increase the recipient\'s balance by 1', async () => {
                        const balance = await token.callStatic.balanceOf(a1);
                        assert.equal(balance.toString(), '2');
                    });
                });
            });

            describe('transferring without the funds', () => {
                it('should not be allowed', async () => {
                    let ex;
                    try {
                        await token.connect(s1).transfer(owner, "1");
                    }
                    catch (_ex) {
                        ex = _ex;
                    }
                    assert(ex, "The account should not have any funds. Expected this transaction to revert!");
                });
            });
        });

        context('balanceOf', () => {
            it('should return zero for any address other than the contract creator', async () => {
                const balance = await token.callStatic.balanceOf(a1);
                assert.equal(balance.toString(), '0');
            });

            it('should return the total supply for the contract creator', async () => {
                const balance = await token.callStatic.balanceOf(owner);
                assert.equal(balance.toString(), totalSupply.toString());
            });
        });

        context('totalSupply', () => {
            it('should return zero', async () => {
                const result = await token.callStatic.totalSupply();
                assert.equal(result.toString(), totalSupply.toString());
            });
        });
    });

    describe('ERC20 Optional', () => {
        context('`name`', () => {
            it('should return the correct name', async () => {
                const name = await token.callStatic.name();
                assert.isAtLeast(name.length, 1);
            });
        });

        context('`symbol`', () => {
            it('should return the correct name', async () => {
                const sym = await token.callStatic.symbol();
                assert.equal(sym.length, 3);
            });
        });

        context('`decimals`', () => {
            it('should return the correct name', async () => {
                const decimals = await token.callStatic.decimals();
                assert.equal(decimals, 18);
            });
        });
    });
});
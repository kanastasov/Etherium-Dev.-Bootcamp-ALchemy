pragma solidity ^0.8.4;

contract Contract {
    
    function sumAndAverage(uint first, uint second, uint third, uint fourth) external pure returns(uint sum, uint average){
        sum = first + second + third + fourth;
        average = sum /4;
    }
}

const { assert } = require('chai');
describe('Contract', function () {
    let contract;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();
    });

    [[2,2,4,4], [1,3,5,7], [8,8,8,8]].forEach(([a,b,c,d]) => {
        const expectedSum = a + b + c + d;
        const expectedAverage = expectedSum / 4;
        describe(`for ${a}, ${b}, ${c} and ${d}`, () => {
            it(`it should return ${expectedSum} and ${expectedAverage}`, async () => {
                const values = await contract.sumAndAverage(a,b,c,d);
                assert.equal(values[0], expectedSum);
                assert.equal(values[1], expectedAverage);
            });
        });
    });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
    uint8 x = 0;
    function tick() external{
        ++x;
        if(x == 10){
         selfdestruct(payable(msg.sender));
        }
    }
}

const { assert } = require('chai');
describe('Contract', function () {
    let contract;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();
    });

    describe('after 9 ticks', () => {
        before(async () => {
            for (let i = 0; i < 9; i++) {
                await contract.tick();
            }
        });

        it('should still exist', async () => {
            const bytecode = await ethers.provider.getCode(contract.address);
            assert(bytecode !== "0x", "Contract does not exist after 9 ticks!");
        });
    });

    describe('after the tenth tick', () => {
        before(async () => {
            await contract.tick();
        });

        it('should not have any code', async () => {
            const bytecode = await ethers.provider.getCode(contract.address);
            assert.equal(bytecode, "0x");
        });
    });
});
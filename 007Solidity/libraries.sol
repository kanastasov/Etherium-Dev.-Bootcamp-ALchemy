// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./UIntFunctions.sol";

contract Game {
    using UIntFunctions for uint;
    uint public participants;
    bool public allowTeams;

    constructor(uint _participants) {
        if(_participants.isEven()) {
            allowTeams = true;
        }

        participants = _participants;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library UIntFunctions {
	function isEven(uint x) public pure returns(bool) {
		return x % 2 == 0;
	} 
}


const { assert } = require('chai');
describe('Game', function () {
    let library; 
    before(async () => {
        const Library = await ethers.getContractFactory("UIntFunctions");
        library = await Library.deploy();
        await library.deployed();
    });

    [2, 4, 6].forEach((participants) => {
        describe(`for an even game of ${participants} participants`, () => {
            let contract;
            before(async () => {
                const Contract = await ethers.getContractFactory("Game", {
                    libraries: { UIntFunctions: library.address }
                });
                contract = await Contract.deploy(participants);
                await contract.deployed();
            });

            it('should store the number of participants', async () => {
                const actual = await contract.callStatic.participants();
                assert.equal(actual, participants);
            });

            it('should allow teams', async () => {
                const allowed = await contract.callStatic.allowTeams();
                assert(allowed);
            });
        });
    });

    [3, 5, 7].forEach((participants) => {
        describe(`for an odd game of ${participants} participants`, () => {
            let contract;
            before(async () => {
                const Contract = await ethers.getContractFactory("Game", {
                    libraries: { UIntFunctions: library.address }
                });
                contract = await Contract.deploy(participants);
                await contract.deployed();
            });

            it('should store the number of participants', async () => {
                const actual = await contract.participants.call();
                assert.equal(actual, participants);
            });

            it('should not allow teams', async () => {
                const allowed = await contract.allowTeams.call();
                assert(!allowed);
            });
        });
    });
});


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Prime {
	function dividesEvenly(uint x, uint y) public pure returns(bool) {
		return (x % y == 0);
	}

	function isPrime(uint x) public pure returns(bool) {
		for(uint i = 2; i <= x / 2; i++) {
			if(dividesEvenly(x, i)) {
				return false;
			}
		}
		return true;
	}
}


const { assert } = require('chai');
describe('Prime', function () {
    let library;
    before(async () => {
        const Prime = await ethers.getContractFactory("Prime");
        library = await Prime.deploy();
        await library.deployed();
    });

    it('should detect prime numbers', async () => {
        const primes = [5, 17, 47];
        for (let i = 0; i < primes.length; i++) {
            const prime = primes[i];
            const isPrime = await library.callStatic.isPrime(prime);
            assert(isPrime, `Expected isPrime to return true for ${prime}!`);
        }
    });

    it('should detect non-prime numbers', async () => {
        const nonPrimes = [4, 18, 51];
        for (let i = 0; i < nonPrimes.length; i++) {
            const nonPrime = nonPrimes[i];
            const isPrime = await library.callStatic.isPrime(nonPrime);
            assert(!isPrime, `Did not expect isPrime to return true for ${nonPrime}!`);
        }
    });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Prime.sol";

contract PrimeGame {
    using Prime for uint;

    function isWinner() public view returns (bool) {
        return block.number.isPrime();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
	address public owner;
	address public charity;

	constructor(address _charity) {
		owner = msg.sender;
		charity = _charity;
	}

	receive() external payable { }

	function donate() public {
		(bool success, ) = charity.call{ value: address(this).balance }("");
		require(success);
		selfdestruct(payable(msg.sender));

	}

	function tip() public payable {
		(bool success, ) = owner.call{ value: msg.value }("");
		require(success);
	}
}


const { assert } = require('chai');
describe('Contract', function () {
    const charity = ethers.Wallet.createRandom().address;
    const donation = ethers.utils.parseEther("1");
    let contract;
    let owner;
    let tipper;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy(charity);
        await contract.deployed();

        owner = ethers.provider.getSigner(0);
        await owner.sendTransaction({ to: contract.address, value: donation });
        tipper = ethers.provider.getSigner(1);
    });

    it('should store the owner', async () => {
        const _owner = await contract.owner.call();
        assert.equal(_owner, await owner.getAddress());
    });

    it('should receive the initial donation', async () => {
        const balance = await ethers.provider.getBalance(contract.address);
        assert(balance.eq(donation), "expected the ether to be received");
    });

    describe('after donating', () => {
        before(async () => {
            await contract.connect(tipper).donate();
        });

        it('should add the donations to the charity balance', async () => {
            const _donation = await ethers.provider.getBalance(charity);
            assert.equal(_donation.toString(), donation.toString());
        });

        it('should destroy the contract', async () => {
            const bytecode = await ethers.provider.getCode(contract.address);
            assert.equal(bytecode, "0x");
        });
    });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
	address owner;

	constructor() payable {
		owner = msg.sender;
		require(msg.value >= 1 ether, "Not enough ether sent");
	}

	function withdraw() public {
		require(msg.sender == owner);
		payable(msg.sender).transfer(address(this).balance);
	}
}


const { assert } = require('chai');
describe('Contract', function () {
    let contract;
    const value = ethers.utils.parseEther("2");
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy({ value });
        await contract.deployed();
    });

    it('should fail when another account attempts to withdraw', async () => {
        let ex;
        try {
            const signer = ethers.provider.getSigner(1);
            await contract.connect(signer).withdraw();
        }
        catch (_ex) { ex = _ex }
        if (!ex) {
            assert.fail("Attempt to withdraw with non-owner did not fail!");
        }
    });

    it('should succeed when the owner attempts to withdraw', async () => {
        const owner = ethers.provider.getSigner(0);
        const balanceBefore = await ethers.provider.getBalance(await owner.getAddress());
        const gasPrice = ethers.utils.parseUnits("2", "gwei");
        const tx = await contract.connect(owner).withdraw({ gasPrice });
        const receipt = await tx.wait();
        const etherUsed = receipt.gasUsed.mul(gasPrice);
        const balanceAfter = await ethers.provider.getBalance(await owner.getAddress());
        assert.equal(
            balanceAfter.toString(),
            balanceBefore.sub(etherUsed).add(value).toString(),
            "Unexpected Owner Balance (did you withdraw all funds?)"
        );
    });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract Contract {
	address owner;
	uint configA;
	uint configB;
	uint configC;

	
	constructor() {
		owner = msg.sender;
	}

	function setA(uint _configA) public onlyOwner {
		configA = _configA;
	}

	function setB(uint _configB) public onlyOwner {
		configB = _configB;
	}

	function setC(uint _configC) public onlyOwner {
		configC = _configC;
	}

	modifier onlyOwner {
		require(owner == msg.sender);
		_;
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

    it('should fail when another account attempts to set a config variable', async () => {
        const vals = ['A', 'B', 'C'];
        const other = ethers.provider.getSigner(1);
        for (let i = 0; i < vals.length; i++) {
            const val = vals[i];
            const methodName = `set${val}`;
            let ex;
            try {
                await contract.connect(other)[methodName](1);
            }
            catch (_ex) { ex = _ex; }
            if (!ex) {
                assert.fail(`Call to ${methodName} with non-owner did not fail!`);
            }
        }
    });

    it('should not fail when owner attempts to set a config variable', async () => {
        const vals = ['A', 'B', 'C'];
        for (let i = 0; i < vals.length; i++) {
            const val = vals[i];
            const methodName = `set${val}`;
            await contract[methodName](1);
        }
    });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Sidekick {
    function sendAlert(address hero, uint enemies, bool armed) external {
        (bool success, ) = hero.call(
            abi.encodeWithSignature("alert(uint256,bool)", enemies, armed)
        );

        require(success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Hero {
    Ambush public ambush;

    struct Ambush {
        bool alerted;
        uint enemies;
        bool armed;
    }

    function alert(uint enemies, bool armed) external {
        ambush = Ambush(true, enemies, armed);
    }
}

const { assert } = require("chai");
const { ethers } = require("hardhat");

describe("Contracts2", () => {
    let hero, sidekick;
    before(async () => {
        const Hero = await ethers.getContractFactory("Hero");
        hero = await Hero.deploy();

        const Sidekick = await ethers.getContractFactory("Sidekick");
        sidekick = await Sidekick.deploy();
    });

    describe("after sending the alert", () => {
        before(async () => {
            await sidekick.sendAlert(hero.address, 5, true);
        });

        it("should have the sidekick alert the hero", async () => {
            const ambush = await hero.ambush();

            assert(ambush.alerted);
            assert.equal(ambush.enemies, 5);
            assert.equal(ambush.armed, true);
        });
    });
});


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Sidekick {
    function relay(address hero, bytes memory data) external {
        (bool success, ) = hero.call(data);

        require(success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Hero {
    Ambush public ambush;

    struct Ambush {
        bool alerted;
        uint enemies;
        bool armed;
    }

    uint lastContact;

    function alert(uint enemies, bool armed) external {
        ambush = Ambush(true, enemies, armed);
    }
}

const { assert } = require("chai");

describe('Sidekick', function () {
    let sidekick, hero;
    beforeEach(async () => {
        const Sidekick = await ethers.getContractFactory("Sidekick");
        sidekick = await Sidekick.deploy();

        const Hero = await ethers.getContractFactory("Hero");
        hero = await Hero.deploy();

        const calldata = hero.interface.encodeFunctionData('alert', [5, true]);
        await sidekick.relay(hero.address, calldata);
    });

    it("should have the sidekick alert the hero", async () => {
        const ambush = await hero.ambush();

        assert(ambush.alerted);
        assert.equal(ambush.enemies, 5);
        assert.equal(ambush.armed, true);
    });
});


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Sidekick {
    function makeContact(address hero) external {
        (bool success, ) = hero.call(abi.encodeWithSignature("alert(uint,bool)", 10, true));

        require(success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Hero {
    Ambush public ambush;

    struct Ambush {
        bool alerted;
        uint enemies;
        bool armed;
    }

    uint public lastContact;

    function alert(uint enemies, bool armed) external {
        ambush = Ambush(true, enemies, armed);
    }
    
    fallback() external {
        lastContact = block.timestamp;
    }
}

const { assert } = require("chai");
const { ethers } = require("hardhat");

describe("Contracts2", () => {
    let hero, sidekick;
    before(async () => {
        const Hero = await ethers.getContractFactory("Hero");
        hero = await Hero.deploy();

        const Sidekick = await ethers.getContractFactory("Sidekick");
        sidekick = await Sidekick.deploy();
    });

    describe("after sending the alert", () => {
        before(async () => {
            await sidekick.makeContact(hero.address);
        });

        it("should update the last contract", async () => {
            const lastContact = await hero.lastContact();

            assert.notEqual(lastContact.toNumber(), 0);
        });
    });
});

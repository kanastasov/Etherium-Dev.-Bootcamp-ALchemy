// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
    mapping (address => bool) public members;

    function addMember(address adr) external{
        members[adr] = true;
    }
    function isMember(address adr)external returns(bool isAMember){
        isAMember = members[adr];

    }

    function removeMember(address adr) external{
        members[adr] = false;
    }
}

const { assert } = require('chai');
describe('Contract', function () {
    let members;
    let nonMember;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();

        const accounts = await ethers.provider.listAccounts();
        members = accounts.slice(0, 2);
        nonMember = accounts[2];
    });

    describe('adding a couple members', () => {
        before(async () => {
            for (let i = 0; i < members.length; i++) {
                await contract.addMember(members[i]);
            }
        });

        it('should find added members', async () => {
            for (let i = 0; i < members.length; i++) {
                assert(await contract.callStatic.isMember(members[i]));
            }
        });

        it('should not find a non-added member', async () => {
            assert(!(await contract.callStatic.isMember(nonMember)));
        });

        describe('after removing a member', () => {
            before(async () => {
                await contract.removeMember(members[0]);
            });

            it('should not find that member', async () => {
                assert(!(await contract.callStatic.isMember(members[0])));
            });

            it('should still find the other member', async () => {
                assert(await contract.callStatic.isMember(members[1]));
            });
        });
    });
});


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
	struct User {
		uint balance;
		bool isActive;
	}

	mapping(address => User) public users;

	function createUser() external {
		require(!users[msg.sender].isActive);
		users[msg.sender] = User(100, true);
	}

	function transfer(address to, uint amount) external {
		require(users[msg.sender].isActive);
		require(users[to].isActive);
		require(users[msg.sender].balance >= amount);
		users[msg.sender].balance -= amount;
		users[to].balance += amount;
	}
}

const { assert } = require('chai');
describe('Contract', function () {
    let a1;
    let a2;
    beforeEach(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();

        a1 = ethers.provider.getSigner(0);
        a2 = ethers.provider.getSigner(1);
    });

    describe('after creating a user', () => {
        beforeEach(async () => {
            await contract.connect(a1).createUser();
        });

        it('should return the user', async () => {
            const user = await contract.users(await a1.getAddress());
            assert.equal(user.balance, 100);
            assert(user.isActive, "Expected a new User to have an isActive boolean that returns true.");
        });

        it('should not allow the same address to create another user', async () => {
            let ex;
            try {
                await contract.connect(a1).createUser();
            }
            catch(_ex) {
                ex = _ex;
            }
            assert(ex, "The same address should not be able to invoke createUser twice. Expected transaction to revert!");
        });

        describe('after creating another user', () => {
            beforeEach(async () => {
                await contract.connect(a2).createUser();
            });

            it('should return the user', async () => {
                const user = await contract.users(await a2.getAddress());
                assert.equal(user.balance, 100);
                assert(user.isActive, "Expected a new User to have an isActive boolean that returns true.");
            });

            it('should not allow the same address to create another user', async () => {
                let ex;
                try {
                    await contract.connect(a2).createUser();
                }
                catch (_ex) {
                    ex = _ex;
                }
                assert(ex, "The same address should not be able to invoke createUser twice. Expected transaction to revert!");
            });
        });
    });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
	struct User {
		uint balance;
		bool isActive;
	}

	mapping(address => User) public users;

	function createUser() external {
		require(!users[msg.sender].isActive);
		users[msg.sender] = User(100, true);
	}

	function transfer(address to, uint amount) external {
		require(users[msg.sender].isActive);
		require(users[to].isActive);
		require(users[msg.sender].balance >= amount);
		users[msg.sender].balance -= amount;
		users[to].balance += amount;
	}
}

const { assert } = require('chai');
describe('Contract', function () {
    let a1;
    let a2;
    beforeEach(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();

        a1 = ethers.provider.getSigner(0);
        a2 = ethers.provider.getSigner(1);
    });

    describe('after creating a user', () => {
        beforeEach(async () => {
            await contract.connect(a1).createUser();
        });

        it('should return the user', async () => {
            const user = await contract.users(await a1.getAddress());
            assert.equal(user.balance, 100);
            assert(user.isActive, "Expected a new User to have an isActive boolean that returns true.");
        });

        it('should not allow the same address to create another user', async () => {
            let ex;
            try {
                await contract.connect(a1).createUser();
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, "The same address should not be able to invoke createUser twice. Expected transaction to revert!");
        });

        it('should not allow a transfer to a non-existent user', async () => {
            let ex;
            try {
                await contract.connect(a1).transfer(await a2.getAddress(), 50);
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, "Should not be able to transfer balance to non-existent user. Expected transaction to revert!");
        });

        describe('after creating another user', () => {
            beforeEach(async () => {
                await contract.connect(a2).createUser();
            });

            it('should return the user', async () => {
                const user = await contract.users(await a2.getAddress());
                assert.equal(user.balance, 100);
                assert(user.isActive, "Expected a new User to have an isActive boolean that returns true.");
            });

            it('should not allow the same address to create another user', async () => {
                let ex;
                try {
                    await contract.connect(a2).createUser();
                }
                catch (_ex) {
                    ex = _ex;
                }
                assert(ex, "The same address should not be able to invoke createUser twice. Expected transaction to revert!");
            });

            it('should be able to transfer to the new user', async () => {
                await contract.connect(a1).transfer(await a2.getAddress(), 50);
                const user1 = await contract.users(await a1.getAddress());
                const user2 = await contract.users(await a2.getAddress());
                assert.equal(user1.balance, 50, "Should subtract the amount from the sender's balance.");
                assert.equal(user2.balance, 150, "Should add the amount to the recipient's balance.");
            });

            it('should not allow a larger transfer than in the users balance', async () => {
                let ex;
                try {
                    await contract.connect(a1).transfer(await a2.getAddress(), 150);
                }
                catch (_ex) {
                    ex = _ex;
                }
                assert(ex, "Cannot transfer more than in the user's balance. Expected transaction to revert!");
            });
        });
    });
});

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
	enum ConnectionTypes { 
		Unacquainted,
		Friend,
		Family
	}
	
	mapping (address => mapping(address => ConnectionTypes)) public connections;

	function connectWith(address other, ConnectionTypes connectionType) external {
        // TODO: make the connection from msg.sender => other => connectionType

		connections[msg.sender][other] = connectionType;
	}
}

const {assert} = require('chai');
const TYPES =  {
    Unacquainted: 0,
    Friend: 1,
    Family: 2
}
describe('Contract', function () {
    let contract;
    let s1;
    let s2;
    let a1;
    let a2;
    beforeEach(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();

        s1 = ethers.provider.getSigner(0);
        s2 = ethers.provider.getSigner(1);
        a1 = await s1.getAddress();
        a2 = await s2.getAddress();
    });

    const getConnection = (x, y) => contract.connections(x, y).then(Number);

    it('should have a Unacquainted connection type from s1 => s2', async () => {
        assert.equal(await getConnection(a1, a2), TYPES.Unacquainted);
    });

    it('should have a Unacquainted connection type from s2 => s1', async () => {
        assert.equal(await getConnection(a2, a1), TYPES.Unacquainted);
    });

    describe('after connecting from both sides', () => {
        beforeEach(async () => {
            await contract.connect(s1).connectWith(a2, TYPES.Friend);    
            await contract.connect(s2).connectWith(a1, TYPES.Friend);    
        });

        it('should have a Friend connection type from s1 => s2', async () => {
            assert.equal(await getConnection(a1, a2), TYPES.Friend);
        });

        it('should have a Friend connection type from s2 => s1', async () => {
            assert.equal(await getConnection(a2, a1), TYPES.Friend);
        });
    });

    describe('after connecting from one side', () => {
        beforeEach(async () => {
            await contract.connect(s1).connectWith(a2, TYPES.Family);
        });

        it('should have a Family connection type from s1 => s2', async () => {
            assert.equal(await getConnection(a1, a2), TYPES.Family);
        });

        it('should have a Unacquainted connection type from s2 => s1', async () => {
            assert.equal(await getConnection(a2, a1), TYPES.Unacquainted);
        });
    });
});
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract Chest {
    function plunder(address[] calldata erc20s) external {
        for(uint i = 0; i < erc20s.length; i++) {
            IERC20 token = IERC20(erc20s[i]);
            uint balance = token.balanceOf(address(this));
            token.transfer(msg.sender, balance);
        }
    }
}


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


const { assert } = require('chai');

describe('Chest', function () {
    let coinCreator, coinCreatorSigner, hunter, hunterSigner; 

    describe('storing erc20 tokens', () => {
        let token1;
        let token2;
        let chest;
        beforeEach(async () => {
            const ERC20 = await ethers.getContractFactory("ERC20FixedSupply");
            
            token1 = await ERC20.deploy(10000);
            await token1.deployed();

            token2 = await ERC20.deploy(10000);
            await token2.deployed();

            const Chest = await ethers.getContractFactory("Chest");
            chest = await Chest.deploy();
            await chest.deployed();

            const accounts = await ethers.provider.listAccounts();
            coinCreator = accounts[0];
            coinCreatorSigner = ethers.provider.getSigner(coinCreator);
            hunter = accounts[1];
            hunterSigner = ethers.provider.getSigner(hunter);
        });

        describe('storing some token1', () => {
            beforeEach(async () => {
                await token1.connect(coinCreatorSigner).transfer(chest.address, 1000);
            });

            it('should let us store token1 at the address', async () => {
                const balance = await token1.balanceOf(chest.address);
                assert.strictEqual(balance.toString(), '1000');
            });

            describe('after plundering', () => {
                beforeEach(async () => {
                    await chest.connect(hunterSigner).plunder([token1.address]);
                });

                it('should award the hunter the balance', async () => {
                    const hunterBalance = await token1.balanceOf(hunter);
                    assert.strictEqual(hunterBalance.toString(), '1000');
                });

                it('should remove the balance from the chest', async () => {
                    const balance = await token1.balanceOf(chest.address);
                    assert.strictEqual(balance.toString(), '0');
                });
            });
        });

        describe('storing some token1 and token2', () => {
            beforeEach(async () => {
                await token1.connect(coinCreatorSigner).transfer(chest.address, 250);
                await token2.connect(coinCreatorSigner).transfer(chest.address, 300);
            });

            it('should let us store token1 at the address', async () => {
                const balance = await token1.balanceOf(chest.address);
                assert.strictEqual(balance.toString(), '250');
            });

            it('should let us store token2 at the address', async () => {
                const balance = await token2.balanceOf(chest.address);
                assert.strictEqual(balance.toString(), '300');
            });

            describe('after pludering token2', () => {
                beforeEach(async () => {
                    await chest.connect(hunterSigner).plunder([token2.address]);
                });

                it('should not award the hunter the token1', async () => {
                    const hunterBalance = await token1.balanceOf(hunter);
                    assert.strictEqual(hunterBalance.toString(), '0');
                });

                it('should award the hunter the token2', async () => {
                    const hunterBalance = await token2.balanceOf(hunter);
                    assert.strictEqual(hunterBalance.toString(), '300');
                });

                it('should not remove the token1 from the chest', async () => {
                    const balance = await token1.balanceOf(chest.address);
                    assert.strictEqual(balance.toString(), '250');
                });

                it('should remove the token2 from the chest', async () => {
                    const balance = await token2.balanceOf(chest.address);
                    assert.strictEqual(balance.toString(), '0');
                });
            });

            describe('upon plundering both', () => {
                beforeEach(async () => {
                    await chest.connect(hunterSigner).plunder([token1.address, token2.address]);
                });

                it('should award the hunter the token1', async () => {
                    const hunterBalance = await token1.balanceOf(hunter);
                    assert.strictEqual(hunterBalance.toString(), '250');
                });

                it('should award the hunter the token2', async () => {
                    const hunterBalance = await token2.balanceOf(hunter);
                    assert.strictEqual(hunterBalance.toString(), '300');
                });

                it('should remove the token1 from the chest', async () => {
                    const balance = await token1.balanceOf(chest.address);
                    assert.strictEqual(balance.toString(), '0');
                });

                it('should remove the token2 from the chest', async () => {
                    const balance = await token2.balanceOf(chest.address);
                    assert.strictEqual(balance.toString(), '0');
                });
            });
        });
    });
});

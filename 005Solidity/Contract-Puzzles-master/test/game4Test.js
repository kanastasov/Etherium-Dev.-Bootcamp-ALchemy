const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { assert } = require('chai');

describe('Game4', function () {
  async function deployContractAndSetVariables() {
    const Game = await ethers.getContractFactory('Game4');
    const game = await Game.deploy();

    return { game };
  }
  it('should be a winner', async function () {
    const { game } = await loadFixture(deployContractAndSetVariables);

    game.nested[ethers.provider.getSigner(0).getAddress()][ethers.provider.getSigner(1).getAddress()] = true;
    // nested mappings are rough :}

    await game.win(ethers.provider.getSigner(0).getAddress());

    // leave this assertion as-is
    assert(await game.isWon(), 'You did not win the game');
  });
});

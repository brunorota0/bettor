const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Bettor", () => {
  let bettor;

  beforeEach(async () => {
    const Bettor = await ethers.getContractFactory("Bettor");
    bettor = await Bettor.deploy();
    await bettor.deployed();
  });

  it("Should create a game once per address", async () => {
    // First start game
    await expect(bettor.startGame()).to.emit(bettor, "CreateGame");

    const res = await bettor.getGamesLength();
    expect(res).to.equal("1");

    // Second start game
    await bettor.startGame();
    const res2 = await bettor.getGamesLength();
    expect(res2).to.equal("1");
  });

  it("Should return level 0 when is the first time or the game is finished", async () => {
    const game = await bettor.getGame();
    expect(game.level.toString()).to.equal("0");
  });

  it("Should return level 1 after start the game", async () => {
    // First start game
    await bettor.startGame();
    const game = await bettor.getGame();
    expect(game.level.toString()).to.equal("1");
  });

  it("Should return random number between 1-10", async () => {
    // First start game
    await bettor.startGame();
    const game = await bettor.getGame();

    expect(game.number.toNumber()).greaterThan(0).lessThanOrEqual(10);
  });

  it("Should block bet if the game is finished", async () => {
    try {
      await bettor.bet(0);
    } catch (err) {
      const errorMessage = err.toString();
      expect(errorMessage.includes("Your game is not currently active.")).to.equal(true);
    }
  });

  it("Should emit Bet event after make a bet", async () => {
    await bettor.startGame();

    await expect(bettor.bet(0)).to.emit(bettor, "Bet");
  });

  it("Should create a Reward after stand an available game.", async () => {
    await bettor.startGame();

    await expect(bettor.bet(0)).to.emit(bettor, "Bet");

    const game = await bettor.getGame();
    if (!game.finished) {
      await expect(bettor.stand()).to.emit(bettor, "CreateReward");
      const rewards = await bettor.getRewards();
      expect(rewards).lengthOf(1);
    } else {
      const rewards = await bettor.getRewards();
      expect(rewards).lengthOf(0);
    }
  });
});

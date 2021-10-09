const { expect } = require("chai");
const { ethers } = require("hardhat");
const sinon = require("sinon");

describe("Bettor", function () {
  it("Should create a game once per address", async function () {
    const Bettor = await ethers.getContractFactory("Bettor");
    const bettor = await Bettor.deploy();
    await bettor.deployed();

    // First start game
    await expect(bettor.startGame()).to.emit(bettor, "CreateGame");

    const res = await bettor.getGamesLength();
    expect(res).to.equal("1");

    // Second start game
    await bettor.startGame();
    const res2 = await bettor.getGamesLength();
    expect(res2).to.equal("1");
  });

  it("Should return level 0 when is the first time or the game is finished", async function () {
    const Bettor = await ethers.getContractFactory("Bettor");
    const bettor = await Bettor.deploy();
    await bettor.deployed();

    const game = await bettor.getGame();
    expect(game.level.toString()).to.equal("0");
  });

  it("Should return level 1 after start the game", async function () {
    const Bettor = await ethers.getContractFactory("Bettor");
    const bettor = await Bettor.deploy();
    await bettor.deployed();

    // First start game
    await bettor.startGame();
    const game = await bettor.getGame();
    expect(game.level.toString()).to.equal("1");
  });

  it("Should return random number between 1-10", async function () {
    const Bettor = await ethers.getContractFactory("Bettor");
    const bettor = await Bettor.deploy();
    await bettor.deployed();

    // First start game
    await bettor.startGame();
    const game = await bettor.getGame();

    expect(game.number.toNumber()).greaterThan(0).lessThanOrEqual(10);
  });

  it("Should block bet if the game is finished", async function () {
    const Bettor = await ethers.getContractFactory("Bettor");
    const bettor = await Bettor.deploy();
    await bettor.deployed();

    try {
      await bettor.bet(0);
    } catch (err) {
      const errorMessage = err.toString();
      expect(errorMessage.includes("You should start the game before make a bet.")).to.equal(true);
    }
  });

  it("Should emit Bet event after make a bet", async function () {
    const Bettor = await ethers.getContractFactory("Bettor");
    const bettor = await Bettor.deploy();
    await bettor.deployed();

    await bettor.startGame();

    await expect(bettor.bet(0)).to.emit(bettor, "Bet");
  });
});

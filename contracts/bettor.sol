//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Bettor {
    event Bet(bool result, uint256 number);
    event CreateGame(Game game);
    event CreateReward(Reward reward);

    struct Game {
        uint8 level;
        bool finished;
        uint256 number;
    }

    struct Reward {
        bytes32 name;
        uint256 rarity;
    }

    enum BetType {
        LOWER,
        EQUAL,
        HIGHER
    }

    Game[] public games;
    Reward[] public rewards;

    mapping(uint256 => address) public gameToOwner;
    mapping(uint256 => address) public rewardToOwner;

    uint256 nonce = 0;

    constructor() {}

    function startGame() external {
        (bool exists, uint256 index) = getGameFromOwner(msg.sender);

        if (exists) {
            Game memory game = games[index];
            if (game.finished) {
                game.level = 1;
                game.finished = false;
            }
        } else {
            _createGame();
        }
    }

    function bet(BetType _betType) external {
        Game memory game = getGame();

        require(
            game.level != 0 && game.finished == false,
            "You should start the game before make a bet."
        );

        uint256 randomNumber = generateRandomNumber();

        bool betResult;
        if (_betType == BetType.LOWER) {
            betResult = randomNumber < game.number;
        } else if (_betType == BetType.EQUAL) {
            betResult = randomNumber == game.number;
        } else if (_betType == BetType.HIGHER) {
            betResult = randomNumber > game.number;
        }

        // console.log("BET: %s to %s = %s", randomNumber, game.number, betResult);

        (, uint256 index) = getGameFromOwner(msg.sender);

        if (betResult) {
            _createReward(game.level);

            games[index].level++;
            games[index].number = randomNumber;
        } else {
            games[index].finished = true;
        }

        emit Bet(betResult, randomNumber);
    }

    function getGamesLength() external view returns (uint256) {
        return games.length;
    }

    function _createGame() internal {
        uint256 randomNumber = generateRandomNumber();
        Game memory newGame = Game(1, false, randomNumber);
        games.push(newGame);
        gameToOwner[games.length - 1] = msg.sender;

        emit CreateGame(newGame);
    }

    function _createReward() internal {
        Reward memory reward = Reward();
    }

    function getGame() public view returns (Game memory) {
        (bool exists, uint256 index) = getGameFromOwner(msg.sender);

        if (exists) {
            return games[index];
        }
    }

    function getGameFromOwner(address _owner)
        internal
        view
        returns (bool, uint256)
    {
        bool exists = false;
        uint256 index = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (gameToOwner[i] == _owner) {
                index = i;
                exists = true;
            }
        }
        return (exists, index);
    }

    function generateRandomNumber() internal returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % 10;
        randomnumber = randomnumber + 1;
        nonce++;
        return randomnumber;
    }
}

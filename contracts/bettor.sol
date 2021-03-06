//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Bettor {
    event Bet(bool result, uint256 number, Game game);
    event CreateGame(Game game);
    event CreateReward(Reward reward);
    event GameFinished(bool gameFinished);
    event ResetGame(Game game);

    struct Game {
        uint8 level;
        bool finished;
        uint256 number;
    }

    struct Reward {
        uint256 id;
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
        (bool exists, uint256 index) = _getGameFromOwner(msg.sender);

        if (exists) {
            _resetGame(index);
        } else {
            _createGame();
        }
    }

    function bet(BetType _betType) external isGameActive {
        uint256 randomNumber = generateRandomNumber();
        Game memory game = getGame();

        bool betResult;
        if (_betType == BetType.LOWER) {
            betResult = randomNumber < game.number;
        } else if (_betType == BetType.EQUAL) {
            betResult = randomNumber == game.number;
        } else if (_betType == BetType.HIGHER) {
            betResult = randomNumber > game.number;
        }

        (, uint256 index) = _getGameFromOwner(msg.sender);

        if (betResult) {
            games[index].level++;
            games[index].number = randomNumber;
        } else {
            games[index].finished = true;
        }

        emit Bet(betResult, randomNumber, games[index]);
    }

    function getGamesLength() external view returns (uint256) {
        return games.length;
    }

    function stand() external isGameActive {
        (, uint256 index) = _getGameFromOwner(msg.sender);
        games[index].finished = true;
        _createReward(games[index].level);

        emit GameFinished(true);
    }

    function getGame() public view returns (Game memory) {
        (bool exists, uint256 index) = _getGameFromOwner(msg.sender);

        if (exists) {
            return games[index];
        }
    }

    function getGames() public view returns (Game[] memory) {
        return games;
    }

    function getRewards() external view returns (Reward[] memory) {
        return rewards;
    }

    function _resetGame(uint256 index) internal {
        if (games[index].finished) {
            uint256 randomNumber = generateRandomNumber();

            games[index].number = randomNumber;
            games[index].level = 1;
            games[index].finished = false;
        }

        emit ResetGame(games[index]);
    }

    function _createGame() internal {
        uint256 randomNumber = generateRandomNumber();
        Game memory newGame = Game(1, false, randomNumber);
        games.push(newGame);
        gameToOwner[games.length - 1] = msg.sender;

        emit CreateGame(newGame);
    }

    function _createReward(uint256 _level) internal {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        );
        Reward memory newReward = Reward(randomNumber, _level);
        rewards.push(newReward);
        rewardToOwner[rewards.length - 1] = msg.sender;
        nonce++;
        emit CreateReward(newReward);
    }

    function _getGameFromOwner(address _owner)
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

    modifier isGameActive() {
        Game memory game = getGame();
        require(
            game.level > 0 && game.finished == false,
            "Your game is not currently active."
        );

        _;
    }
}

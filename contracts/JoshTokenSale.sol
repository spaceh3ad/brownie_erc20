// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JoshToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract JoshTokenSale is VRFConsumerBase, Ownable {
    address payable[] public investors;
    address payable public recentWinner;

    uint256 public constant MAX = 25000000000000000000;
    uint256 public nRoundTime;
    uint8 public phase;

    IERC20 private _joshToken;

    AggregatorV3Interface internal ethUsdPriceFeed;

    enum SALE_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    SALE_STATE public sale_state;

    uint256 public tokenPrice;
    uint256 public randomness;
    uint256 public fee;

    uint256[5] bonusForLuckyOne = [
        1000000000000000000,
        2000000000000000000,
        3000000000000000000,
        4000000000000000000,
        5000000000000000000
    ];

    bytes32 public keyhash;

    event RequestedRandomness(bytes32 requestId);
    event BuyTokens(uint256 _numberOfTokens);

    constructor(
        IERC20 joshToken,
        uint256 _RoundTime,
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        _joshToken = joshToken;
        nRoundTime = _RoundTime;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        sale_state = SALE_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function getSaleAllowance() public view returns (uint256) {
        return _joshToken.allowance(owner(), address(this));
    }

    function startSale(
        uint256 _tokensAllocation,
        uint256 _tokenPrice,
        uint256 _RoundTime
    ) public onlyOwner {
        require(sale_state == SALE_STATE.CLOSED);
        require(
            getSaleAllowance() == _tokensAllocation,
            "Sale contract doesn't have enough tokens!"
        );
        tokenPrice = _tokenPrice;
        nRoundTime = _RoundTime;
        sale_state = SALE_STATE.OPEN;
        phase += 1;
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price);
        return adjustedPrice;
    }

    function endSale() public onlyOwner {
        require(sale_state == SALE_STATE.OPEN);
        sale_state = SALE_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function buyTokens() public payable {
        require(sale_state == SALE_STATE.OPEN, "Sale not active");
        require(block.timestamp < nRoundTime, "Phase ended");
        require(msg.value <= MAX, "Maximum amount of purchase is 25BNB");
        uint256 _ethPrice = getEthPrice();
        uint256 _tokenAmount = (msg.value * _ethPrice) / tokenPrice / 10**8;

        require(
            getSaleAllowance() >= _tokenAmount,
            "Not enough tokens for this phase!"
        );

        _joshToken.transferFrom(owner(), msg.sender, _tokenAmount);
        emit BuyTokens(_tokenAmount);
        investors.push(payable(msg.sender));
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            sale_state == SALE_STATE.CALCULATING_WINNER,
            "You arn't there yet"
        );

        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % investors.length;
        recentWinner = investors[indexOfWinner];
        recentWinner.transfer(bonusForLuckyOne[phase]);
        investors = new address payable[](0);
        sale_state = SALE_STATE.CLOSED;
        randomness = _randomness;

        payable(owner()).transfer(address(this).balance);
    }
}

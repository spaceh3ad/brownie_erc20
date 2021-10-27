// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JoshToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract JoshTokenSale is VRFConsumerBase, Ownable {
    address public admin;
    address payable[] public investors;
    address payable public recentWinner;

    mapping(address => uint256) public balanceOf;

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
    uint256 public constant MAX = 25000000000000000000;

    bytes32 public keyhash;

    event RequestedRandomness(bytes32 requestId);
    event BuyTokens(uint256 _numberOfTokens);

    constructor(
        IERC20 joshToken,
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        admin = msg.sender;
        _joshToken = joshToken;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        sale_state = SALE_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function getSaleAllowance() public view returns (uint256) {
        return _joshToken.allowance(admin, address(this));
    }

    function startSale(uint256 _tokensAllocation, uint256 _tokenPrice)
        public
        onlyOwner
    {
        require(sale_state == SALE_STATE.CLOSE);
        require(
            getSaleAllowance() == _tokensAllocation,
            "Sale contract doesn't have enough tokens!"
        );
        tokenPrice = _tokenPrice;
        sale_state = SALE_STATE.OPEN;
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price); //18 decimals
        return adjustedPrice;
    }

    function endSale() public onlyOwner {
        require(sale_state == SALE_STATE.OPEN);
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);

        payable(admin).transfer(address(this).balance);
    }

    function buyTokens() public payable {
        require(sale_state == SALE_STATE.OPEN, "Sale not active");
        require(msg.value <= MAX, "Maximum amount of purchase is 25BNB");
        uint256 _ethPrice = getEthPrice();
        uint256 _tokenAmount = (msg.value * _ethPrice) / tokenPrice / 10**23;

        require(
            getSaleAllowance() >= _tokenAmount,
            "Not enough tokens for this phase!"
        );

        balanceOf[msg.sender] += _tokenAmount;
        _joshToken.transferFrom(admin, msg.sender, _tokenAmount);
        emit BuyTokens(_tokenAmount);
        investors.push(msg.sender);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You arn't there yet"
        );

        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % investors.length;
        recentWinner = investors[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        investors = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}

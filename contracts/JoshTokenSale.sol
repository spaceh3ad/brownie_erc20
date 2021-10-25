// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JoshToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract JoshTokenSale is Ownable {
    address public admin;
    address payable[] public investors;
    mapping(address => uint256) public balances;
    IERC20 private _joshToken;
    uint256 public tokenPrice;
    AggregatorV3Interface internal ethUsdPriceFeed;

    enum SALE_STATE {
        OPEN,
        CLOSED,
        SENDING_TOKENS
    }

    SALE_STATE public sale_state;

    event BuyTokens(uint256 _numberOfTokens);

    constructor(IERC20 joshToken, address _priceFeedAddress) {
        admin = msg.sender;
        _joshToken = joshToken;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        _joshToken.allowance(msg.sender, address(this));
    }

    function startSale(uint256 _tokenAllocation, uint256 _tokenPrice)
        public
        onlyOwner
    {
        _joshToken.approve(address(this), _tokenAllocation);
        tokenPrice = _tokenPrice;
        sale_state = SALE_STATE.OPEN;
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price); //18 decimals
        return adjustedPrice;
    }

    function endSale() public onlyOwner {
        for (uint256 i = 0; i < investors.length; i++) {
            address payable addr = investors[i];
            uint256 tokens = balances[addr];
            _joshToken.transferFrom(admin, address(this), tokens);
        }
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(sale_state == SALE_STATE.OPEN, "Sale not active");
        balances[msg.sender] += _numberOfTokens;
        emit BuyTokens(_numberOfTokens);
    }
}

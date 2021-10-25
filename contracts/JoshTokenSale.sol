// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JoshToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract JoshTokenSale is Ownable {
    address public admin;
    address payable[] public investors;
    mapping(address => uint256) public balanceOf;
    IERC20 private _joshToken;
    uint256 public tokenPrice;
    AggregatorV3Interface internal ethUsdPriceFeed;

    enum SALE_STATE {
        OPEN,
        CLOSE,
        SENDING_TOKENS
    }

    SALE_STATE public sale_state;

    event BuyTokens(uint256 _numberOfTokens);

    constructor(IERC20 joshToken, address _priceFeedAddress) {
        admin = msg.sender;
        _joshToken = joshToken;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        sale_state = SALE_STATE.CLOSE;
    }

    function getSaleAllowance() public view returns (uint256) {
        return _joshToken.allowance(admin, address(this));
    }

    function startSale(uint256 _tokenPrice) public onlyOwner {
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
            uint256 tokens = balanceOf[addr];
            _joshToken.transferFrom(admin, address(this), tokens);
        }
        sale_state = SALE_STATE.CLOSE;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(sale_state == SALE_STATE.OPEN, "Sale not active");
        balanceOf[msg.sender] += _numberOfTokens;
        emit BuyTokens(_numberOfTokens);
    }
}

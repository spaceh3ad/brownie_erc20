pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JoshToken is ERC20 {
    uint256 public immutable unfreezeTime;
    bool public bool_saleEnded = false;
    address public immutable owner;

    constructor(uint256 initialSupply, uint256 _unfreezeTime)
        ERC20("JoshToken", "JOSH")
    {
        unfreezeTime = _unfreezeTime;
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    modifier freezeTokens() {
        if (block.timestamp < unfreezeTime) {
            require(
                msg.sender == owner || bool_saleEnded == true,
                "Funds are frozen."
            );
        }
        _;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        freezeTokens
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address source,
        address dest,
        uint256 value
    ) public override freezeTokens returns (bool) {
        return super.transferFrom(source, dest, value);
    }
}

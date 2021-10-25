// contracts/JoshToken.sol
// SPDX-Licencse-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JoshToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("JoshToken", "JOSH") {
        _mint(msg.sender, initialSupply);
    }
}

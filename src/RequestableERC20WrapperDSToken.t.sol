pragma solidity ^0.4.24;

import "ds-test/test.sol";

import "./ERC20WrapperDSToken.sol";
import "ds-token/token.sol";

contract RequestableERC20WrapperDSTokenTest is DSTest {
    RequestableERC20WrapperDSToken wrapperToken;
    DSToken ERC20Token;

    function setUp() public {
        ERC20Token = new DSToken('TEST');
        wrapperToken = new RequestableERC20WrapperDSToken(false, 'WRAPPER', ERC20Token);
    }


}

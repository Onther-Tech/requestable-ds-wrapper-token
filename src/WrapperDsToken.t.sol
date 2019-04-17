pragma solidity ^0.4.24;

import "ds-test/test.sol";

import "./WrapperDsToken.sol";

contract WrapperDsTokenTest is DSTest {
    WrapperDsToken token;

    function setUp() public {
        token = new WrapperDsToken();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}

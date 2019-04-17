pragma solidity ^0.4.24;

import "ds-token/token.sol";
import "./RequestableI.sol";

/**
 * @title   RequestableERC20Wrapper
 * @notice  RequestableERC20Wrapper is a requestable token contract that can exchange
 *          another base ERC20 token.
 */
contract RequestableERC20WrapperDSToken is DSToken, RequestableI {

  bool public initialized;
  bool public development;
  address public rootchain;
  ERC20 public token;

  /* Events */
  event Depositted(address _from, uint _value);
  event Withdrawn(address _from, uint _value);
  event RequestCreated(bool _isExit, address _requestor, bytes32 _trieKey, uint _value);

  modifier isInitialized() {
    require(initialized);
    _;
  }

  constructor(bool _development, bytes32 symbol_, ERC20 _token) DSToken(symbol_) public {
    development = _development;
    token = _token;
  }

  function init(address _rootchain) external returns (bool) {
    require(!initialized);

    rootchain = _rootchain;
    initialized = true;
  }

  function deposit(uint _amount) external isInitialized returns (bool) {
    mint(msg.sender, _amount);
    emit Depositted(msg.sender, _amount);
    require(token.transferFrom(msg.sender, this, _amount));

    return true;
  }

  function withdraw(uint _amount) external isInitialized returns (bool) {
    burn(msg.sender, _amount);
    emit Withdrawn(msg.sender, _amount);
    require(token.transfer(msg.sender, _amount));

    return true;
  }

  function getBalanceTrieKey(address _who) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(bytes32(0), _who));
  }

  function applyRequestInRootChain(
    bool isExit,
    uint256 requestId,
    address requestor,
    bytes32 trieKey,
    bytes trieValue
  ) external isInitialized returns (bool success) {
    require(msg.sender == address(rootchain));
    require(trieKey == getBalanceTrieKey(requestor));

    uint v = decodeTrieValue(trieValue);

    if (isExit) {
      mint(requestor, v);
    } else {
      burn(requestor, v);
    }

    emit RequestCreated(isExit, requestor, trieKey, v);

    return true;
  }

  function applyRequestInChildChain(
    bool isExit,
    uint256 requestId,
    address requestor,
    bytes32 trieKey,
    bytes trieValue
  ) external returns (bool success) {
    require(development || msg.sender == address(0));
    require(trieKey == getBalanceTrieKey(requestor));

    uint v = decodeTrieValue(trieValue);

    if (isExit) {
      burn(requestor, v);
    } else {
      mint(requestor, v);
    }

    emit RequestCreated(isExit, requestor, trieKey, v);

    return true;
  }

  function decodeTrieValue(bytes memory trieValue) public pure returns (uint v) {
    require(trieValue.length == 0x20);

    assembly {
       v := mload(add(trieValue, 0x20))
    }
  }
}

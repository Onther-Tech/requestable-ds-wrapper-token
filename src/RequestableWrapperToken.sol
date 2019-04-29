pragma solidity ^0.4.24;

import "ds-token/token.sol";
import "./RequestableI.sol";

/**
 * @title   RequestableERC20Wrapper
 * @notice  RequestableERC20Wrapper is a requestable token contract that can exchange
 *          another base ERC20 token.
 */
contract RequestableWrapperToken is DSToken, RequestableWrapperI {

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
    return keccak256(abi.encodePacked(bytes32(4), _who));
  }

  function applyRequestInRootChain(
    bool isExit,
    uint256 requestId,
    address requestor,
    bytes32 trieKey,
    bytes trieValue
  ) external isInitialized returns (bool success) {
    require(msg.sender == address(rootchain));
    /* require(trieKey == getBalanceTrieKey(requestor)); */

    uint v = decodeTrieValue(trieValue);

    if (trieKey == bytes32(1)) {
        _handleOwner(true, isExit, requestor, trieKey, v);
    } else if (trieKey == bytes32(2)) {
        _handleStopped(true, isExit, requestor, trieKey, v);
    } else if (trieKey == getBalanceTrieKey(requestor)) {
        _handleBalance(true, isExit, requestor, trieKey, v);
    } else {
        revert();
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
    /* require(trieKey == getBalanceTrieKey(requestor)); */

    uint v = decodeTrieValue(trieValue);

    if (trieKey == bytes32(1)) {
        _handleOwner(false, isExit, requestor, trieKey, v);
    } else if (trieKey == bytes32(2)) {
        _handleStopped(false, isExit, requestor, trieKey, v);
    } else if (trieKey == getBalanceTrieKey(requestor)) {
        _handleBalance(false, isExit, requestor, trieKey, v);
    } else {
        revert();
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

  function _handleOwner(
      bool isRootChain,
      bool isExit,
      address requestor,
      bytes32 trieKey,
      uint v
  ) internal {
      address newOwner = address(v);

      if (isRootChain) {
          if (isExit) {
              owner = newOwner;
          } else {
              require(owner == requestor);
              require(owner == newOwner);
          }
      } else {
          if (isExit) {
              require(owner == requestor);
              require(owner == newOwner);
          } else {
              owner = newOwner;
          }
      }
  }

  function _handleStopped(
      bool isRootChain,
      bool isExit,
      address requestor,
      bytes32 trieKey,
      uint v
  ) internal {
      bool newStopped = v == 0x1;

      if (isRootChain) {
          if (isExit) {
              stopped = newStopped;
          } else {
              require(isAuthorized(requestor, bytes4(keccak256("stop()"))));
          }
      } else {
          if (isExit) {
              require(isAuthorized(requestor, bytes4(keccak256("stop()"))));
          } else {
              stopped = newStopped;
          }
      }
  }

  function _handleBalance(
      bool isRootChain,
      bool isExit,
      address requestor,
      bytes32 trieKey,
      uint amount
  ) internal {
      /* uint amount = uint(trieValue); */

      if (isRootChain) {
          if (isExit) {
              _balances[requestor] = add(_balances[requestor], amount);
          } else {
              require(amount <= _balances[requestor]);
              _balances[requestor] = sub(_balances[requestor], amount);
            }
      } else {
          if (isExit) {
              require(amount <= _balances[requestor]);
              _balances[requestor] = sub(_balances[requestor], amount);
          } else {
              _balances[requestor] = add(_balances[requestor], amount);
          }
      }
  }


}

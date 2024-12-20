// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ICardFactory {
    struct TransportationCard {
        uint32 validUntil;
        bool isApproved;
    }

    function createCard() external;
    function getSenderCard() external view returns (TransportationCard memory);
    function approveCard(string memory url) external;
    function checkIfCanProlongValidity(bytes32 cardId) external view returns (bool);
    function prolongValidity(bytes32 _cardId, uint16 _weeks) external;
    function isCardApproved(bytes32 _cardId) external view returns(bool);
    function getValidUntil(bytes32 _cardId) external view returns(uint);
}

contract CardControl is Ownable {

    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    event ControlledCardNoSubscription(bytes32 _id, uint _timestamp);
    event ControlledCardNoApproval(bytes32 _id, uint _timestamp);
    event NewController(address _address, uint _timestamp);
    event RevokedController(address _address, uint _timestamp);

    ICardFactory private cardFactory;

    // if address is associated with a controller it will be true
    // can be further implemented by creating a Controller struct,
    // but for this purpose just having info if it is or not is enough
    mapping (address => bool) private isController;

    constructor( address _cardFactory) Ownable(msg.sender) {
        cardFactory = ICardFactory(_cardFactory);
    }

    modifier onlyController() { 
        require(isController[msg.sender], "Function is reserved only for controllers.");
        _;
    }

    function addNewController(address _newController) external onlyOwner {
        isController[_newController] = true;
        emit NewController(_newController, block.timestamp);
    }

    function revokeController(address _newController) external onlyOwner {
        isController[_newController] = false;
        emit RevokedController(_newController, block.timestamp);
    }

    function controlCard(bytes32 _cardId) external onlyController {
        if (cardFactory.isCardApproved(_cardId) == false){
            emit ControlledCardNoApproval(_cardId, block.timestamp); 
        }
    
        if (block.timestamp > cardFactory.getValidUntil(_cardId)){
            emit ControlledCardNoSubscription(_cardId, block.timestamp); 
        }
    }
}
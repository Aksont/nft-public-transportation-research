// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CardFactory is Ownable {

    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    event NewCard(bytes32 _id, uint _timestamp);
    event ValidityProlonged(bytes32 _id, uint _timestamp, uint16 _weeks, uint _newValidUntil);
    event CardApproved(bytes32 _id, uint _timestamp);

    struct TransportationCard {
        // should identity even be verifiable? probably yes - with picture included
        // therefore, there should be a way to hash (hide) this informations or to zero-knowledge them
        string fullName; // concern with storing full name, because otherwise user's private wallet address would be exposed
        // string pictureUrl;
        uint validUntil;
        bool isApproved;
    } 

    // id can be used as a QR to show when control arrives
    // as well as fast checking if the user has a card already attached to their address
    mapping (address => bytes32) private ownerToCardId;

    // card is attached to id, instead of the address, for the purpose of increased user privacy
    // can be discussed if it should be private or public
    mapping (bytes32 => TransportationCard) private cardIdToCard;

    // used to make sure that validity prolongation can come only from SubscriptionOffer contract,
    // because validity of payment is conducted there
    address private subscriptionContractAddress;

    // a function for changing this value should exist,
    // but for proof-of-concept is okay
    uint minDaysBeforeNewSubProlongation = 30;
    
    constructor() Ownable(msg.sender) {}

    modifier onlySubscriptionContract() { 
        require(msg.sender == subscriptionContractAddress, "Function is callable only by SubscriptionOffer contract.");
        _;
    }

    function setSubscriptionContractAddress(address _address) external onlyOwner {
        subscriptionContractAddress = _address;
    }

    function approveCard(bytes32 _cardId) external onlyOwner {
        TransportationCard storage card = cardIdToCard[_cardId];
        card.isApproved = true;
        emit CardApproved(_cardId, block.timestamp);
    }

    function createCard(string memory _fullName) external {
        require(ownerToCardId[msg.sender] == 0);
        bytes32 id = bytes32(_generateUUID());
        ownerToCardId[msg.sender] = id;
        cardIdToCard[id] = TransportationCard(_fullName, 0, false);
        emit NewCard(id, block.timestamp);
    }

    function _generateUUID() private view returns (bytes32) {
        bytes32 randomHash = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender));
        
        return randomHash;
    }

    function getSenderCard() public view returns (TransportationCard memory) {
        require(ownerToCardId[msg.sender] != 0);
        bytes32 id = ownerToCardId[msg.sender];
        
        return cardIdToCard[id];
    }

    function getSenderCardId() public view returns (bytes32) {
        require(ownerToCardId[msg.sender] != 0);
        bytes32 id = ownerToCardId[msg.sender];
        
        return id;
    }

    function checkIfCanProlongValidity(bytes32 _cardId) external view returns (bool) {
        _verifyCardApproval(_cardId);
        TransportationCard memory card = cardIdToCard[_cardId];
        int canProlongSince = int(card.validUntil) - int(minDaysBeforeNewSubProlongation) * 1 days;

        return int(block.timestamp) > canProlongSince;
    }

    function prolongValidity(bytes32 _cardId, uint16 _weeks) external onlySubscriptionContract {
        _verifyCardApproval(_cardId);
        this.checkIfCanProlongValidity(_cardId);
        TransportationCard storage card = cardIdToCard[_cardId];

        if (block.timestamp > card.validUntil){
            card.validUntil = block.timestamp + _weeks * 1 weeks;
        } else {
            card.validUntil = card.validUntil + _weeks * 1 weeks;
        }

        emit ValidityProlonged(_cardId, block.timestamp, _weeks, card.validUntil);
    }

    function _verifyCardApproval(bytes32 _cardId) internal view {
        require(this.isCardApproved(_cardId) == true, "Card is not yet approved or it does not exist."); // checks if it is approved, but also if it even exists (because default value for bool data type is false
    }

    function isCardApproved(bytes32 _cardId) external view returns(bool) {
        return cardIdToCard[_cardId].isApproved;
    }

    function getValidUntil(bytes32 _cardId) external view returns(uint) {
        return cardIdToCard[_cardId].validUntil;
    }
}
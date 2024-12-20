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

contract SubscriptionOfferFactory is Ownable {

    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    event NewSubscriptionOffer(uint _offerId, string _name, uint _numberOfWeeks, uint _fee, uint _timestamp);
    event RemovedSubscriptionOffer(uint _offerId, string _name, uint _numberOfWeeks, uint _fee, uint _timestamp);
    event SubscriptionFeeUpdated(uint _offerId, uint newFee, uint _timestamp);

    // provides transparency into public system's earnings
    // all the data is publicly available
    event NewSubscriptionPayment(uint _timestamp, uint _offerId, uint fee);

    struct SubscriptionOffer {
        string name;
        uint16 numberOfWeeks;
        uint fee;
    }

    ICardFactory private cardFactory;

    // generates the id of the offer, and tracks its activity status
    // instance and information about the SubscriptionOffer are available in offers mapping
    bool[] public offersActivity; 

    // contains SubscriptionOffer instances in mapping because mapping consumes less gas 
    // (you can remove unused instances without need to reorder everything like is the case with arrays)
    mapping (uint16 => SubscriptionOffer) offers;
    

    constructor( address _cardFactory) Ownable(msg.sender) {
        cardFactory = ICardFactory(_cardFactory);
    }

    function addSubscriptionOffer(string memory _name, uint16 _numberOfWeeks, uint _fee) public onlyOwner {
        _validateAddSubscriptionOffer(_name, _numberOfWeeks, _fee);
        uint16 id = uint16(offersActivity.length);
        offersActivity.push(true);
        offers[id] = SubscriptionOffer(_name, _numberOfWeeks, _fee);
        emit NewSubscriptionOffer(id, _name, _numberOfWeeks, _fee, block.timestamp);
    }

    function _validateAddSubscriptionOffer(string memory _name, uint16 _numberOfWeeks, uint _fee) internal pure {
        require(bytes(_name).length > 0, "Subscription offer name can not be empty.");
        require(_numberOfWeeks > 0, "Subscription offer duration must be greater than 0.");
        require(_fee >= 0, "Subscription offer fee must be greater or equal to 0.");
    }

    function updateSubscriptionFee(uint16 _id, uint _fee) public onlyOwner {
        require(_fee >= 0, "Subscription offer fee must be greater or equal to 0."); // possibly to be 0, for some special offers maybe, let's not constrain it too much
        _checkOfferActivity(_id);
        offers[_id].fee = _fee;
        emit SubscriptionFeeUpdated(_id, _fee, block.timestamp);
        emit RemovedSubscriptionOffer(_id, offers[_id].name, offers[_id].numberOfWeeks, offers[_id].fee, block.timestamp);
    }

    function removeSubscriptionOffer(uint16 _id) public onlyOwner {
        _checkOfferActivity(_id);
        offersActivity[_id] = false;
        emit RemovedSubscriptionOffer(_id, offers[_id].name, offers[_id].numberOfWeeks, offers[_id].fee, block.timestamp);
        delete offers[_id]; // can truly delete, because the historical information is preserved in events
    }

    function _countActiveOffers() private view returns(uint16){
        uint16 id;
        uint16 numOfActiveOffers = 0;
         bool isOfferActive;

        for (id = 0; id < offersActivity.length; id++){
            isOfferActive = offersActivity[id];

            if (isOfferActive){
                numOfActiveOffers = uint16(numOfActiveOffers.add(1));
            }
        }

        return numOfActiveOffers;
    }

    function getNumOfActiveOffers() external view returns(uint16){
        return _countActiveOffers();
    }

    function getSubscriptionOffers() external view returns(SubscriptionOffer[] memory){
        bool isOfferActive;
        SubscriptionOffer[] memory activeOffers = new SubscriptionOffer[](_countActiveOffers());
        uint16 counter = 0;

        for (uint16 id = 0; id < offersActivity.length; id++){
            isOfferActive = offersActivity[id];

            if (isOfferActive){
                activeOffers[counter] = offers[id];
                counter = uint16(counter.add(1));
            }
        }

        return activeOffers;
    }

    function getSubscriptionOffer(uint16 _offerId) external view returns(SubscriptionOffer memory){
        _checkOfferActivity(_offerId);
        return offers[_offerId];
    }

    function paySubscription(uint16 _offerId, bytes32 _cardId) external payable{
        _checkOfferActivity(_offerId);
        require(cardFactory.checkIfCanProlongValidity(_cardId), "The subscription can not yet be prolonged.");
        
        SubscriptionOffer memory offer = offers[_offerId];
        require(msg.value == offer.fee || msg.value > offer.fee, "Not enough fee has been transfered.");

        cardFactory.prolongValidity(_cardId, offer.numberOfWeeks);
        emit NewSubscriptionPayment(block.timestamp, _offerId, offer.fee);
    }

    function _checkOfferActivity(uint16 _offerId) private view {
        require(offersActivity[_offerId] == true, "The requested offer does not exist.");
    }

    // function for collecting the earned ETH stored in the smart contract
    function withdraw() external onlyOwner {
        address _owner = owner();
        (bool success, ) = _owner.call{value: address(this).balance}("Transfering profit.");
        require(success, "Transfer failed");
    }
}
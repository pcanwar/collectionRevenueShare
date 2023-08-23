// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CollectionRevenueShare.sol";

contract FactoryRevenueShare is Ownable  {

    address private immutable nftImp;
    address [] private nftCollection;
    mapping (address => bool) isMintedCollection;

    event NewCollectionLog(address indexed contracts, address indexed creator, address indexed admain, 
    string  [3] nsbURI_,
    uint256 [2] maxSypplyMintPerAddress, uint256 [4] privatePublicPriceWei, address[] payees, uint256[] shares);

    // SaleLogFactory event if there is sale either private or public sales
    event SaleLogFactory(address indexed collection, address minter, uint256 numOfTokens, uint256 cost);
    // CryptoLogFactory  event is called in the addToken function when 
    // the admain adds erc20 address and the price 
    event CryptoLogFactory(address indexed collection, bool isSupported, address paymentAddress, uint256 price);
    // ActiveLogLogFactory event is for activing or disactiving the sale active
    event ActiveLogLogFactory(address indexed collection, bool isActive);

    // MintLogFactory event  is to mint a new token id
    event MintLogFactory(address indexed collection, address account, uint256 tokenId);
    // StartCollectionLogFactory event is called in setPublicTimeSale function 
    // and retruns if the owner changes the timestamp of the public sale timestamp and max mint per address
    // also this will activate the sale of the collection was deactivated
    event StartCollectionLogFactory(address indexed collection,address admain, uint256 time, uint256 maxMinPerAddress, bool saleIsActive);
    // CurrencySaleLog event is simialr to SaleLogFactory event but here it is for erc20 
    event CurrencySaleLog(address indexed collection,address account, uint256 numTokens, address paymentContract, uint256 cost);
  // WithdrawLog event is called in the withdraw function for withdraing fees
    event WithdrawLog(address indexed contracts, address indexed account, uint amount);

    modifier onlyCollection() {
        require(isMintedCollection[msg.sender], "Caller is not minted collection");
        _;
    }

    constructor() {
        nftImp = address(new CollectionRevenueShare());
    }


    /*
    * @notice: this function runs for creating a collection
    * @param  nsbURI_ string is an array of 3 elements name and symbol of the collection and baseURL
    * @param  _admain address is the owner of the collection 
    * @param  maxCollMintAddr_ uint256 is an array of 2 elements max sypply of the collection and how many a wallet address can mint
    * @param  privPriceStart_pubPriceStart_ uint256 is an arry of 4 elements the private price in Wei and private start time stamp
    * and public pricd in Wei and the public start time stamp
    * @param payees address is array of the addresses revenue share add 
    * @param shares uint256 is an array of the revenue assigned the number of shares 
    */

    function createCollection(string [3] calldata nsbURI_, address _admain,
    uint256 [2] calldata maxCollMintAddr_, uint256 [4] calldata privPriceStart_pubPriceStart_,
    address[] calldata payees, uint256[] calldata shares) external   {
        require( maxCollMintAddr_[0] > 0, "It must be nonzero");
        address payable clone = payable(Clones.clone(nftImp));
        CollectionRevenueShare(clone).initialize(
            nsbURI_, _admain, address(this),
            maxCollMintAddr_,privPriceStart_pubPriceStart_, payees, shares);

        nftCollection.push(clone);

        isMintedCollection[clone] = true;

        emit NewCollectionLog(clone, msg.sender,_admain,
            nsbURI_, maxCollMintAddr_, privPriceStart_pubPriceStart_, payees, shares);
    }


    /*
    * @notice: this function returns all nft collection address
    */
    function getAllCollection() view external returns(address [] memory list){
        list = nftCollection;
    }

    // notifications of the events in collection contract
    function notifySaleLog(address minter, uint256 tokenID, uint256 cost) external onlyCollection() {
        emit SaleLogFactory(msg.sender, minter, tokenID, cost);
    }

    function notifyCryptoLog(bool isSupported, address paymentContract, uint256 price) external onlyCollection() {
        emit CryptoLogFactory(msg.sender, isSupported, paymentContract, price);
    }
    
    function notifyActiveLog(bool isActive) external onlyCollection() {
        emit ActiveLogLogFactory(msg.sender, isActive);
    }


    function notifyMintLog(address admain, uint256 tokenId) external onlyCollection() {
        emit MintLogFactory(msg.sender, admain, tokenId);
    }


    function notifyStartCollectionLog(address admain, uint256 time, uint256 maxMinPerAddress, bool saleIsActive) external onlyCollection() {
        emit StartCollectionLogFactory(msg.sender, admain, time, maxMinPerAddress, saleIsActive);
    }

    function notifyCurrencySaleLog(address account, uint256 numTokens, address paymentContract, uint256 cost) external onlyCollection() {
        emit CurrencySaleLog(msg.sender, account, numTokens, paymentContract, cost);
    }

    /*
    * @notice: to get collection by Id returns collection address
    */
    function getCollection(uint256 _id) view external returns(address ){
        address _cool = nftCollection[_id];
        return _cool;
    }

    /*
    * @notice: read the balance of this contract
    */
    function balance() external view returns(uint256 _balance) {
        _balance = address(this).balance;
    }

    /*
    * @notice: only the admin can withdraw.
    */
    function withdraw() external onlyOwner {
        uint256 contract_balance = address(this).balance;
        require(contract_balance > 0, "No funds available for withdrawal");

        payable(msg.sender).transfer(contract_balance);
    }


}
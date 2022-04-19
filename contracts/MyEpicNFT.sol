// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import {Base64} from "./libraries/Base64.sol";

contract MyEpicNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // maximum number of token
    uint256 public constant MAX_TOKEN = 1000;
    uint256 public constant MAX_PER_MINT = 5;

    uint256 _mintPrice = 0.001 ether;

    bool _isPresale = false;

    mapping(address => bool) public _whiteList;
    mapping (address => uint256) addressToNumberOfTokensMinted;

    address payable private _owner;
    uint256 public totalSupply = 1000;

    // We split the SVG at the part where it asks for the background color.
    string svgPartOne =
        "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='";
    string svgPartTwo =
        "'/><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    string[] firstWords = [
        "FOREVER ",
        "ALWAYS ",
        "CONSTANTLY ",
        "PERPETUALLY ",
        "INCESSANTLY ",
        "ENDLESSLY "
    ];
    string[] secondWords = [
        "DIAMOND ",
        "PAPER ",
        "GEM ",
        "PEARL ",
        "JEWEL ",
        "CUPBOARD ",
        "GLASS ",
        "PLASTIC ",
        "DIAMOND "
    ];
    string[] thirdWords = ["HANDS", "LEG", "MOUTH", "EYES", "FEET", "NOSE"];

    // Get fancy with it! Declare a bunch of colors.
    string[] colors = ["red", "#08C2A8", "black", "yellow", "blue", "green"];

    event NewEpicNFTMinted(address sender, uint256 tokenId);

    constructor() ERC721("SquareNFT", "SQUARE") {
        console.log("This is my NFT contract. Woah!");
    }

    function pickRandomFirstWord(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint256 rand = random(
            string(abi.encodePacked("FIRST_WORD", Strings.toString(tokenId)))
        );
        rand = rand % firstWords.length;
        return firstWords[rand];
    }

    function pickRandomSecondWord(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint256 rand = random(
            string(abi.encodePacked("SECOND_WORD", Strings.toString(tokenId)))
        );
        rand = rand % secondWords.length;
        return secondWords[rand];
    }

    function pickRandomThirdWord(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint256 rand = random(
            string(abi.encodePacked("THIRD_WORD", Strings.toString(tokenId)))
        );
        rand = rand % thirdWords.length;
        return thirdWords[rand];
    }

    // Same old stuff, pick a random color.
    function pickRandomColor(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint256 rand = random(
            string(abi.encodePacked("COLOR", Strings.toString(tokenId)))
        );
        rand = rand % colors.length;
        return colors[rand];
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    

    //Make NFT!
    //Validate!
    function makeAnEpicNFT(uint256 amount) public payable{
        //uint256 newItemId = _tokenIds.current();
        require(amount > 0 && amount <= MAX_PER_MINT, "Only 1-5 allowed");
        //require((newItemId + amount) > MAX_TOKEN, "Max number minted.");

        require(
            msg.value >= _mintPrice * amount,
            "Please call with enough money."
        );

        if (_isPresale) {
            require(
                _whiteList[msg.sender] == true,
                "Only whitelist can mint in presale"
            );
        }

        addressToNumberOfTokensMinted[msg.sender] += amount;
        require(addressToNumberOfTokensMinted[msg.sender] < MAX_PER_MINT, "No more mints for this wallet");

        for (uint256 i = 0; i < amount; i++) {
            _mintNFT(msg.sender);
        }
    }

     function _mintNFT(address to) private {
        uint256 newItemId = _tokenIds.current();
        string memory first = pickRandomFirstWord(newItemId);
        string memory second = pickRandomSecondWord(newItemId);
        string memory third = pickRandomThirdWord(newItemId);
        string memory combinedWord = string(
            abi.encodePacked(first, second, third)
        );

        // Add the random color in.
        string memory randomColor = pickRandomColor(newItemId);
        string memory finalSvg = string(
            abi.encodePacked(
                svgPartOne,
                randomColor,
                svgPartTwo,
                combinedWord,
                "</text></svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        combinedWord,
                        '", "description": "A highly acclaimed collection of squares.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log("\n--------------------");
        console.log(finalTokenUri);
        console.log("--------------------\n");

        _tokenIds.increment();
        _safeMint(to, newItemId);

        _setTokenURI(newItemId, finalTokenUri);

        totalSupply++;
        
        console.log(
            "An NFT w/ ID %s has been minted to %s",
            newItemId,
            to
        );
        emit NewEpicNFTMinted(to, newItemId);
    }

    function getTotalNFTsMintedSoFar() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getMintPrice() public view returns (uint256){
        return _mintPrice;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        _mintPrice = _newMintPrice;
    }

    function setWhiteList(address[] calldata addresses) external onlyOwner {
        uint256 count = addresses.length;
        for (uint256 i = 0; i < count; i++) {
            _whiteList[addresses[i]] = true;
        }
    }

    function iamInWhitelist() public view returns (bool) {
        return _whiteList[msg.sender] == true;
    }

    function getTotalSupply() public pure returns (uint256) {
        return MAX_TOKEN;
    }

    function isPresale() public view returns (bool) {
        return _isPresale;
    }

    function setIsPresale(bool _newIsPresale) public onlyOwner {
        _isPresale = _newIsPresale;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}

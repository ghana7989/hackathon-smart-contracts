// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CFP {
    struct Creator {
        address creator;
        string name;
        string photoUrl;
        string email;
        string website;
        string socialMedia;
        uint256 raisedAmount;
    }
    struct User {
        address user;
        string name;
        bool isCreator;
        uint256 totalDonatedAmount;
    }
    struct Donation {
        address from;
        address to;
        uint256 amount;
    }
    // owner of the contract
    address public owner;
    // list of all the creators
    mapping(address => Creator) creators;
    // list of all the users
    mapping(address => User) users;

    // map of creator to the array of user addresses who donated
    mapping(address => mapping(address => uint256))
        public creatorToUsersToAmountDonated;
    mapping(address => address[]) public creatorToUsersDonated;

    // map of user to the array of creator addresses who they donated to
    mapping(address => mapping(address => uint256))
        public userToCreatorsToAmountDonated;
    mapping(address => address[]) public userToCreatorsDonated;

    mapping(address => bool) public creatorExists;
    mapping(address => bool) public userExists;
    mapping(address => bool) public userAndCreatorExists;

    // Creator balance
    mapping(address => uint256) creatorBalance;

    //-----------------------
    // EXTRA
    // Create a counter for campaigns ids
    uint256 private _campaignIdCounter;
    struct Campaign {
        uint256 id;
        string name;
        address createdBy;
        string description;
        uint256 targetMoney;
        uint256 raisedMoney;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }
    mapping(uint256 => Campaign) campaigns;
    mapping(address => Campaign[3]) creatorToCampaignsArray;

    mapping(address => uint256[]) public userToCampaignsDonated;

    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _targetMoney,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        require(creatorExists[msg.sender], "Bro! You are not a creator!");
        // creators can have only 3 active campaigns at a time
        require(
            creatorToCampaignsArray[msg.sender].length < 3,
            "You can have only 3 active campaigns at a time!"
        );
        Campaign memory newCampaign;
        newCampaign.id = _campaignIdCounter;
        newCampaign.name = _name;
        newCampaign.createdBy = msg.sender;
        newCampaign.description = _description;
        newCampaign.targetMoney = _targetMoney;
        newCampaign.raisedMoney = 0;
        newCampaign.startTime = _startTime;
        newCampaign.endTime = _endTime;
        newCampaign.isActive = true;
        campaigns[_campaignIdCounter] = newCampaign;
        creatorToCampaignsArray[msg.sender][_campaignIdCounter] = newCampaign;
        _campaignIdCounter++;
    }

    function deleteCampaign(uint256 _campaignId) public {
        require(creatorExists[msg.sender], "Bro! You are not a creator!");
        require(
            campaigns[_campaignId].createdBy == msg.sender,
            "You can only delete your campaigns!"
        );

        delete creatorToCampaignsArray[msg.sender][_campaignId];
    }

    function changeCampaignStatus(uint256 _campaignId, bool _isActive) public {
        require(creatorExists[msg.sender], "Bro! You are not a creator!");
        require(
            campaigns[_campaignId].createdBy == msg.sender,
            "You can only delete your campaigns!"
        );
        creatorToCampaignsArray[msg.sender][_campaignId].isActive = _isActive;
    }

    function getCampaignsOf(address _of)
        public
        view
        returns (Campaign[3] memory)
    {
        require(creatorExists[_of], "Bro! You are not a creator!");
        return creatorToCampaignsArray[_of];
    }

    function getCreator(uint256 _campaignId) public view returns (address) {
        require(creatorExists[msg.sender], "Bro! You are not a creator!");
        return campaigns[_campaignId].createdBy;
    }

    function donateToCampaigns(uint256 _campaignId) public payable {
        address creatorAddress = getCreator(_campaignId);

        require(userExists[msg.sender], "Bro! You are not a user!");
        require(campaigns[_campaignId].isActive, "Campaign is not active!");
        require(
            campaigns[_campaignId].targetMoney >
                campaigns[_campaignId].raisedMoney,
            "Campaign is already full!"
        );
        require(
            campaigns[_campaignId].startTime < block.timestamp,
            "Campaign has not started yet!"
        );
        require(
            campaigns[_campaignId].endTime > block.timestamp,
            "Campaign has ended!"
        );
        require(
            campaigns[_campaignId].targetMoney > msg.value,
            "You cannot donate more than the target amount!"
        );
        require(
            creatorToCampaignsArray[creatorAddress][_campaignId].isActive,
            "You cannot donate to a campaign that is not active!"
        );
        require(
            creatorToCampaignsArray[creatorAddress][_campaignId].targetMoney >
                creatorToCampaignsArray[creatorAddress][_campaignId]
                    .raisedMoney ||
                creatorToCampaignsArray[creatorAddress][_campaignId]
                    .targetMoney >
                msg.value,
            "You cannot donate more than the target amount!"
        );
        require(
            creatorToCampaignsArray[creatorAddress][_campaignId].startTime <
                block.timestamp,
            "You cannot donate to a campaign that has not started yet!"
        );
        require(
            creatorToCampaignsArray[creatorAddress][_campaignId].endTime >
                block.timestamp,
            "You cannot donate to a campaign that has ended!"
        );
        donate(payable(creatorAddress));
        creatorToCampaignsArray[creatorAddress][_campaignId].raisedMoney += msg
            .value;
        creatorToCampaignsArray[creatorAddress][_campaignId].targetMoney -= msg
            .value;
        creatorBalance[creatorAddress] -= msg.value;
        userToCampaignsDonated[msg.sender].push(_campaignId);
        // userToCreatorsDonated[msg.sender].push(creatorAddress);
        // userToCreatorsToAmountDonated[msg.sender][creatorAddress] = (msg.value);
    }

    //----------------------
    event CreatorCreated(
        address indexed creator,
        string indexed name,
        string photoUrl,
        string email,
        string website,
        string socialMedia,
        uint256 indexed raisedAmount
    );

    event UserCreated(
        address indexed user,
        string indexed name,
        bool isCreator,
        uint256 indexed totalDonatedAmount
    );

    event DonationCreated(
        address indexed from,
        address indexed to,
        uint256 indexed amount,
        uint256 timestamp
    );

    constructor() {
        owner = msg.sender;
    }

    // MODIFIERS

    // FUNCTIONS

    function createCreator(
        string memory name,
        string memory photoUrl,
        string memory email,
        string memory website,
        string memory socialMedia
    ) public {
        creators[msg.sender] = Creator({
            creator: msg.sender,
            name: name,
            photoUrl: photoUrl,
            email: email,
            website: website,
            socialMedia: socialMedia,
            raisedAmount: 0
        });
        creatorExists[msg.sender] = true;
        emit CreatorCreated(
            msg.sender,
            name,
            photoUrl,
            email,
            website,
            socialMedia,
            0
        );
    }

    // create the user
    function createUser(string memory name) public {
        require(
            users[msg.sender].user == address(0),
            "Bro why do you want two accounts, YOU already have an account"
        );
        User memory temp;
        temp.user = msg.sender;
        temp.name = name;
        temp.isCreator = false;
        temp.totalDonatedAmount = 0;
        userExists[msg.sender] = true;
        users[msg.sender] = temp;
        emit UserCreated(msg.sender, name, false, 0);
    }

    // donate to the creator
    function donate(address payable creator) public payable {
        require(msg.value > 0, "Amount must be greater than 0");
        users[msg.sender].totalDonatedAmount += msg.value;
        creators[creator].raisedAmount += msg.value;
        creatorToUsersToAmountDonated[creator][msg.sender] += msg.value;
        creatorToUsersDonated[creator].push(msg.sender);
        userToCreatorsToAmountDonated[msg.sender][creator] += msg.value;
        userToCreatorsDonated[msg.sender].push(creator);
        creator.transfer(msg.value);
        emit DonationCreated(msg.sender, creator, msg.value, block.timestamp);
    }

    // get the details of the creator
    function getCreatorDetails(address creator)
        public
        view
        returns (
            string memory name,
            string memory photoUrl,
            string memory email,
            string memory website,
            string memory socialMedia,
            uint256 raisedAmount
        )
    {
        return (
            creators[creator].name,
            creators[creator].photoUrl,
            creators[creator].email,
            creators[creator].website,
            creators[creator].socialMedia,
            creators[creator].raisedAmount
        );
    }

    function getUserDetails(address user)
        public
        view
        returns (
            string memory name,
            bool isCreator,
            uint256 totalDonatedAmount
        )
    {
        return (
            users[user].name,
            users[user].isCreator,
            users[user].totalDonatedAmount
        );
    }

    // get the donation details of the creator
    // When given the creator address, it returns the list of users who donated to the creator and another array with respective amounts
    function getCreatorDonationDetails()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 size = creatorToUsersDonated[msg.sender].length;
        address[] memory usersDonated = new address[](size);
        uint256[] memory amountsDonated = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            usersDonated[i] = creatorToUsersDonated[msg.sender][i];
            amountsDonated[i] = creatorToUsersToAmountDonated[msg.sender][
                creatorToUsersDonated[msg.sender][i]
            ];
        }
        return (usersDonated, amountsDonated);
    }

    function getUserDonationDetails(address _user)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        require(_user != address(0), "User address is invalid");

        uint256 size = userToCreatorsDonated[_user].length;
        address[] memory creatorsDonated = new address[](size);
        uint256[] memory amountsDonated = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            creatorsDonated[i] = userToCreatorsDonated[_user][i];
            amountsDonated[i] = userToCreatorsToAmountDonated[_user][
                userToCreatorsDonated[_user][i]
            ];
        }
        return (creatorsDonated, amountsDonated);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
Create a donation application where users can donate cryptocurrency to their favourite content creators(test cryptocurrency is fine) .
Create separate login and dashboard pages for content creators to update their information like photo, email id, website link and social media ids.
Users of content creators should have the ability to login to the portal and browse among existing content creators according to their choice.
Users should be able to send cryptocurrency(Neo/Ether/BTC,etc.) to the content creator after choosing one from existing content creators.
User Analytics and Creator Analytics should be included in a separate page. Logged in User can see only his personal analytics(ie. How much he has donated to which creator)
Creator Analytics should only be visible to creators which will include details regarding donation received from individual users
If an entity is both a creator and a user, then he shall be able to see both creator analytics and user analytics. 
 */

contract CFP {
    struct User {
        string name;
        address user;
        bool isCreator;
    }
    struct Creator {
        address creator;
        string name;
        string email;
        string website;
        string socialMedia;
        string photo;
        string category;
    }
    struct Donation {
        address to;
        address from;
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => Donation[]) userAddressDonationsMap;
    mapping(address => mapping(address => uint256)) amountUserDonatedToCreatorMap;
    mapping(address => Creator[]) userAddressToCreators;

    mapping(address => Donation[]) creatorAddressDonationsMap;
    mapping(address => mapping(address => uint256)) amountCreatorGotFromUsersMap;
    mapping(address => User[]) creatorAddressToUsers;

    mapping(address => User) userAddressUserMap;
    mapping(address => bool) userExists;

    mapping(address => Creator) creatorAddressCreatorMap;
    address[] creatorAddresses;

    mapping(address => bool) creatorExists;

    // Balances
    mapping(address => uint256) creatorAddressBalanceMap;

    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getAllCreators() public view returns (Creator[] memory) {
        Creator[] memory creators = new Creator[](creatorAddresses.length);
        for (uint256 i = 0; i < creatorAddresses.length; i++) {
            creators[i] = creatorAddressCreatorMap[creatorAddresses[i]];
        }
        return creators;
    }

    function getCreatorsByCategory(string memory category)
        public
        view
        returns (Creator[] memory)
    {
        Creator[] memory creators = new Creator[](creatorAddresses.length);
        for (uint256 i = 0; i < creatorAddresses.length; i++) {
            if (
                compareStrings(
                    creatorAddressCreatorMap[creatorAddresses[i]].category,
                    category
                )
            ) {
                creators[i] = creatorAddressCreatorMap[creatorAddresses[i]];
            }
        }
        return creators;
    }

    function getCreatorDonors(address creatorAddress)
        public
        view
        returns (User[] memory)
    {
        User[] memory users = new User[](
            creatorAddressToUsers[creatorAddress].length
        );
        for (
            uint256 i = 0;
            i < creatorAddressToUsers[creatorAddress].length;
            i++
        ) {
            users[i] = creatorAddressToUsers[creatorAddress][i];
        }
        return users;
    }

    function getUserCreators(address userAddress)
        public
        view
        returns (Creator[] memory)
    {
        Creator[] memory creators = new Creator[](
            userAddressToCreators[userAddress].length
        );
        for (
            uint256 i = 0;
            i < userAddressToCreators[userAddress].length;
            i++
        ) {
            creators[i] = userAddressToCreators[userAddress][i];
        }
        return creators;
    }

    function createCreator(
        string memory _name,
        string memory _email,
        string memory _website,
        string memory _socialMedia,
        string memory _photo
    ) public returns (bool) {
        require(!creatorExists[msg.sender], "Creator already exists");

        Creator memory newCreator;
        newCreator.creator = msg.sender;
        newCreator.name = _name;
        newCreator.email = _email;
        newCreator.website = _website;
        newCreator.socialMedia = _socialMedia;
        newCreator.photo = _photo;
        creatorAddressCreatorMap[msg.sender] = newCreator;
        creatorExists[msg.sender] = true;
        creatorAddresses.push(msg.sender);

        if (userExists[msg.sender]) {
            userAddressUserMap[msg.sender].isCreator = true;
        } else {
            User memory newUser;
            newUser.name = _name;
            newUser.user = msg.sender;
            newUser.isCreator = true;
            userAddressUserMap[msg.sender] = newUser;
            userExists[msg.sender] = true;
        }
        return true;
    }

    function getUserDonations(address userAddress)
        public
        view
        returns (Donation[] memory)
    {
        Donation[] memory donations = new Donation[](
            userAddressDonationsMap[userAddress].length
        );
        for (
            uint256 i = 0;
            i < userAddressDonationsMap[userAddress].length;
            i++
        ) {
            donations[i] = userAddressDonationsMap[userAddress][i];
        }
        return donations;
    }

    function getCreatorDonations(address creatorAddress)
        public
        view
        returns (Donation[] memory)
    {
        Donation[] memory donations = new Donation[](
            creatorAddressDonationsMap[creatorAddress].length
        );

        for (
            uint256 i = 0;
            i < creatorAddressDonationsMap[creatorAddress].length;
            i++
        ) {
            donations[i] = creatorAddressDonationsMap[creatorAddress][i];
        }
        return donations;
    }

    function createUser(string memory _name) public returns (bool) {
        require(!userExists[msg.sender], "User already exists");

        User memory newUser;
        newUser.name = _name;
        newUser.user = msg.sender;
        newUser.isCreator = false;
        userAddressUserMap[msg.sender] = newUser;
        userExists[msg.sender] = true;
        return true;
    }

    function donate(address payable _to) public payable {
        require(msg.value > 0, "Amount must be greater than 0");

        // require(!userExists[msg.sender], "User must be created first");
        require(creatorExists[_to], "Creator must be created first");

        // First Transfer the amount
        _to.transfer(msg.value);
        creatorAddressBalanceMap[_to] += msg.value;
        // updating user has donated to creator
        amountUserDonatedToCreatorMap[msg.sender][_to] += msg.value;
        // updating creator has received from user
        amountCreatorGotFromUsersMap[_to][msg.sender] += msg.value;

        userAddressToCreators[msg.sender].push(creatorAddressCreatorMap[_to]);
        creatorAddressToUsers[_to].push(userAddressUserMap[msg.sender]);

        // updating user's donation history
        Donation memory newDonation;
        newDonation.to = _to;
        newDonation.from = msg.sender;
        newDonation.amount = msg.value;
        newDonation.timestamp = block.timestamp;

        userAddressDonationsMap[msg.sender].push(newDonation);
        creatorAddressDonationsMap[_to].push(newDonation);
    }
}

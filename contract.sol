// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BookSharing {
    struct Book {
        uint256 id;
        string name;
        string author;
        address owner;
    }

    mapping(uint256 => Book) private books;
    mapping(address => uint256) private userToBookCount;
    mapping(address => mapping(uint256 => bool)) private userBooks;
    uint256 private bookCount;

    event BookAdded(uint256 indexed id, string name, string author);
    event BookRemoved(uint256 indexed id);
    event TransferAccepted(uint256 indexed id, address recipient);

    function addBook(string memory _name, string memory _author) public {
        bookCount++;
        books[bookCount] = Book(bookCount, _name, _author, msg.sender);
        userToBookCount[msg.sender]++;
        userBooks[msg.sender][bookCount] = true;
        emit BookAdded(bookCount, _name, _author);
    }

    function removeBook(uint256 _id) public {
        require(_id <= bookCount, "Invalid book ID");
        require(userBooks[msg.sender][_id], "You can only remove your own books");
        delete books[_id];
        delete userBooks[msg.sender][_id];
        emit BookRemoved(_id);
    }

    function initiateTransfer(address _recipient, uint256 _bookId) public {
        require(userBooks[msg.sender][_bookId], "You can only transfer your own books");
        require(!userBooks[_recipient][_bookId], "Book already belongs to the recipient");

        userBooks[msg.sender][_bookId] = false;
        userBooks[_recipient][_bookId] = true;
    }

    function getBooksByUser() public view returns (Book[] memory) {
        uint256 userBookCount = userToBookCount[msg.sender];
        Book[] memory userBooksArr = new Book[](userBookCount);
        uint256 counter = 0;

        for (uint256 i = 1; i <= bookCount; i++) {
            if (userBooks[msg.sender][i]) {
                userBooksArr[counter] = books[i];
                counter++;
            }
        }

        return userBooksArr;
    }

    function getPartiallyTransferredBooks() public view returns (Book[] memory) {
        uint256 userBookCount = userToBookCount[msg.sender];
        Book[] memory partiallyTransferredBooks = new Book[](userBookCount);
        uint256 counter = 0;

        for (uint256 i = 1; i <= bookCount; i++) {
            if (userBooks[msg.sender][i] && !compareAddresses(msg.sender, books[i].owner)) {
                partiallyTransferredBooks[counter] = books[i];
                counter++;
            }
        }

        return partiallyTransferredBooks;
    }

    function acceptTransfer(uint256 _bookId) public {
        require(userBooks[msg.sender][_bookId], "You can only accept transfer for partially transferred books");

        books[_bookId].owner = msg.sender;
        emit TransferAccepted(_bookId, msg.sender);
    }

    function searchByName(string memory _name) public view returns (Book[] memory) {
        uint256[] memory results = new uint256[](bookCount);
        uint256 count = 0;

        for (uint256 i = 1; i <= bookCount; i++) {
            if (compareStrings(books[i].name, _name)) {
                results[count] = i;
                count++;
            }
        }

        return _getBooks(results, count);
    }

    function searchByAuthor(string memory _author) public view returns (Book[] memory) {
        uint256[] memory results = new uint256[](bookCount);
        uint256 count = 0;

        for (uint256 i = 1; i <= bookCount; i++) {
            if (compareStrings(books[i].author, _author)) {
                results[count] = i;
                count++;
            }
        }

        return _getBooks(results, count);
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function compareAddresses(address a, address b) private pure returns (bool) {
        return a == b;
    }

    function _getBooks(uint256[] memory ids, uint256 count) private view returns (Book[] memory) {
        Book[] memory result = new Book[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 id = ids[i];
            result[i] = books[id];
        }

        return result;
    }
}

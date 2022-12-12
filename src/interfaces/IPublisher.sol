// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IPublisher.sol
 * @notice Interface for Publisher contracts
 */
interface IPublisher {
    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Shared listing struct for both artifactRenderer address + artifactMetadata
    struct ArtifactDetails {
        address artifactRenderer;
        bytes artifactMetadata;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Emitted when an artifact is created
    event ArtifactCreated(
        address creator,
        address zoraDrop,
        address mintRecipient,
        uint256 tokenId,
        address tokenRenderer,
        bytes tokenMetadata
    );

    /// @notice Emitted when an artifact is edited
    event ArtifactEdited(address editor, address zoraDrop, uint256 tokenId, address tokenRenderer, bytes tokenMetadata);

    /// @notice Emitted when an artifact is initialized
    event ArtifactInitialized(address indexed target, address sender, uint256 indexed tokenId, string indexed tokenURI);

    /// @notice Emitted when an artifact is updated
    event ArtifactUpdated(address indexed target, address sender, uint256 indexed tokenId, string indexed tokenURI);

    /// @notice Emitted when the contractURI is updated
    event ContractURIUpdated(address indexed target, address sender, string indexed contractURI);

    /// @notice Emitted when the metadataRenderer is updated
    event MetadataRendererUpdated(address sender, address newRenderer);

    /// @notice Emitted when a mint occurs
    event Mint(
        address minter, address mintRecipient, uint256 tokenId, address artifactRegistry, bytes artifactMetadata
    );

    /// @notice Emitted when the mintPrice is updated
    event MintPriceUpdated(address sender, address target, uint256 newMintPrice);

    /// @notice Emitted when a new publication is initialized
    /// @dev admin function indexer feedback
    event PublicationInitialized(
        address indexed target,
        string indexed contractURI,
        uint256 mintPricePerToken,
        address indexed accessControl,
        bytes accessControlInit
    );

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Thrown if the artifactRenderer address is zero
    error Cannot_SetToZeroAddress();

    /// @notice Thrown if msg.value is incorrect
    error WrongPrice();

    /// @notice Thrown if minter contract has not recieved minting role
    error MinterNotAuthorized();

    /// @notice Thrown if funds transfer to target drops contract is unsuccessful
    error TransferNotSuccessful();

    /// @notice Thrown if caller is not an admin on target zora drop
    error Access_OnlyAdmin();

    /// @notice Thrown if artifact creation update fails
    error CreateArtifactFail();

    /// @notice Thrown if artifact edit update fails
    error EditArtifactFail();

    /// @notice Thrown if msg.sender does not have publication access
    error No_PublicationAccess();

    /// @notice Thrown if msg.sender does not have access to update the metadata for a token
    error No_EditAccess();

    /// @notice Thrown if contractURI returns empty. The contract has not been initialized
    ///      or is being called by an address other than the target zora drop
    error NotInitialized_Or_NotZoraDrop();

    /// @notice Thrown if value is set to empty
    error Cannot_SetBlank();

    /// @notice Thrown if specified token does not exist
    error Token_DoesntExist();

    /// @notice Thrown if target drops collection has not been initialized
    error Address_NotInitialized();

    /// @notice Thrown if supplied inputs are invalid
    error INVALID_INPUT_LENGTH();

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function publisherDirectory(address zoraDrop, uint256 tokenId)
        external
        view
        returns (string memory, string memory);

    function owner() external view returns (address);

    function MINTER_ROLE() external view returns (bytes32);

    function artifactInfo(address, uint256)
        external
        view
        returns (address artifactRenderer, bytes memory artifactMetadata);

    function contractURIInfo(address) external view returns (string memory);

    function dropAccessControl(address) external view returns (address);

    // ||||||||||||||||||||||||||||||||
    // ||| WRITE FUNCTIONS ||||||||||||
    // ||||||||||||||||||||||||||||||||

    function edit(address zoraDrop, uint256[] memory tokenIds, ArtifactDetails[] memory artifactDetails) external;

    function initializeWithData(bytes memory data) external;

    function mintPricePerToken(address) external view returns (uint256);

    function publish(address zoraDrop, address mintRecipient, ArtifactDetails[] memory artifactDetails)
        external
        payable;

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function updateContractURI(address target, string memory newContractURI) external;

    function updateMintPrice(address target, uint256 newMintPricePerToken) external;
}

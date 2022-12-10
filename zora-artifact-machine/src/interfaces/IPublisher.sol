// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IPublisher {

    /// @notice Shared listing struct for both access and storage ***CHANGE THIS  
    struct ArtifactDetails {
        address artifactRenderer;
        bytes artifactMetadata;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice CHANGE
    function initializeArtifact(ArtifactDetails artifactDetails) external returns (bool);   

    /// @notice CHANGE
    function updateArtifact(address, uint256, address, string memory) external returns (bool);

    /// @notice CHANGE
    function updateContractURI(address, string memory) external; 

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice create artifact notice
    event ArtifactCreated(
        address creator, 
        address zoraDrop, 
        address mintRecipient, 
        uint256 tokenId, 
        address tokenRenderer,
        bytes tokenMetadata
    ) ; 

    /// @notice edit artifact notice
    event ArtifactEdited(
        address editor, 
        address zoraDrop,
        uint256 tokenId, 
        address tokenRenderer, 
        bytes tokenMetadata
    );           
    
    /// @notice mint notice
    // event Mint(address minter, address mintRecipient, uint256 tokenId, string tokenURI);
    event Mint(address minter, address mintRecipient, uint256 tokenId, address artifactRegistry, bytes artifactMetadata);    
    
    /// @notice mintPrice edited notice
    event MintPriceEdited(address sender, address target, uint256 newMintPrice);

    /// @notice metadataRenderer updated notice
    event MetadataRendererUpdated(address sender, address newRenderer);     

    /// @notice Event for initialized Artifact
    event ArtifactInitialized(
        address indexed target,
        address sender,
        uint256 indexed tokenId,
        string indexed tokenURI
    );    

    /// @notice Event for updated Artifact
    event ArtifactUpdated(
        address indexed target,
        address sender,
        uint256 indexed tokenId,
        string indexed tokenURI
    );

    /// @notice Event for updated contractURI
    event ContractURIUpdated(
        address indexed target,
        address sender,
        string indexed contractURI
    );    

    /// @notice Event for a new collection initialized
    /// @dev admin function indexer feedback
    event CollectionInitialized(
        address indexed target,
        string indexed contractURI,
        uint256 mintPricePerToken,
        address indexed accessControl,
        bytes accessControlInit
    );         

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    error Cannot_SetToZeroAddress();

    /// @notice Action is unable to complete because msg.value is incorrect
    error WrongPrice();

    /// @notice Action is unable to complete because minter contract has not recieved minting role
    error MinterNotAuthorized();

    /// @notice Funds transfer not successful to drops contract
    error TransferNotSuccessful();

    /// @notice Caller is not an admin on target zora drop
    error Access_OnlyAdmin();

    /// @notice Artifact creation update failed
    error CreateArtifactFail();      

    /// @notice CHANGEEEEEEEE
    error No_MetadataAccess();

    /// @notice CHANGEEEEEEEE
    error No_PublicationAccess();    

    /// @notice CHANGEEEEEEEE
    error No_EditAccess();      

    /// @notice CHANGEEEEEEEE    
    error Cannot_SetBlank();

    /// @notice CHANGEEEEEEEE    
    error Token_DoesntExist();

    /// @notice CHANGEEEEEEEE    
    error Address_NotInitialized();

    /// @notice CHANGEEEEEEEE  
    error INVALID_INPUT_LENGTH();
}

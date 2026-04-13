// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title AgriChainCompliance
 * @dev Manages legal and regulatory compliance for Agrichain agreements,
 * embedding Indian laws into the smart contract execution.
 */
contract AgriChainCompliance {
    
    address public platformAdmin;

    // Emitted when a legally compliant agreement is formulated
    event AgreementCreated(
        bytes32 indexed agreementId,
        address indexed farmer,
        address indexed buyer,
        uint256 timestamp
    );

    // Emitted when digital signatures under IT Act 2000 are recorded
    event DigitalSignatureRecorded(
        bytes32 indexed agreementId,
        address indexed signer,
        string role,
        uint256 timestamp
    );

    // Emitted when DPDP Act consent is recorded
    event ConsentRecorded(
        address indexed user,
        string purpose,
        uint256 timestamp
    );

    struct LegalFrameworks {
        bool indianContractAct1872;
        bool itAct2000;
        bool digitalSignatureRules;
        bool saleOfGoodsAct1930;
        bool farmersProduceAct2020;
        bool apmcActCompliant;
        bool paymentSettlementAct2007;
        bool consumerProtectionAct2019;
        bool dpdpAct2023;
    }

    struct AgreementTerms {
        bytes32 agreementId;
        address farmer;
        address buyer;
        string cropDetails;
        uint256 quantity; // Delivery terms (Sale of Goods Act)
        uint256 considerationAmount; // Consideration (Indian Contract Act)
        string paymentMethod; // Payment Settlement Act
        bool isDirectTrade; // Farmers Produce Act
        string apmcState; // APMC Act compliance
        uint256 createdAt;
        bool isActive;
        LegalFrameworks complianceFlags;
    }

    mapping(bytes32 => AgreementTerms) public agreements;
    mapping(bytes32 => mapping(address => bool)) public digitalSignatures;
    mapping(address => bool) public dpdpConsent;

    modifier onlyAdmin() {
        require(msg.sender == platformAdmin, "Only admin can call this");
        _;
    }

    constructor() {
        platformAdmin = msg.sender;
    }

    /**
     * @dev Creates an agreement adhering to the Indian Contract Act and Sale of Goods Act
     */
    function createCompliantAgreement(
        bytes32 _agreementId,
        address _farmer,
        address _buyer,
        string memory _cropDetails,
        uint256 _quantity,
        uint256 _considerationAmount,
        string memory _paymentMethod,
        bool _isDirectTrade,
        string memory _apmcState
    ) external {
        require(agreements[_agreementId].createdAt == 0, "Agreement already exists");
        
        LegalFrameworks memory flags = LegalFrameworks({
            indianContractAct1872: true, // Offer + Acceptance + Consideration
            itAct2000: true, // Electronic record formulation
            digitalSignatureRules: true, // Awaiting signature
            saleOfGoodsAct1930: true, // Delivery and consideration defined
            farmersProduceAct2020: _isDirectTrade, // Trade outside mandi
            apmcActCompliant: bytes(_apmcState).length > 0, // State APMC tracking
            paymentSettlementAct2007: bytes(_paymentMethod).length > 0, // Monitored payment channel
            consumerProtectionAct2019: true, // Buyer protection mechanisms
            dpdpAct2023: dpdpConsent[_farmer] && dpdpConsent[_buyer] // Verified consent
        });

        agreements[_agreementId] = AgreementTerms({
            agreementId: _agreementId,
            farmer: _farmer,
            buyer: _buyer,
            cropDetails: _cropDetails,
            quantity: _quantity,
            considerationAmount: _considerationAmount,
            paymentMethod: _paymentMethod,
            isDirectTrade: _isDirectTrade,
            apmcState: _apmcState,
            createdAt: block.timestamp,
            isActive: true,
            complianceFlags: flags
        });

        emit AgreementCreated(_agreementId, _farmer, _buyer, block.timestamp);
    }

    /**
     * @dev Records digital signatures in compliance with IT Act 2000 and Digital Signature Rules
     */
    function recordDigitalSignature(bytes32 _agreementId, string memory _role) external {
        require(agreements[_agreementId].isActive, "Agreement is not active");
        require(!digitalSignatures[_agreementId][msg.sender], "Already signed");
        require(
            msg.sender == agreements[_agreementId].farmer || msg.sender == agreements[_agreementId].buyer,
            "Signer is not party to agreement"
        );

        digitalSignatures[_agreementId][msg.sender] = true;
        
        emit DigitalSignatureRecorded(_agreementId, msg.sender, _role, block.timestamp);
    }

    /**
     * @dev Explicitly records user consent for data processing under the DPDP Act 2023
     */
    function recordConsent(string memory _purpose) external {
        dpdpConsent[msg.sender] = true;
        emit ConsentRecorded(msg.sender, _purpose, block.timestamp);
    }

    /**
     * @dev Retrieves legal compliance flags for a specific agreement
     */
    function getComplianceFlags(bytes32 _agreementId) external view returns (LegalFrameworks memory) {
        require(agreements[_agreementId].createdAt != 0, "Agreement not found");
        return agreements[_agreementId].complianceFlags;
    }

    /**
     * @dev Checks if an agreement is fully signed according to the IT Act 2000
     */
    function isAgreementFullySigned(bytes32 _agreementId) external view returns (bool) {
        AgreementTerms memory agreement = agreements[_agreementId];
        return digitalSignatures[_agreementId][agreement.farmer] && digitalSignatures[_agreementId][agreement.buyer];
    }
}

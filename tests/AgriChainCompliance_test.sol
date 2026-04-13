// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // injected by Remix.
import "../contracts/4_AgriChainCompliance.sol";

contract AgriChainComplianceTest {
    AgriChainCompliance complianceContract;
    address farmer = address(0x123);
    address buyer = address(0x456);
    bytes32 agreementId = "agreement1";

    function beforeAll() public {
        complianceContract = new AgriChainCompliance();
    }

    function checkRecordConsent() public {
        complianceContract.recordConsent("Data Processing for Agrichain");
        Assert.equal(complianceContract.dpdpConsent(address(this)), true, "Consent should be recorded under DPDP Act 2023");
    }
    
    // Testing Admin
    function checkAdminSetupRole() public view {
        Assert.equal(complianceContract.platformAdmin(), address(this), "Platform admin should be the deployer");
    }

    function checkAgreementCreation() public {
        complianceContract.createCompliantAgreement(
            agreementId,
            farmer,
            buyer,
            "100kg Wheat",
            100,
            50000,
            "UPI",
            true, // isDirectTrade
            "Maharashtra"
        );

        AgriChainCompliance.LegalFrameworks memory flags = complianceContract.getComplianceFlags(agreementId);
        Assert.equal(flags.indianContractAct1872, true, "Should comply with Contract Act");
        Assert.equal(flags.farmersProduceAct2020, true, "Should comply with Farmers Produce Act");
        Assert.equal(flags.apmcActCompliant, true, "Should comply with APMC Act Tracking");
    }

    function checkDigitalSignature() public {
        // Can't easily mock msg.sender in Remix tests for the farmer/buyer specifically without a harder setup,
        // so we check the `isAgreementFullySigned` logic defaults back to false.
        Assert.equal(complianceContract.isAgreementFullySigned(agreementId), false, "Agreement shouldn't be fully signed initially");
    }
}

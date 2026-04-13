// import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../models/firestore_models.dart';

class ContractPdfService {
  static const String _companyName = 'AgriChain Marketplace';
  static const String _companyAddress =
      'Blockchain Agriculture Platform\nDecentralized Marketplace';
  static const String _companyEmail = 'contracts@agrichain.com';
  static const String _companyPhone = '+91-XXXX-XXXXXX';

  static Future<Uint8List?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Image fetch timeout');
        },
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error fetching image: $e');
    }
    return null;
  }

  /// Generate a professional agricultural purchase contract PDF
  static Future<Uint8List> generatePurchaseContract({
    required String contractId,
    required String farmerName,
    required String buyerName,
    required String cropName,
    required double quantity,
    required double price,
    required String deliveryDate,
    String? deliveryLocation,
    String? paymentTerms,
    String? farmerSignatureUrl,
    String? buyerSignatureUrl,
    Map<String, dynamic>? extra,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('dd MMMM yyyy \'at\' HH:mm');

    // Fetch signatures
    final farmerSignature = await _fetchImage(farmerSignatureUrl);
    final buyerSignature = await _fetchImage(buyerSignatureUrl);

    // Professional fonts
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final italicFont = await PdfGoogleFonts.openSansItalic();

    final now = DateTime.now();

    // Note: Logo removed to avoid asset loading errors
    // Company branding is now text-based

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 40),
        header: (context) => _buildContractHeader(regularFont, boldFont),
        footer: (context) =>
            _buildContractFooter(contractId, regularFont, boldFont, context),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'AGRICULTURAL PURCHASE AGREEMENT',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: 300,
                    height: 2,
                    color: PdfColors.green700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Parties Section
            _buildSectionTitle('1. PARTIES', boldFont),
            _buildPartiesSection(farmerName, buyerName, regularFont, boldFont),
            pw.SizedBox(height: 25),

            // Agreement Details Section
            _buildSectionTitle('2. AGREEMENT DETAILS', boldFont),
            _buildPurchaseDetailsSection(
              contractId,
              dateFormat.format(now),
              cropName,
              quantity,
              price,
              deliveryDate,
              deliveryLocation,
              paymentTerms,
              regularFont,
              boldFont,
            ),
            pw.SizedBox(height: 25),

            // Terms and Conditions
            _buildSectionTitle('3. TERMS AND CONDITIONS', boldFont),
            _buildPurchaseTermsAndConditions(regularFont, boldFont, italicFont),
            pw.SizedBox(height: 30),

            // Legal Framework & Compliance (Indian Laws)
            _buildSectionTitle('4. LEGAL FRAMEWORK & COMPLIANCE', boldFont),
            _buildIndianLegalComplianceSection(regularFont, boldFont, italicFont),
            pw.SizedBox(height: 30),

            // Signatures
            _buildSectionTitle('5. SIGNATURES', boldFont),
            _buildPurchaseSignatureSection(
              farmerName,
              buyerName,
              farmerSignature,
              buyerSignature,
              regularFont,
              boldFont,
              timeFormat,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Header for the purchase contract
  static pw.Widget _buildContractHeader(pw.Font regularFont, pw.Font boldFont) {
    return _buildLoanAgreementHeader(
      regularFont,
      boldFont,
    ); // Reusing the same header style
  }

  // Footer for the purchase contract
  static pw.Widget _buildContractFooter(
    String contractId,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Context context,
  ) {
    return _buildLoanAgreementFooter(
      contractId,
      regularFont,
      boldFont,
      context,
    ); // Reusing the same footer style
  }

  // Purchase details section
  static pw.Widget _buildPurchaseDetailsSection(
    String contractId,
    String agreementDate,
    String cropName,
    double quantity,
    double price,
    String deliveryDate,
    String? deliveryLocation,
    String? paymentTerms,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final totalValue = quantity * price;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(160),
        1: const pw.FlexColumnWidth(),
      },
      children: [
        _buildDetailRow('Contract ID', contractId, boldFont, regularFont),
        _buildDetailRow('Agreement Date', agreementDate, boldFont, regularFont),
        _buildDetailRow('Crop Name', cropName, boldFont, regularFont),
        _buildDetailRow(
          'Quantity',
          '${quantity.toStringAsFixed(2)} Kg',
          boldFont,
          regularFont,
        ),
        _buildDetailRow(
          'Price per Kg',
          currencyFormat.format(price),
          boldFont,
          regularFont,
        ),
        _buildDetailRow(
          'Total Value',
          currencyFormat.format(totalValue),
          boldFont,
          regularFont,
        ),
        _buildDetailRow('Delivery Date', deliveryDate, boldFont, regularFont),
        if (deliveryLocation != null)
          _buildDetailRow(
            'Delivery Location',
            deliveryLocation,
            boldFont,
            regularFont,
          ),
        if (paymentTerms != null)
          _buildDetailRow('Payment Terms', paymentTerms, boldFont, regularFont),
      ],
    );
  }

  // Terms and conditions for the purchase
  static pw.Widget _buildPurchaseTermsAndConditions(
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTermClause(
          '1. Quality Standards:',
          'The crop must meet the quality standards as agreed upon by both parties. The buyer reserves the right to reject the delivery if standards are not met.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          '2. Delivery & Acceptance:',
          'Delivery will be made on the specified date. The buyer will have 24 hours to inspect and accept the goods. Failure to reject within this period implies acceptance.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          '3. Payment:',
          'Payment will be processed according to the agreed payment terms upon acceptance of the goods. All payments will be made through the AgriChain platform.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          '4. Governing Law:',
          'This agreement shall be governed by the laws of the relevant jurisdiction and the terms of service of the AgriChain platform.',
          regularFont,
          boldFont,
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'This agreement is electronically generated and signed, representing a binding contract between the parties.',
          style: pw.TextStyle(
            font: italicFont,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  // Indian Legal Compliance Section
  static pw.Widget _buildIndianLegalComplianceSection(
      pw.Font regularFont, pw.Font boldFont, pw.Font italicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTermClause(
          'A. Contract Act & Sale of Goods:',
          'This agreement constitutes a valid electronic contract under the Indian Contract Act, 1872, and the Sale of Goods Act, 1930, determining price, delivery, and ownership transfer.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          'B. Digital Signatures (IT Act 2000):',
          'Electronic signatures affixed hereto are legally recognized under Sections 4 & 5 of the Information Technology Act, 2000, and the IT (Electronic Service Delivery) Rules.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          'C. DPDP Act 2023 Consent:',
          'The parties explicitly consent to the processing of their digital identities and personal data strictly for the execution of this platform trade, per the Digital Personal Data Protection Act, 2023.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          'D. Agricultural & Consumer Laws:',
          'This trade complies with the Farmers\' Produce Trade and Commerce (Promotion and Facilitation) Act, 2020. Disputes are subject to platform arbitration and the Consumer Protection Act, 2019.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          'E. Payments & Settlements:',
          'Consideration settlement occurs via RBI-regulated channels as mandated by the Payment and Settlement Systems Act, 2007.',
          regularFont,
          boldFont,
        ),
      ],
    );
  }

  // Signature section for the purchase agreement
  static pw.Widget _buildPurchaseSignatureSection(
    String farmerName,
    String buyerName,
    Uint8List? farmerSignature,
    Uint8List? buyerSignature,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        color: PdfColors.grey100,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSignatureBlock(
            'Farmer',
            farmerName,
            farmerSignature,
            regularFont,
            boldFont,
            timeFormat,
          ),
          _buildSignatureBlock(
            'Buyer',
            buyerName,
            buyerSignature,
            regularFont,
            boldFont,
            timeFormat,
          ),
        ],
      ),
    );
  }

  /// Generate a simple agricultural loan agreement PDF
  static Future<Uint8List> generateLoanAgreement({
    required String agreementId,
    required String borrowerName,
    required String lenderName,
    required double loanAmount,
    required String interestRate,
    required String repaymentPeriod,
    String? purpose,
    String? collateralNFT,
    String? borrowerSignatureUrl,
    String? lenderSignatureUrl,
    Map<String, dynamic>? extra,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('dd MMMM yyyy \'at\' HH:mm');

    // Fetch signatures
    final borrowerSignature = await _fetchImage(borrowerSignatureUrl);
    final lenderSignature = await _fetchImage(lenderSignatureUrl);

    // Professional fonts
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final italicFont = await PdfGoogleFonts.openSansItalic();

    final now = DateTime.now();

    // Note: Logo removed to avoid asset loading errors
    // Company branding is now text-based

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 40),
        header: (context) => _buildLoanAgreementHeader(regularFont, boldFont),
        footer: (context) => _buildLoanAgreementFooter(
          agreementId,
          regularFont,
          boldFont,
          context,
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'AGRICULTURAL LOAN AGREEMENT',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: 250,
                    height: 2,
                    color: PdfColors.green700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Parties Section
            _buildSectionTitle('1. PARTIES', boldFont),
            _buildPartiesSection(
              borrowerName,
              lenderName,
              regularFont,
              boldFont,
            ),
            pw.SizedBox(height: 25),

            // Loan Details Section
            _buildSectionTitle('2. LOAN DETAILS', boldFont),
            _buildLoanDetailsSection(
              agreementId,
              dateFormat.format(now),
              loanAmount,
              interestRate,
              repaymentPeriod,
              purpose,
              collateralNFT,
              regularFont,
              boldFont,
            ),
            pw.SizedBox(height: 25),

            // Terms and Conditions
            _buildSectionTitle('3. TERMS AND CONDITIONS', boldFont),
            _buildLoanTermsAndConditions(regularFont, boldFont, italicFont),
            pw.SizedBox(height: 30),

            // Legal Framework & Compliance (Indian Laws)
            _buildSectionTitle('4. LEGAL FRAMEWORK & COMPLIANCE', boldFont),
            _buildIndianLegalComplianceSection(regularFont, boldFont, italicFont),
            pw.SizedBox(height: 30),

            // Signatures
            _buildSectionTitle('5. SIGNATURES', boldFont),
            _buildLoanSignatureSection(
              borrowerName,
              lenderName,
              borrowerSignature,
              lenderSignature,
              regularFont,
              boldFont,
              timeFormat,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Helper to build section titles
  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: PdfColors.green700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 1, color: PdfColors.grey600),
        pw.SizedBox(height: 15),
      ],
    );
  }

  // Header for the loan agreement
  static pw.Widget _buildLoanAgreementHeader(
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.green700, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              // Logo removed - using text icon instead
              pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'AC',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 24,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 15),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _companyName,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _companyAddress,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'CONFIDENTIAL',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.red800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Date: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Footer for the loan agreement
  static pw.Widget _buildLoanAgreementFooter(
    String agreementId,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Context context,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Agreement ID: $agreementId',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // Parties section for the loan agreement
  static pw.Widget _buildPartiesSection(
    String borrowerName,
    String lenderName,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'This Loan Agreement is between:',
          style: pw.TextStyle(font: regularFont, fontSize: 11),
        ),
        pw.SizedBox(height: 15),
        _buildPartyDetail('The Borrower:', borrowerName, regularFont, boldFont),
        pw.SizedBox(height: 10),
        _buildPartyDetail('The Lender:', lenderName, regularFont, boldFont),
      ],
    );
  }

  // Helper for party details
  static pw.Widget _buildPartyDetail(
    String title,
    String name,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            title,
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            name,
            style: pw.TextStyle(font: regularFont, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // Loan details section
  static pw.Widget _buildLoanDetailsSection(
    String agreementId,
    String agreementDate,
    double loanAmount,
    String interestRate,
    String repaymentPeriod,
    String? purpose,
    String? collateralNFT,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(160),
        1: const pw.FlexColumnWidth(),
      },
      children: [
        _buildDetailRow('Agreement ID', agreementId, boldFont, regularFont),
        _buildDetailRow('Agreement Date', agreementDate, boldFont, regularFont),
        _buildDetailRow(
          'Principal Loan Amount',
          currencyFormat.format(loanAmount),
          boldFont,
          regularFont,
        ),
        _buildDetailRow(
          'Annual Interest Rate',
          interestRate,
          boldFont,
          regularFont,
        ),
        _buildDetailRow(
          'Repayment Period',
          repaymentPeriod,
          boldFont,
          regularFont,
        ),
        if (purpose != null)
          _buildDetailRow('Purpose of Loan', purpose, boldFont, regularFont),
        if (collateralNFT != null)
          _buildDetailRow(
            'Collateral (NFT ID)',
            collateralNFT,
            boldFont,
            regularFont,
          ),
      ],
    );
  }

  // Helper for detail rows in a table
  static pw.TableRow _buildDetailRow(
    String label,
    String value,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: PdfColors.green50,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ),
      ],
    );
  }

  // Terms and conditions for the loan
  static pw.Widget _buildLoanTermsAndConditions(
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTermClause(
          '1. Repayment:',
          'The Borrower agrees to repay the loan in full, including principal and accrued interest, within the specified repayment period. Payments shall be made in monthly installments.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          '2. Default:',
          'Failure to make a payment within 15 days of the due date will constitute a default. In the event of a default, the Lender has the right to seize the collateralized NFT.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          '3. Governing Law:',
          'This agreement shall be governed by and construed in accordance with the laws of the jurisdiction in which the Lender operates.',
          regularFont,
          boldFont,
        ),
        _buildTermClause(
          '4. Entire Agreement:',
          'This document constitutes the entire agreement between the parties and supersedes all prior discussions, agreements, or understandings of any kind.',
          regularFont,
          boldFont,
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'By signing below, the parties acknowledge that they have read, understood, and agree to the terms of this Loan Agreement.',
          style: pw.TextStyle(
            font: italicFont,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  // Helper for term clauses
  static pw.Widget _buildTermClause(
    String title,
    String content,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              title,
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              content,
              style: pw.TextStyle(font: regularFont, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // Signature section for the loan agreement
  static pw.Widget _buildLoanSignatureSection(
    String borrowerName,
    String lenderName,
    Uint8List? borrowerSignature,
    Uint8List? lenderSignature,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        color: PdfColors.grey100,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSignatureBlock(
            'Borrower',
            borrowerName,
            borrowerSignature,
            regularFont,
            boldFont,
            timeFormat,
          ),
          _buildSignatureBlock(
            'Lender',
            lenderName,
            lenderSignature,
            regularFont,
            boldFont,
            timeFormat,
          ),
        ],
      ),
    );
  }

  // Helper for signature blocks
  static pw.Widget _buildSignatureBlock(
    String role,
    String name,
    Uint8List? signatureImage,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 180,
          height: 60, // Increased height for signature
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
          child: signatureImage != null
              ? pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(signatureImage),
                    width: 150,
                    height: 50,
                    fit: pw.BoxFit.contain,
                  ),
                )
              : pw.Center(
                  child: pw.Text(
                    'Electronically Signed',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(name, style: pw.TextStyle(font: boldFont, fontSize: 12)),
        pw.SizedBox(height: 4),
        pw.Text(role, style: pw.TextStyle(font: regularFont, fontSize: 10)),
        pw.SizedBox(height: 8),
        pw.Text(
          'Date: ${timeFormat.format(DateTime.now())}',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  /// Build a professional-looking header for the PDF
  static pw.Widget _buildProfessionalHeader(
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _companyName,
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _companyAddress,
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Email: $_companyEmail',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
              pw.Text(
                'Phone: $_companyPhone',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProfessionalContractInfo(
    FirestoreOrder order,
    Map<String, dynamic> contractData,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONTRACT REFERENCE',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow('Contract Number:', order.id, regularFont, boldFont),
            _buildTableRow(
              'Contract Date:',
              timeFormat.format(order.orderDate),
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Status:',
              order.status.name.toUpperCase(),
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Blockchain ID:',
              contractData['contractId'] ?? 'Pending',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Transaction Hash:',
              _truncateHash(contractData['transactionHash'] ?? 'Pending'),
              regularFont,
              boldFont,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalPartiesSection(
    FirestoreUser buyer,
    FirestoreUser seller,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONTRACTING PARTIES',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 15),

        // Buyer Section
        pw.Text(
          '1. THE BUYER',
          style: pw.TextStyle(font: boldFont, fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Name: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: buyer.name,
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Email: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: buyer.email,
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Phone: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: buyer.phone ?? 'Not provided',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Location: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: buyer.location ?? 'Not specified',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Wallet Address: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: _truncateAddress(
                        buyer.walletAddress ?? 'Not connected',
                      ),
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 15),

        // Seller Section
        pw.Text(
          '2. THE SELLER',
          style: pw.TextStyle(font: boldFont, fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Name: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: seller.name,
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Email: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: seller.email,
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Phone: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: seller.phone ?? 'Not provided',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Location: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: seller.location ?? 'Not specified',
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Wallet Address: ',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                    pw.TextSpan(
                      text: _truncateAddress(
                        seller.walletAddress ?? 'Not connected',
                      ),
                      style: pw.TextStyle(font: regularFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalProductSection(
    FirestoreCrop crop,
    FirestoreOrder order,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PRODUCT SPECIFICATIONS',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow('Product Name:', crop.name, regularFont, boldFont),
            _buildTableRow(
              'Category:',
              crop.category?.name.toUpperCase() ?? 'Not specified',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Quality Grade:',
              crop.qualityGrade.name.toUpperCase(),
              regularFont,
              boldFont,
            ),
            _buildTableRow('Quantity:', order.quantity, regularFont, boldFont),
            _buildTableRow(
              'Unit Price:',
              '₹${crop.price.toStringAsFixed(2)}',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Total Amount:',
              '₹${order.totalAmount.toStringAsFixed(2)}',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Harvest Date:',
              dateFormat.format(crop.harvestDate),
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Origin Location:',
              crop.location,
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'NFT Token ID:',
              crop.nftTokenId ?? 'Not minted',
              regularFont,
              boldFont,
            ),
          ],
        ),
        if (crop.certifications.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'CERTIFICATIONS:',
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            crop.certifications
                .map((cert) => '• ${cert['type'] ?? 'Unknown certification'}')
                .join('\n'),
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildProfessionalFinancialSection(
    FirestoreOrder order,
    Map<String, dynamic>? paymentDetails,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FINANCIAL TERMS',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow(
              'Total Amount:',
              '₹${order.totalAmount.toStringAsFixed(2)}',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Currency:',
              'Indian Rupees (INR)',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Payment Method:',
              paymentDetails?['payment_method'] ?? 'Digital Payment',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Transaction ID:',
              paymentDetails?['transaction_id'] ?? 'Pending',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Escrow Status:',
              'FUNDS SECURED',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Release Condition:',
              'Upon successful delivery confirmation',
              regularFont,
              boldFont,
            ),
            if (paymentDetails?['upi_id'] != null)
              _buildTableRow(
                'UPI ID:',
                paymentDetails!['upi_id'],
                regularFont,
                boldFont,
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalSmartContractSection(
    Map<String, dynamic> contractData,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BLOCKCHAIN INTEGRATION',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FlexColumnWidth(),
          },
          children: [
            _buildTableRow(
              'Contract Address:',
              contractData['contractAddress'] ?? 'Deploying...',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Escrow Address:',
              contractData['escrowAddress'] ?? 'Initializing...',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Block Number:',
              contractData['blockNumber']?.toString() ?? 'Pending',
              regularFont,
              boldFont,
            ),
            _buildTableRow(
              'Gas Fee:',
              contractData['gasUsed'] ?? 'Calculating...',
              regularFont,
              boldFont,
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'SMART CONTRACT FEATURES:',
          style: pw.TextStyle(font: boldFont, fontSize: 10),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '• Automated escrow with secure fund management\n'
          '• Quality verification and dispute resolution mechanism\n'
          '• Automatic NFT ownership transfer upon completion\n'
          '• Penalty enforcement for contract violations\n'
          '• Immutable transaction record on blockchain\n'
          '• Multi-signature approval for fund release',
          style: pw.TextStyle(font: regularFont, fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalTermsSection(
    Map<String, dynamic> contractData,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
    DateFormat dateFormat,
  ) {
    final terms =
        contractData['contractData']?['terms'] as Map<String, dynamic>?;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TERMS AND CONDITIONS',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 15),

        // Specific Terms
        if (terms != null) ...[
          pw.Text(
            'SPECIFIC CONTRACT TERMS:',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(120),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              _buildTableRow(
                'Delivery Deadline:',
                terms['deliveryDeadline'] != null
                    ? dateFormat.format(
                        DateTime.parse(terms['deliveryDeadline']),
                      )
                    : 'As per mutual agreement',
                regularFont,
                boldFont,
              ),
              _buildTableRow(
                'Quality Standards:',
                terms['qualityStandards'] ?? 'As per product specifications',
                regularFont,
                boldFont,
              ),
              _buildTableRow(
                'Late Delivery Penalty:',
                '${((terms['penaltyRate'] ?? 0.05) * 100).toStringAsFixed(1)}% per day',
                regularFont,
                boldFont,
              ),
              _buildTableRow(
                'Refund Policy:',
                terms['refundPolicy'] ??
                    'Full refund if quality standards not met',
                regularFont,
                boldFont,
              ),
            ],
          ),
          pw.SizedBox(height: 15),
        ],

        // General Terms
        pw.Text(
          'GENERAL TERMS AND CONDITIONS:',
          style: pw.TextStyle(font: boldFont, fontSize: 11),
        ),
        pw.SizedBox(height: 8),

        ..._buildNumberedTerms(regularFont, boldFont),

        pw.SizedBox(height: 15),
        pw.Text(
          'By executing this contract, both parties acknowledge that they have read, understood, and agree to be bound by all terms and conditions stated herein.',
          style: pw.TextStyle(font: italicFont, fontSize: 10),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildNumberedTerms(
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final terms = [
      'This contract is governed by the smart contract deployed on the blockchain network and is legally binding under applicable laws.',
      'All disputes shall be resolved through the platform\'s automated dispute resolution mechanism before escalating to legal proceedings.',
      'The buyer must confirm delivery within seven (7) days of receiving the goods, failing which delivery shall be deemed accepted.',
      'Quality standards must be met as per the product specifications outlined in this contract.',
      'Late delivery may result in penalties as specified in the contract terms, automatically enforced by the smart contract.',
      'Both parties warrant that they have the legal capacity and authority to enter into this contract.',
      'This contract may only be modified through mutual written consent and blockchain transaction confirmation.',
      'Force majeure events shall be handled as per platform policies and may result in contract suspension or termination.',
      'All personal data shall be handled in accordance with applicable privacy laws and platform policies.',
      'This contract shall remain in effect until all obligations are fulfilled or the contract is terminated as per these terms.',
    ];

    return terms.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final term = entry.value;

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 25,
              child: pw.Text(
                '$index.',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                term,
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  static pw.Widget _buildProfessionalSignatureSection(
    FirestoreUser buyer,
    FirestoreUser seller,
    pw.Font regularFont,
    pw.Font boldFont,
    DateFormat timeFormat,
  ) {
    final currentDate = timeFormat.format(DateTime.now());

    return pw.Column(
      children: [
        pw.Text(
          'SIGNATURES',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Buyer Signature
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'THE BUYER:',
                    style: pw.TextStyle(font: boldFont, fontSize: 11),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 200, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    buyer.name,
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                  pw.Text(
                    'Digital Signature',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                  pw.Text(
                    'Date: $currentDate',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                ],
              ),
            ),

            pw.SizedBox(width: 40),

            // Seller Signature
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'THE SELLER:',
                    style: pw.TextStyle(font: boldFont, fontSize: 11),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 200, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    seller.name,
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                  pw.Text(
                    'Digital Signature',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                  pw.Text(
                    'Date: $currentDate',
                    style: pw.TextStyle(font: regularFont, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 30),

        // Witness/Platform Signature
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'WITNESSED BY:',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
              pw.SizedBox(height: 20),
              pw.Container(width: 200, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 5),
              pw.Text(
                _companyName,
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              pw.Text(
                'Platform Authority',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
              pw.Text(
                'Date: $currentDate',
                style: pw.TextStyle(font: regularFont, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildTableRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionalFooter(
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final currentDateTime = DateFormat(
      'dd MMMM yyyy, HH:mm:ss',
    ).format(DateTime.now());

    return pw.Column(
      children: [
        pw.Container(width: double.infinity, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DIGITAL VERIFICATION',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '✓ Blockchain Secured',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  '✓ Cryptographically Signed',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  '✓ Immutable Record',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'DOCUMENT INFORMATION',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Generated: $currentDateTime',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  'Platform: $_companyName',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
                pw.Text(
                  'Version: 2.0',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'This contract is legally binding and enforceable under applicable laws.\n'
            'For verification and dispute resolution, please contact platform support.',
            style: pw.TextStyle(font: regularFont, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static String _truncateHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  static String _truncateAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  /// Save PDF to device storage and return the file path
  static Future<String> savePdfToDevice(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    debugPrint('savePdfToDevice: Not implemented for web/this platform');
    return '';
  }

  /// Share or print the PDF
  static Future<void> shareOrPrintPdf(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  /// Generate a unique filename for the contract
  static String generateContractFileName(String orderId) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'AgriChain_Contract_${orderId}_$timestamp.pdf';
  }
}

class SellerApplicationModel {
  final String? id;
  final String companyName;
  final String companyTitle;
  final String taxNumber;
  final String taxOffice;
  final String address;
  final String contactInfo;
  final String iban;
  final bool kvkkAccepted;
  final bool contractAccepted;
  final String status;
  final String? rejectionReason;

  SellerApplicationModel({
    this.id,
    required this.companyName,
    required this.companyTitle,
    required this.taxNumber,
    required this.taxOffice,
    required this.address,
    required this.contactInfo,
    required this.iban,
    required this.kvkkAccepted,
    required this.contractAccepted,
    this.status = "pending",
    this.rejectionReason,
  });

  factory SellerApplicationModel.fromJson(Map<String, dynamic> json) {
    return SellerApplicationModel(
      id: json['_id'] as String?,
      companyName: json['companyName'] ?? '',
      companyTitle: json['companyTitle'] ?? '',
      taxNumber: json['taxNumber'] ?? '',
      taxOffice: json['taxOffice'] ?? '',
      address: json['address'] ?? '',
      contactInfo: json['contactInfo'] ?? '',
      iban: json['iban'] ?? '',
      kvkkAccepted: json['kvkkAccepted'] ?? false,
      contractAccepted: json['contractAccepted'] ?? false,
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        "companyName": companyName,
        "companyTitle": companyTitle,
        "taxNumber": taxNumber,
        "taxOffice": taxOffice,
        "address": address,
        "contactInfo": contactInfo,
        "iban": iban,
        "kvkkAccepted": kvkkAccepted,
        "contractAccepted": contractAccepted,
      };
}

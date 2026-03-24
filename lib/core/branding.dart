class Branding {
  static const companyName = 'Güde Teknoloji';
  static const companyTagline = 'Kurumsal yazılım ve ürün deneyimi';
  static const logoAsset = 'assets/branding/gude_logo.png';
  static const website = 'www.gudeteknoloji.com.tr';
  static const companyPhoneDisplay = '0 543 795 60 44';
  static const companyPhoneRaw = '+905437956044';
  static const companyAddress =
      'Yalı Mah. 6436 Sok. No: 37/A, Karşıyaka, İzmir';
  static const companyDistrict = 'Karşıyaka / İzmir';

  static final String googleMapsQuery = Uri.encodeComponent(companyAddress);
  static final String googleMapsUrl =
      'https://www.google.com/maps/search/?api=1&query=$googleMapsQuery';
  static final String googleMapsEmbedUrl =
      'https://www.google.com/maps?q=$googleMapsQuery&z=16&output=embed';
}

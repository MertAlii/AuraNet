/// Port risk veritabanı — port numarası → risk bilgisi eşlemesi
class PortRiskInfo {
  final int port;
  final String protocol;
  final String riskLevel; // 'high', 'medium', 'low', 'safe'
  final String description;
  final String recommendation;

  const PortRiskInfo({
    required this.port,
    required this.protocol,
    required this.riskLevel,
    required this.description,
    required this.recommendation,
  });
}

class PortRiskDatabase {
  PortRiskDatabase._();

  static const Map<int, PortRiskInfo> ports = {
    21: PortRiskInfo(
      port: 21,
      protocol: 'FTP',
      riskLevel: 'high',
      description: 'Şifresiz dosya transferi protokolü',
      recommendation: 'FTP kapatın, SFTP kullanın',
    ),
    22: PortRiskInfo(
      port: 22,
      protocol: 'SSH',
      riskLevel: 'medium',
      description: 'Uzak bağlantı — brute force riski',
      recommendation: 'Güçlü şifre veya anahtar tabanlı kimlik doğrulama kullanın',
    ),
    23: PortRiskInfo(
      port: 23,
      protocol: 'Telnet',
      riskLevel: 'high',
      description: 'Şifresiz uzak bağlantı — tüm veriler açık metin',
      recommendation: 'Telnet kapatın, SSH kullanın',
    ),
    25: PortRiskInfo(
      port: 25,
      protocol: 'SMTP',
      riskLevel: 'medium',
      description: 'E-posta gönderme — spam riski',
      recommendation: 'SMTP portunu internet erişimine kapatın',
    ),
    53: PortRiskInfo(
      port: 53,
      protocol: 'DNS',
      riskLevel: 'low',
      description: 'DNS çözümleme hizmeti',
      recommendation: 'Router DNS ayarlarını kontrol edin',
    ),
    80: PortRiskInfo(
      port: 80,
      protocol: 'HTTP',
      riskLevel: 'medium',
      description: 'Şifrelenmemiş web trafiği',
      recommendation: 'HTTPS kullanımına geçin',
    ),
    443: PortRiskInfo(
      port: 443,
      protocol: 'HTTPS',
      riskLevel: 'safe',
      description: 'Şifreli web trafiği — güvenli',
      recommendation: 'Güvenli bağlantı, sorun yok',
    ),
    554: PortRiskInfo(
      port: 554,
      protocol: 'RTSP',
      riskLevel: 'medium',
      description: 'Video stream — kamera olabilir',
      recommendation: 'Bu cihazı tanıyorsanız güvenilir olarak işaretleyin',
    ),
    3306: PortRiskInfo(
      port: 3306,
      protocol: 'MySQL',
      riskLevel: 'high',
      description: 'Veritabanı erişimi açık',
      recommendation: 'Veritabanı portunu dışarıya kapatın',
    ),
    3389: PortRiskInfo(
      port: 3389,
      protocol: 'RDP',
      riskLevel: 'high',
      description: 'Uzak masaüstü — çok yüksek risk',
      recommendation: 'RDP portunu kapatın veya VPN arkasına alın',
    ),
    5432: PortRiskInfo(
      port: 5432,
      protocol: 'PostgreSQL',
      riskLevel: 'high',
      description: 'Veritabanı erişimi açık',
      recommendation: 'Veritabanı portunu dışarıya kapatın',
    ),
    5900: PortRiskInfo(
      port: 5900,
      protocol: 'VNC',
      riskLevel: 'high',
      description: 'Uzak masaüstü kontrolü',
      recommendation: 'VNC portunu kapatın',
    ),
    6379: PortRiskInfo(
      port: 6379,
      protocol: 'Redis',
      riskLevel: 'high',
      description: 'Veritabanı erişimi açık — genellikle şifresiz',
      recommendation: 'Redis portunu dışarıya kapatın ve şifre ayarlayın',
    ),
    8080: PortRiskInfo(
      port: 8080,
      protocol: 'HTTP Alt.',
      riskLevel: 'medium',
      description: 'Alternatif HTTP — yönetim paneli olabilir',
      recommendation: 'Gereksiz ise kapatın',
    ),
    8443: PortRiskInfo(
      port: 8443,
      protocol: 'HTTPS Alt.',
      riskLevel: 'low',
      description: 'Alternatif HTTPS bağlantı',
      recommendation: 'Güvenli bağlantı, sorun düşük',
    ),
    8888: PortRiskInfo(
      port: 8888,
      protocol: 'HTTP Proxy',
      riskLevel: 'medium',
      description: 'HTTP proxy hizmeti',
      recommendation: 'Gereksiz ise kapatın',
    ),
    9090: PortRiskInfo(
      port: 9090,
      protocol: 'Web Mgmt.',
      riskLevel: 'medium',
      description: 'Web yönetim arayüzü',
      recommendation: 'Gereksiz ise kapatın',
    ),
    1433: PortRiskInfo(
      port: 1433,
      protocol: 'MSSQL',
      riskLevel: 'high',
      description: 'Microsoft SQL Server erişimi açık',
      recommendation: 'Veritabanı portunu dışarıya kapatın',
    ),
    1521: PortRiskInfo(
      port: 1521,
      protocol: 'Oracle DB',
      riskLevel: 'high',
      description: 'Oracle veritabanı erişimi açık',
      recommendation: 'Veritabanı portunu dışarıya kapatın',
    ),
    27017: PortRiskInfo(
      port: 27017,
      protocol: 'MongoDB',
      riskLevel: 'high',
      description: 'MongoDB erişimi açık — genellikle şifresiz',
      recommendation: 'MongoDB portunu kapatın ve kimlik doğrulama ekleyin',
    ),
  };

  /// Yaygın taranacak portlar (Free kullanıcı)
  static const List<int> commonPorts = [
    21, 22, 23, 25, 53, 80, 443, 554, 3389,
    8080, 8443, 8888, 9090, 3306, 5432, 27017,
    1433, 1521, 5900, 6379,
  ];

  /// Bilinmeyen port için varsayılan bilgi
  static PortRiskInfo getPortInfo(int port) {
    return ports[port] ??
        PortRiskInfo(
          port: port,
          protocol: 'Bilinmeyen',
          riskLevel: 'low',
          description: 'Bu port hakkında bilgi bulunmuyor',
          recommendation: 'Gereksiz ise kapatmanız önerilir',
        );
  }
}

import 'usuario_model.dart';

class SesionModel {
  final String tipoToken;
  final String tokenAcceso;
  final String tokenRenovacion;
  final DateTime tokenAccesoExpiraEn;
  final DateTime tokenRenovacionExpiraEn;
  final UsuarioModel usuario;

  const SesionModel({
    required this.tipoToken,
    required this.tokenAcceso,
    required this.tokenRenovacion,
    required this.tokenAccesoExpiraEn,
    required this.tokenRenovacionExpiraEn,
    required this.usuario,
  });

  bool get tokenAccesoVencido => DateTime.now().isAfter(tokenAccesoExpiraEn);

  bool get proximoAVencer => DateTime.now()
      .add(const Duration(seconds: 30))
      .isAfter(tokenAccesoExpiraEn);

  bool get tokenRenovacionVencido =>
      DateTime.now().isAfter(tokenRenovacionExpiraEn);

  factory SesionModel.fromJson(Map<String, dynamic> json) {
    return SesionModel(
      tipoToken: json['tipo_token'] as String? ?? 'Bearer',
      tokenAcceso: json['token_acceso'] as String? ?? '',
      tokenRenovacion: json['token_renovacion'] as String? ?? '',
      tokenAccesoExpiraEn:
          DateTime.parse(json['token_acceso_expira_en'] as String),
      tokenRenovacionExpiraEn:
          DateTime.parse(json['token_renovacion_expira_en'] as String),
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_token': tipoToken,
      'token_acceso': tokenAcceso,
      'token_renovacion': tokenRenovacion,
      'token_acceso_expira_en': tokenAccesoExpiraEn.toIso8601String(),
      'token_renovacion_expira_en': tokenRenovacionExpiraEn.toIso8601String(),
      'usuario': usuario.toJson(),
    };
  }

  SesionModel copyWith({
    String? tipoToken,
    String? tokenAcceso,
    String? tokenRenovacion,
    DateTime? tokenAccesoExpiraEn,
    DateTime? tokenRenovacionExpiraEn,
    UsuarioModel? usuario,
  }) {
    return SesionModel(
      tipoToken: tipoToken ?? this.tipoToken,
      tokenAcceso: tokenAcceso ?? this.tokenAcceso,
      tokenRenovacion: tokenRenovacion ?? this.tokenRenovacion,
      tokenAccesoExpiraEn: tokenAccesoExpiraEn ?? this.tokenAccesoExpiraEn,
      tokenRenovacionExpiraEn:
          tokenRenovacionExpiraEn ?? this.tokenRenovacionExpiraEn,
      usuario: usuario ?? this.usuario,
    );
  }
}

import 'package:chopper/chopper.dart';

import '../model/response/campaign_response.dart';
import '../model/response/tier_response.dart';
import '../model/response/rule_response.dart';
import '../common/myriad_error.dart';

//typedef JsonDeserialize<T> = T Function(Map<String,dynamic> json);
typedef T JsonDeserialize<T>(Map<String, dynamic> json);

class MyriadConverter extends JsonConverter {
  final Map<String, JsonDeserialize> registry;

  MyriadConverter(this.registry);

  T _decodeMap<T>(Map<String, dynamic> json) {
    /// Get deserializer from registry - we may need a deserializer for a subclass of T
    /// if not found or invalid, throw error
    var objType = json['objType'];
    final deserialize = registry[objType];
    if (deserialize == null || deserialize is! JsonDeserialize<T>) {
      /// throw serializer not found error;
      throw NoJsonSerializerError(T, objType);
    }
    
    return deserialize(json);
  }

  List<T> _decodeList<T>(List values) =>
      values.where((v) => v != null).map<T>((v) => _decode<T>(v)).toList();

  dynamic _decode<T>(entity) {
    if (entity is Iterable) return _decodeList<T>(entity);

    if (entity is Map) return _decodeMap<T>(entity);

    return entity;
  }

  @override
  Response<ResultType> convertResponse<ResultType, Item>(Response response) {
    // use JsonConverter to convert response
    final jsonRes = super.convertResponse(response);
    // deserialize and replace the response body
    return jsonRes.replace<ResultType>(body: _decode<Item>(jsonRes.body));
  }

  @override
  // all objects should implements toJson method
  Request convertRequest(Request request) => super.convertRequest(request);

  Response convertError<ResultType, Item>(Response response) {
    // use [JsonConverter] to decode json
    final jsonRes = super.convertError(response);

    return jsonRes.replace<MyriadError>(
      body: MyriadError.fromJson(jsonRes.body)
    );
  }
}

class NoJsonSerializerError extends Error {
  /// The exception thrown when trying to convert the object.
  final Type unsupportedType;
  final String objType;

  NoJsonSerializerError(this.unsupportedType, [this.objType]);

  String toString() {
    var safeString = objType??Error.safeToString(unsupportedType);
    String prefix = "Type has no suitable deserializer:";
    return "$prefix $safeString";
  }

}

/// register response deserializers
final myriadConverter = MyriadConverter(
  {
    "CampaignResponse": CampaignResponse.deserialize,
    "PaginatedCampaignsResponse": PaginatedCampaignsResponse.deserialize,
    "VoucherCampaignResponse": VoucherCampaignResponse.deserialize,
    "PromotionCampaignResponse": PromotionCampaignResponse.deserialize,
    "TierResponse": TierResponse.deserialize,
    "RuleResponse": RuleResponse.deserialize
  }
);
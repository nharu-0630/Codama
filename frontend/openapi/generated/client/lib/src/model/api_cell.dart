//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'api_cell.g.dart';

/// セル情報のAPIモデル
///
/// Properties:
/// * [geoHash] 
/// * [id] 
/// * [location] 
@BuiltValue()
abstract class APICell implements Built<APICell, APICellBuilder> {
  @BuiltValueField(wireName: r'geo_hash')
  String get geoHash;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'location')
  BuiltList<JsonObject?> get location;

  APICell._();

  factory APICell([void updates(APICellBuilder b)]) = _$APICell;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(APICellBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<APICell> get serializer => _$APICellSerializer();
}

class _$APICellSerializer implements PrimitiveSerializer<APICell> {
  @override
  final Iterable<Type> types = const [APICell, _$APICell];

  @override
  final String wireName = r'APICell';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    APICell object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'geo_hash';
    yield serializers.serialize(
      object.geoHash,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'location';
    yield serializers.serialize(
      object.location,
      specifiedType: const FullType(BuiltList, [FullType.nullable(JsonObject)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    APICell object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required APICellBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'geo_hash':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.geoHash = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'location':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType.nullable(JsonObject)]),
          ) as BuiltList<JsonObject?>;
          result.location.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  APICell deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = APICellBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


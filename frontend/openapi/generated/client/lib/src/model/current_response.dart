//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/api_area.dart';
import 'package:openapi/src/model/api_cell.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'current_response.g.dart';

/// 現在位置エンドポイントのレスポンス
///
/// Properties:
/// * [area] 
/// * [cell] 
@BuiltValue()
abstract class CurrentResponse implements Built<CurrentResponse, CurrentResponseBuilder> {
  @BuiltValueField(wireName: r'area')
  APIArea get area;

  @BuiltValueField(wireName: r'cell')
  APICell get cell;

  CurrentResponse._();

  factory CurrentResponse([void updates(CurrentResponseBuilder b)]) = _$CurrentResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CurrentResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CurrentResponse> get serializer => _$CurrentResponseSerializer();
}

class _$CurrentResponseSerializer implements PrimitiveSerializer<CurrentResponse> {
  @override
  final Iterable<Type> types = const [CurrentResponse, _$CurrentResponse];

  @override
  final String wireName = r'CurrentResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CurrentResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'area';
    yield serializers.serialize(
      object.area,
      specifiedType: const FullType(APIArea),
    );
    yield r'cell';
    yield serializers.serialize(
      object.cell,
      specifiedType: const FullType(APICell),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CurrentResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CurrentResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'area':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(APIArea),
          ) as APIArea;
          result.area.replace(valueDes);
          break;
        case r'cell':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(APICell),
          ) as APICell;
          result.cell.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CurrentResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CurrentResponseBuilder();
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


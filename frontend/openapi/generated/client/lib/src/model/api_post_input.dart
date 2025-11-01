//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/api_area.dart';
import 'package:openapi/src/model/api_cell.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'api_post_input.g.dart';

/// 投稿情報のAPIモデル（ユーザー投稿・LLM返信）
///
/// Properties:
/// * [area] 
/// * [cell] 
/// * [content] 
/// * [createdAt] 
/// * [location] 
/// * [replies] 
/// * [userUuid] 
/// * [uuid] 
@BuiltValue()
abstract class APIPostInput implements Built<APIPostInput, APIPostInputBuilder> {
  @BuiltValueField(wireName: r'area')
  APIArea? get area;

  @BuiltValueField(wireName: r'cell')
  APICell? get cell;

  @BuiltValueField(wireName: r'content')
  String get content;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'location')
  BuiltList<JsonObject?> get location;

  @BuiltValueField(wireName: r'replies')
  BuiltList<APIPostInput>? get replies;

  @BuiltValueField(wireName: r'user_uuid')
  String? get userUuid;

  @BuiltValueField(wireName: r'uuid')
  String get uuid;

  APIPostInput._();

  factory APIPostInput([void updates(APIPostInputBuilder b)]) = _$APIPostInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(APIPostInputBuilder b) => b
      ..replies = ListBuilder();

  @BuiltValueSerializer(custom: true)
  static Serializer<APIPostInput> get serializer => _$APIPostInputSerializer();
}

class _$APIPostInputSerializer implements PrimitiveSerializer<APIPostInput> {
  @override
  final Iterable<Type> types = const [APIPostInput, _$APIPostInput];

  @override
  final String wireName = r'APIPostInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    APIPostInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.area != null) {
      yield r'area';
      yield serializers.serialize(
        object.area,
        specifiedType: const FullType.nullable(APIArea),
      );
    }
    if (object.cell != null) {
      yield r'cell';
      yield serializers.serialize(
        object.cell,
        specifiedType: const FullType.nullable(APICell),
      );
    }
    yield r'content';
    yield serializers.serialize(
      object.content,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'location';
    yield serializers.serialize(
      object.location,
      specifiedType: const FullType(BuiltList, [FullType.nullable(JsonObject)]),
    );
    if (object.replies != null) {
      yield r'replies';
      yield serializers.serialize(
        object.replies,
        specifiedType: const FullType(BuiltList, [FullType(APIPostInput)]),
      );
    }
    if (object.userUuid != null) {
      yield r'user_uuid';
      yield serializers.serialize(
        object.userUuid,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'uuid';
    yield serializers.serialize(
      object.uuid,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    APIPostInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required APIPostInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'area':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(APIArea),
          ) as APIArea?;
          if (valueDes == null) continue;
          result.area.replace(valueDes);
          break;
        case r'cell':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(APICell),
          ) as APICell?;
          if (valueDes == null) continue;
          result.cell.replace(valueDes);
          break;
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.content = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'location':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType.nullable(JsonObject)]),
          ) as BuiltList<JsonObject?>;
          result.location.replace(valueDes);
          break;
        case r'replies':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(APIPostInput)]),
          ) as BuiltList<APIPostInput>;
          result.replies.replace(valueDes);
          break;
        case r'user_uuid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.userUuid = valueDes;
          break;
        case r'uuid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.uuid = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  APIPostInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = APIPostInputBuilder();
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

